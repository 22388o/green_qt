import Blockstream.Green
import QtQuick
import QtQuick.Controls

Label {
    property Account account
    font.pixelSize: 10
    font.capitalization: Font.AllUppercase
    leftPadding: 8
    rightPadding: 8
    topPadding: 4
    bottomPadding: 4
    color: 'white'
    background: Rectangle {
        color: constants.c400
        radius: height / 2
    }
    visible: text !== ''
    text: {
        if (account) {
            switch (account.type) {
                case '2of2': return qsTrId('id_standard_account')
                case '2of3': return qsTrId('id_2of3_account')
                case '2of2_no_recovery': return qsTrId('id_amp_account')
                case 'p2sh-p2wpkh': return 'LEGACY SEGWIT (BIP49)'
                case 'p2wpkh': return 'SEGWIT (BIP84)'
            }
        }
        return ''
    }
}
