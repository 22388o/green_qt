#include "controller.h"
#include "device.h"
#include "handler.h"
#include "json.h"
#include "resolver.h"
#include "session.h"
#include "wallet.h"

#include <gdk.h>

class ChangeSettingsHandler : public Handler
{
    QJsonObject m_data;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        auto data = Json::fromObject(m_data);
        int err = GA_change_settings(session, data.get(), auth_handler);
        Q_ASSERT(err == GA_OK);
    }
public:
    ChangeSettingsHandler(const QJsonObject& data, Wallet* wallet)
        : Handler(wallet)
        , m_data(data)
    {
    }
};


class SendNLocktimesHandler : public Handler
{
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        Q_UNUSED(auth_handler);
        int err = GA_send_nlocktimes(session);
        // Can't Q_ASSERT(err == GA_OK) because err != GA_OK
        // if no utxos found (e.g. new wallet)
        Q_UNUSED(err);
    }
public:
    SendNLocktimesHandler(Wallet* wallet)
        : Handler(wallet)
    {
    }
};

class ChangeSettingsTwoFactorHandler : public Handler
{
    QByteArray m_method;
    QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        auto details = Json::fromObject(m_details);
        int res = GA_change_settings_twofactor(session, m_method.data(), details.get(), auth_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    ChangeSettingsTwoFactorHandler(const QByteArray& method, const QJsonObject& details, Wallet* wallet)
        : Handler(wallet)
        , m_method(method)
        , m_details(details)
    {
    }
};

class TwoFactorChangeLimitsHandler : public Handler
{
    QJsonObject m_details;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        auto details = Json::fromObject(m_details);
        int err = GA_twofactor_change_limits(session, details.get(), auth_handler);
        Q_ASSERT(err == GA_OK);
    }
public:
    TwoFactorChangeLimitsHandler(const QJsonObject& details, Wallet* wallet)
        : Handler(wallet)
        , m_details(details)
    {
    }
};

