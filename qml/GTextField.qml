import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

TextField {
    id: self
    bottomPadding: 8
    topPadding: 8
    leftPadding: 8
    rightPadding: 8
    background: Rectangle {
        implicitWidth: 200
        radius: 4
        opacity: self.activeFocus ? 1 : (self.enabled ? 0.8 : 0.5)
        color: constants.c500
        border.color: Qt.lighter(color)
        border.width: self.activeFocus ? 1 : 0
    }
}
