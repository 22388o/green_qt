#ifndef GREEN_WALLETMANAGER_H
#define GREEN_WALLETMANAGER_H

#include <QJsonObject>
#include <QObject>
#include <QQmlListProperty>
#include <QVector>

class Network;
class Wallet;

class WalletManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<Wallet> wallets READ wallets NOTIFY changed)
public:
    explicit WalletManager();
    virtual ~WalletManager();
    static WalletManager* instance();

    Q_INVOKABLE Wallet* createWallet(Network* network, const QString& hash_id);
    Wallet* restoreWallet(Network* network, const QString& hash_id);
    Q_INVOKABLE Wallet* wallet(const QString& id) const;
    Wallet* walletWithHashId(const QString& hash_id, bool watch_only) const;

    void addWallet(Wallet *wallet);

    Q_INVOKABLE void insertWallet(Wallet* wallet);
    Q_INVOKABLE void removeWallet(Wallet* wallet);

    int size() const { return m_wallets.size(); }

    QQmlListProperty<Wallet> wallets();

    QString newWalletName(Network* network) const;
    QString uniqueWalletName(const QString& base) const;

signals:
    void changed();
    void walletAdded(Wallet* wallet);
    void aboutToRemove(Wallet* wallet);

public slots:
    QStringList generateMnemonic(int size);
public:
    QVector<Wallet*> m_wallets;
};

#endif // GREEN_WALLETMANAGER_H
