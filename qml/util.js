function link(url, text) {
    return `<style>a:link { color: "#00B45A"; text-decoration: none; }</style><a href="${url}">${text || url}</a>`
}

function iconFor(target) {
    if (target instanceof Wallet) return iconFor(target.network)
    if (target instanceof Network) return iconFor(target.key)
    switch (target) {
        case 'liquid':
            return 'qrc:/svg/liquid.svg'
        case 'testnet-liquid':
            return 'qrc:/svg/testnet-liquid.svg'
        case 'bitcoin':
            return 'qrc:/svg/btc.svg'
        case 'testnet':
            return 'qrc:/svg/btc_testnet.svg'
        case 'localtest':
            return 'qrc:/svg/localtest.svg'
        case 'localtest-liquid':
            return 'qrc:/svg/localtest-liquid.svg'
    }
    return ''
}

function formatTransactionTimestamp(tx) {
    return new Date(tx.created_at_ts / 1000).toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
}

function accountName(account) {
    if (!account) return ''
    if (account.name !== '') return account.name
    if (account.mainAccount) return qsTrId('id_main_account')
    return qsTrId('Account %1').arg(account.pointer)
}

function dynamicScenePosition(item, x, y) {
    const target = item
    while (item) {
        item.x
        item.y
        item = item.parent
    }
    return target.mapToItem(null, x, y)
}

function findChildIndex(parent, pred) {
    if (!parent) return 0
    let index = 0
    for (let i = 0; i < parent.children.length; ++i) {
        const child = parent.children[i]
        if (!(child instanceof Item)) continue
        if (pred(child)) index = i
    }
    return index
}
