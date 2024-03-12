import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDialog {
    required property Session session

    id: self
    clip: true
    header: null
    onClosed: self.destroy()
    Overlay.modal: Rectangle {
        anchors.fill: parent
        color: 'black'
        opacity: 0.6
    }
    SessionController {
        id: controller
        context: self.context
        session: self.session
        onFinished: self.accept()
        onFailed: (error) => stack_view.replace(error_page, { error })
    }
    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: stack_view
    }
    Component.onCompleted: controller.cancelTwoFactorReset()
    contentItem: GStackView {
        id: stack_view
        implicitWidth: {
            let w = 400
            for (let i = 0; i < stack_view.depth; i++) {
                const item = stack_view.get(i, StackView.DontLoad)
                if (item) w = Math.max(w, item.implicitWidth)
            }
            return w
        }
        implicitHeight: {
            let h = 400
            for (let i = 0; i < stack_view.depth; i++) {
                const item = stack_view.get(i, StackView.DontLoad)
                if (item) h = Math.max(h, item.implicitHeight)
            }
            return h
        }
    }

    Component {
        id: error_page
        ErrorPage {
            rightItem: CloseButton {
                onClicked: self.close()
            }
        }
    }
}