class TwoFactorResetHandler : public Handler
{
    const QByteArray m_email;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        const uint32_t is_dispute = GA_FALSE;
        int res = GA_twofactor_reset(session, m_email.data(), is_dispute, auth_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    TwoFactorResetHandler(const QByteArray& email, Wallet* wallet)
        : Handler(wallet)
        , m_email(email)
    {
    }
};

class TwoFactorCancelResetHandler : public Handler
{
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        int res = GA_twofactor_cancel_reset(session, auth_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    TwoFactorCancelResetHandler(Wallet* wallet)
        : Handler(wallet)
    {
    }
};

class SetCsvTimeHandler : public Handler
{
    const int m_value;
    void call(GA_session* session, GA_auth_handler** auth_handler) override {
        auto details = Json::fromObject({{ "value", m_value }});
        int res = GA_set_csvtime(session, details.get(), auth_handler);
        Q_ASSERT(res == GA_OK);
    }
public:
    SetCsvTimeHandler(const int value, Wallet* wallet)
        : Handler(wallet)
        , m_value(value)
    {
    }
};

Controller::Controller(QObject* parent)
    : QObject(parent)
{
}

void Controller::exec(Handler* handler)
{
    // TODO get xpubs should be delegated
    connect(handler, &Handler::done, this, [this, handler] { emit done(handler); });
    connect(handler, &Handler::error, this, [this, handler] { emit error(handler); });
    connect(handler, &Handler::requestCode, this, [this, handler] { emit requestCode(handler); });
    connect(handler, &Handler::invalidCode, this, [this, handler] { emit invalidCode(handler); });
    connect(handler, &Handler::resolver, this, &Controller::resolver);
    QMetaObject::invokeMethod(context(), [this, handler] {
        QMetaObject::invokeMethod(this, [handler] {
            handler->exec();
        }, Qt::QueuedConnection);
    }, Qt::QueuedConnection);
}

QObject* Controller::context() const
{
    return m_wallet ? m_wallet->m_session->m_context : nullptr;
}

GA_session* Controller::session() const
{
    return m_wallet ? m_wallet->m_session->m_session : nullptr;
}

Wallet* Controller::wallet() const
{
    return m_wallet;
}

void Controller::setWallet(Wallet *wallet)
{
    if (m_wallet == wallet) return;
    m_wallet = wallet;
    emit walletChanged(m_wallet);
}

void Controller::changeSettings(const QJsonObject& data)
{
    if (!m_wallet) return;

    // Avoid unnecessary calls to GA_change_settings
    bool updated = true;
    auto settings = m_wallet->settings();
    for (auto i = data.begin(); i != data.end(); ++i) {
        if (settings.value(i.key()) != i.value()) {
            updated = false;
            break;
        }
    }
    if (updated) return;

    // Check if wallet is undergoing reset
    if (m_wallet->isLocked()) return;

    auto handler = new ChangeSettingsHandler(data, m_wallet);
    connect(handler, &Handler::done, this, [this, handler] {
        m_wallet->updateSettings();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::sendRecoveryTransactions()
{
    if (!m_wallet) return;
    auto handler = new SendNLocktimesHandler(m_wallet);
    connect(handler, &Handler::done, this, [this, handler] {
        m_wallet->updateSettings();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::enableTwoFactor(const QString& method, const QString& data)
{
    if (!m_wallet) return;
    auto details = QJsonObject{
        { "data", data },
        { "enabled", true }
    };
    auto handler = new ChangeSettingsTwoFactorHandler(method.toLatin1(), details, m_wallet);
    connect(handler, &Handler::done, this, [this, handler] {
        // Two factor configuration has changed, update it.
        m_wallet->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::disableTwoFactor(const QString& method)
{
    if (!m_wallet) return;
    auto details = QJsonObject{
        { "enabled", false }
    };
    auto handler = new ChangeSettingsTwoFactorHandler(method.toLatin1(), details, m_wallet);
    connect(handler, &Handler::done, this, [this, handler] {
        // Two factor configuration has changed, update it.
        m_wallet->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::changeTwoFactorLimit(bool is_fiat, const QString& limit)
{
    if (!m_wallet) return;
    auto unit = m_wallet->settings().value("unit").toString().toLower();
    auto details = QJsonObject{
        { "is_fiat", is_fiat },
        { is_fiat ? "fiat" : unit, limit }
    };
    auto handler = new TwoFactorChangeLimitsHandler(details, m_wallet);
    connect(handler, &Handler::done, this, [this, handler] {
        // Two factor configuration has changed, update it.
        m_wallet->updateConfig();
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::requestTwoFactorReset(const QString& email)
{
    if (!m_wallet) return;
    auto handler = new TwoFactorResetHandler(email.toLatin1(), m_wallet);
    connect(handler, &Handler::done, this, [this, handler] {
        m_wallet->updateConfig();
        // TODO: updateConfig doesn't update 2f reset data,
        // it's only updated after authentication in GDK,
        // so force wallet lock for now.
        m_wallet->setLocked(true);
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::cancelTwoFactorReset()
{
    if (!m_wallet) return;
    auto handler = new TwoFactorCancelResetHandler(m_wallet);
    connect(handler, &Handler::done, this, [this, handler] {
        m_wallet->updateConfig();
        // TODO: updateConfig doesn't update 2f reset data,
        // it's only updated after authentication in GDK,
        // so force wallet unlock for now.
        m_wallet->setLocked(false);
        handler->deleteLater();
        emit finished();
    });
    exec(handler);
}

void Controller::setRecoveryEmail(const QString& email)
{
    if (!m_wallet) return;
    const auto method = QByteArray{"email"};
    const auto details = QJsonObject{
        { "data", email.toLatin1().data() },
        { "confirmed", true },
        { "enabled", false }
    };
    auto handler = new ChangeSettingsTwoFactorHandler(method, details, m_wallet);
    connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();
        m_wallet->updateConfig();
    });
    connect(handler, &Handler::done, this, [this] {
        auto details = QJsonObject{
            { "notifications" , QJsonValue({
                { "email_incoming", true },
                { "email_outgoing", true }})
            }
        };
        auto handler = new ChangeSettingsHandler(details, m_wallet);
        connect(handler, &Handler::done, this, [this, handler] {
            handler->deleteLater();
            emit finished();
        });
        exec(handler);
    });
    exec(handler);
}

void Controller::setCsvTime(int value)
{
    const auto handler = new SetCsvTimeHandler(value, m_wallet);
    connect(handler, &Handler::done, this, [this, handler] {
        handler->deleteLater();
        m_wallet->updateSettings();
        emit finished();
    });
    exec(handler);
}
