import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

import "util.js" as UtilJS

ItemDelegate {
    required property Output output

    function toggleSelection() {
        if (!output.account.network.liquid) selection_model.select(output_model.index(output_model.indexOf(output), 0), ItemSelectionModel.Toggle)
    }

    id: self
    hoverEnabled: true
    topPadding: 16
    leftPadding: 16
    rightPadding: 16
    bottomPadding: 16
    background: Rectangle {
        color: 'transparent'
        radius: 4
        border.width: self.highlighted ? 1 : 0
        border.color: constants.g500
        Rectangle {
            anchors.fill: parent
            visible: self.hovered
            color: '#00B45A'
            opacity: 0.08
        }
        Rectangle {
            color: '#1F222A'
            width: parent.width
            height: 1
            y: parent.height - 1
        }
    }
    // onClicked: self.toggleSelection()
    contentItem: RowLayout {
        spacing: 20
        AssetIcon {
            Layout.alignment: Qt.AlignCenter
            asset: output.asset
        }
        ColumnLayout {
            RowLayout {
                spacing: 10
                Repeater {
                    model: self.tags
                    delegate: Tag2 {
                        text: modelData.name
                        color: modelData.color ?? 'white'
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 12
                font.weight: 400
                color: '#929292'
                text: self.output.data.txhash + ':' + self.output.data.pt_idx
                wrapMode: Label.Wrap
            }
        }
        ColumnLayout {
            Convert {
                id: convert
                account: self.output.account
                asset: self.output.asset
                unit: 'sats'
                value: String(self.output.data.satoshi)
            }
            Label {
                Layout.alignment: Qt.AlignRight
                font.pixelSize: 14
                font.weight: 600
                text: convert.unitLabel
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#929292'
                font.pixelSize: 14
                font.weight: 600
                text: convert.fiatLabel
                visible: convert.result.fiat_currency ?? false
            }
        }
    }
    readonly property var tags: {
        const output = self.output
        const tags = []
        if (output.expired) tags.push({ name: qsTrId('id_2fa_expired'), color: '#69302E' })
        if (output.locked) tags.push({ name: qsTrId('id_locked') })
        if (output.dust) tags.push({ name: qsTrId('id_dust') })
        if (output.account.network.liquid && !output.confidential) tags.push({ name: qsTrId('id_not_confidential') })
        tags.push({ name: localizedLabel(output.addressType) })
        if (output.unconfirmed) tags.push({ name: qsTrId('id_unconfirmed'), color: '#d2934a' })
        return tags
    }

    component Tag2: Tag {
        background: Rectangle {
            color: Qt.alpha('#FFF', 0.4)
            border.width: 1
            border.color: Qt.alpha('#FFF', 0.6)
            radius: height / 2
        }
        color: 'white'
        font.capitalization: Font.AllUppercase
    }
}
