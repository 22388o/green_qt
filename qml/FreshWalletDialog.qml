import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractDialog {
    id: self
    background: null
    header: null
    closePolicy: Popup.NoAutoClose
    contentItem: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/fresh_wallet.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.maximumWidth: 250
            color: '#FFF'
            font.pixelSize: 18
            font.weight: 500
            horizontalAlignment: Label.AlignHCenter
            text: 'Congratulations and welcome to your new wallet'
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            color: '#FFF'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: qsTrId('id_create_your_first_account_to')
        }
        PrimaryButton {
            Layout.topMargin: 25
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 200
            text: qsTrId('id_create_account')
            onClicked: self.accept()
        }
    }
}
