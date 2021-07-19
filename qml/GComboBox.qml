import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

ComboBox {
    id: self
    bottomPadding: 10
    topPadding: 10
    leftPadding: 8
    rightPadding: 8 + self.indicator.width + self.spacing
    background: Rectangle {
        implicitWidth: 200
        radius: 4
        opacity: self.activeFocus ? 1 : (self.enabled ? 0.8 : 0.5)
        color: constants.c500
        border.color: Qt.lighter(color)
        border.width: self.activeFocus ? 1 : 0
    }
}
