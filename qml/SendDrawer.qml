import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Account account
    property Asset asset
    id: self
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        initialItem: SendPage {
            context: self.context
            account: self.account
            asset: self.asset
            onClosed: self.close()
        }
    }
    AnalyticsView {
        name: 'Send'
        active: true
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, self.account)
    }
}
