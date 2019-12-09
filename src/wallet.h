#ifndef GREEN_WALLET_H
#define GREEN_WALLET_H

#include <QList>
#include <QObject>
#include <QQmlListProperty>
#include <QThread>
#include <QJsonObject>

class Account;
class Network;

struct GA_session;
struct GA_auth_handler;
struct GA_json;

class Wallet : public QObject
{
    Q_OBJECT

public:
    enum ConnectionStatus {
        Disconnected,
        Connecting,
        Connected
    };
    Q_ENUM(ConnectionStatus)

    enum AuthenticationStatus {
        Unauthenticated,
        Authenticating,
        Authenticated
    };
    Q_ENUM(AuthenticationStatus)

private:
    Q_PROPERTY(Network* network READ network CONSTANT)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(ConnectionStatus connection READ connection NOTIFY connectionChanged)
    Q_PROPERTY(AuthenticationStatus authentication READ authentication NOTIFY authenticationChanged)
    Q_PROPERTY(QJsonObject settings READ settings NOTIFY settingsChanged)
    Q_PROPERTY(QJsonObject currencies READ currencies CONSTANT)
    Q_PROPERTY(QQmlListProperty<Account> accounts READ accounts NOTIFY accountsChanged)
    Q_PROPERTY(QJsonObject events READ events NOTIFY eventsChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic CONSTANT)
    Q_PROPERTY(int loginAttemptsRemaining READ loginAttemptsRemaining NOTIFY loginAttemptsRemainingChanged)
    Q_PROPERTY(QString balance READ balance NOTIFY balanceChanged)
    Q_PROPERTY(QJsonObject config READ config NOTIFY configChanged)

public:
    explicit Wallet(QObject *parent = nullptr);
    virtual ~Wallet();

    Network* network() const { return m_network; }

    ConnectionStatus connection() const { return m_connection; }
    AuthenticationStatus authentication() const { return m_authentication; }

    QJsonObject settings() const;
    QJsonObject currencies() const;

    QQmlListProperty<Account> accounts();

    void handleNotification(const QJsonObject& notification);

    QJsonObject events() const;

    QStringList mnemonic() const;

    int loginAttemptsRemaining() const { return m_login_attempts_remaining; }

    QString balance() const;
    QJsonObject config() const { return m_config; }

public slots:
    void connect();
    void disconnect();
    void test();
    void login(const QByteArray& pin);
    void signup(const QStringList &mnemonic, const QString& password, const QByteArray& pin);
    void recover(const QString& name, const QStringList& mnemonic, const QByteArray& pin);
    void reload();
    void setup2F();

    void updateConfig();

signals:
    void connectionChanged();
    void authenticationChanged();

    void accountsChanged();

    void eventsChanged(QJsonObject events);

    void nameChanged(QString name);

    void loginAttemptsRemainingChanged(int loginAttemptsRemaining);

    void balanceChanged();

    void settingsChanged();

    void configChanged();
private:
    void setConnection(ConnectionStatus connection);
    void setAuthentication(AuthenticationStatus authentication);
    void setBalance(const quint64);
    void connectNow();

public:
    int m_index{0};
    QThread* m_thread{nullptr};
    QObject* m_context{nullptr};
    GA_session* m_session{nullptr};
    ConnectionStatus m_connection{Disconnected};
    AuthenticationStatus m_authentication{Unauthenticated};
    QJsonObject m_settings;
    QJsonObject m_currencies;
    QList<Account*> m_accounts;
    QMap<int, Account*> m_accounts_by_pointer;
    QJsonObject m_events;
    QStringList m_mnemonic;

    QByteArray getPinData() const;
    QByteArray m_pin_data;
    QString m_name;
    QString name() const
    {
        return m_name;
    }
    Network* m_network{nullptr};
    int m_login_attempts_remaining{3};
    QString m_proxy;
    bool m_use_tor{false};
    quint64 m_balance;
    QJsonObject m_config;
};

class AmountConverter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged)
    Q_PROPERTY(QJsonObject input READ input WRITE setInput NOTIFY inputChanged)
    Q_PROPERTY(QJsonObject output READ output NOTIFY outputChanged)

public:
    explicit AmountConverter(QObject* parent = nullptr);

    Wallet* wallet() const;
    QJsonObject input() const;
    QJsonObject output() const;

    void setWallet(Wallet* wallet);
    void setInput(const QJsonObject& input);

    bool valid() const;

signals:
    void walletChanged(Wallet* wallet);
    void inputChanged(QJsonObject input);
    void outputChanged(QJsonObject output);

    void validChanged(bool valid);

private:
    Wallet* m_wallet{nullptr};
    QJsonObject m_input;
    QJsonObject m_output;
    bool m_valid{false};

    void update();
};

#endif // GREEN_WALLET_H
