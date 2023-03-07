#ifndef GREEN_SIGNUPCONTROLLER_H
#define GREEN_SIGNUPCONTROLLER_H

#include "green.h"

#include <QObject>
#include <QQmlEngine>

#include "controller.h"
#include "task.h"

class SignupController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic WRITE setMnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QString pin READ pin WRITE setPin NOTIFY pinChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    explicit SignupController(QObject* parent = nullptr);

    Network* network() const { return m_network; };
    void setNetwork(Network* network);

    QStringList mnemonic() const { return m_mnemonic; }
    void setMnemonic(const QStringList &mnemonic);

    QString type() const { return m_type; }
    void setType(const QString& type);

    QString pin() const { return m_pin; }
    void setPin(const QString& pin);

    bool active() const { return m_active; }
    void setActive(bool active);

    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);

public slots:
    QStringList generateMnemonic(int size);

signals:
    void networkChanged();
    void walletChanged();
    void pinChanged();
    void activeChanged();
    void typeChanged();
    void mnemonicSizeChanged();
    void mnemonicChanged();
    void signup(Wallet* wallet);

private:
    Network* m_network{nullptr};
    QStringList m_mnemonic;
    QString m_pin;
    QString m_type{"default"};
    bool m_active{false};
    Wallet* m_wallet{nullptr};
};

class SignupCreateWalletTask : public Task
{
    Q_OBJECT
public:
    SignupCreateWalletTask(SignupController* controller);
    void update() override;
private:
    SignupController* const m_controller;
};

class SignupPersistWalletTask : public Task
{
    Q_OBJECT
public:
    SignupPersistWalletTask(SignupController* controller);
    void update() override;
private:
    SignupController* const m_controller;
};

#endif // GREEN_SIGNUPCONTROLLER_H
