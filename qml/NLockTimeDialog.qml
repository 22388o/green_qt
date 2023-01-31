import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    id: dialog
    title: qsTrId('id_set_timelock')
    controller: Controller {
        wallet: dialog.wallet
    }

    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_ok')
                enabled: nlocktime_blocks.acceptableInput
                onTriggered: controller.changeSettings({ nlocktime: Number.parseInt(nlocktime_blocks.text) })
            }
        ]
        Label {
            text: qsTrId('id_redeem_your_deposited_funds')
        }
        Label {
            text: qsTrId('id_value_must_be_between_144_and')
        }
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            GTextField {
                id: nlocktime_days
                text: Math.round(wallet.settings.nlocktime / 144 || 0)
                validator: IntValidator { bottom: 1; top: 200000 / 144; }
                onTextChanged: {
                    if (activeFocus) nlocktime_blocks.text = Math.round(text * 144);
                }
                horizontalAlignment: Qt.AlignRight
                Layout.alignment: Qt.AlignBaseline
            }
            Label {
                text: qsTrId('id_days') + ' ≈ '
                Layout.alignment: Qt.AlignBaseline
            }
            GTextField {
                id: nlocktime_blocks
                text: wallet.settings.nlocktime || 0
                validator: IntValidator { bottom: 144; top: 200000; }
                onTextChanged: {
                    if (activeFocus) nlocktime_days.text = Math.round(text / 144);
                }
                horizontalAlignment: Qt.AlignRight
                Layout.alignment: Qt.AlignBaseline
            }
            Label {
                text: qsTrId('id_blocks')
                Layout.alignment: Qt.AlignBaseline
            }
        }
    }
}
