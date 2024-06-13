import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MainPage {
    function openWallet(wallet) {
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.wallet === wallet) { // && !child.device) {
                stack_layout.currentIndex = i;
                return
            }
        }
        wallet_view.createObject(stack_layout, { wallet })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallets
    }
    function openDevice(device, options) {
        if (stack_layout.currentItem?.device) {
            console.log('current view has device assigned')
            return
        }

        if (stack_layout.currentItem?.wallet) {
            console.log('current view has wallet')
            if (stack_layout.currentItem.wallet.context) {
                console.log('    but wallet has context')
                return
            }
        }

        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (!(child instanceof WalletView)) continue
            if (child.device === device) {
                stack_layout.currentIndex = i;
                console.log('switch to existing device view', i)
                return
            }
            if (child.wallet && device.session && child.wallet.xpubHashId === device.session.xpubHashId) {
                stack_layout.currentIndex = i;
                console.log('switch to existing wallet view with same xpubhashid', i)
                return
            }
        }

        if (options?.prompt ?? true) {
            if (device instanceof JadeDevice && device.state === JadeDevice.StateUninitialized) {
                jade_notification_dialog.createObject(window, { device }).open()
                return
            }

            if (device instanceof LedgerDevice) {
                // TODO ignore connected ledger device for now
                return
            }
        }

        console.log('create view for device', device)
        wallet_view.createObject(stack_layout, { device })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallets
    }
    function openWallets() {
        if (wallets_drawer.visible) {
            wallets_drawer.close()
            return
        }

        let current_index = -1
        let current_wallet
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView) {
                current_index = i
                current_wallet = child.wallet
                break
            }
        }

        if (WalletManager.wallets.length > 1 && current_index < 0) {
            stack_layout.currentIndex = 0
            return
        }

        if (current_index >= 0) {
            if (current_wallet || WalletManager.wallets.length > 0) {
                wallets_drawer.open()
            } else {
                stack_layout.currentIndex = current_index
                side_bar.currentView = SideBar.View.Wallets
            }
            return
        }

        if (WalletManager.wallets.length === 1 && current_index >= 0) {
            stack_layout.currentIndex = current_index
            side_bar.currentView = SideBar.View.Wallets
            return
        }

        const wallet = WalletManager.wallets[0] ?? null
        wallet_view.createObject(stack_layout, { wallet })
        stack_layout.currentIndex = stack_layout.children.length - 1
        side_bar.currentView = SideBar.View.Wallets
    }
    function closeWallet(wallet) {
        stack_layout.currentIndex = 0
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.wallet === wallet) {
                child.destroy()
                break
            }
        }
    }
    function closeDevice(device) {
        stack_layout.currentIndex = 0
        for (let i = 0; i < stack_layout.children.length; ++i) {
            const child = stack_layout.children[i]
            if (child instanceof WalletView && child.device === device) {
                child.destroy()
                break
            }
        }
    }
    function removeWallet(wallet) {
        self.closeWallet(wallet)
        WalletManager.removeWallet(wallet)
        Analytics.recordEvent('wallet_delete')
    }

    property Constants constants: Constants {}

    Action {
        id: preferences_action
        onTriggered: {
            preferences_dialog.createObject(self).open()
            wallets_drawer.close()
            side_bar.currentView = SideBar.View.Preferences
        }
        shortcut: 'Ctrl+,'
    }

    StackView.onActivating: {
        const device = DeviceManager.defaultDevice()
        if (device instanceof JadeDevice) {
            self.openDevice(device)
        } else {
            self.openWallets()
        }
    }
    StackView.onActivated: side_bar.x = 0

    id: self
    leftPadding: side_bar.width
    rightPadding: 0
    title: stack_layout.currentItem?.title ?? ''
    contentItem: Page {
        background: null
        header: AppBanner {
        }
        contentItem: GStackLayout {
            id: stack_layout
            currentIndex: 0
            WalletsView {
                enabled: StackLayout.isCurrentItem
                focus: StackLayout.isCurrentItem
                onOpenWallet: (wallet) => self.openWallet(wallet)
                onOpenDevice: (device) => self.openDevice(device)
                onCreateWallet: self.openWallet(null)
                AnalyticsView {
                    name: 'Home'
                    active: stack_layout.currentIndex === 0
                }
            }
        }
        footer: Bip21Banner {
        }
    }

    Component {
        id: wallet_view
        WalletView {
            enabled: StackLayout.isCurrentItem
            onOpenWallet: (wallet) => self.openWallet(wallet)
            onCloseWallet: (wallet) => self.closeWallet(wallet)
            onCloseDevice: (device) => self.closeDevice(device)
            onRemoveWallet: (wallet) => remove_wallet_dialog.createObject(self, { wallet }).open()
        }
    }

    Component {
        id: remove_wallet_dialog
        RemoveWalletDialog {
            onRemoveWallet: (wallet) => {
                self.removeWallet(wallet)
                stack_layout.currentIndex = 0
            }
        }
    }

    JadeFirmwareController {
        id: firmware_controller
        enabled: true
    }

    JadeDeviceSerialPortDiscoveryAgent {
    }
    DeviceDiscoveryAgent {
    }

    SideBar {
        id: side_bar
        height: parent?.height ?? 0
        parent: Overlay.overlay
        z: 1
        x: -side_bar.width
        Behavior on x {
            SmoothedAnimation {
                velocity: 200
            }
        }
        onPreferencesClicked: preferences_action.trigger()
        onWalletsClicked: openWallets()
    }


    Connections {
        target: DeviceManager
        function onDeviceAdded(device) {
            self.openDevice(device)
        }
        function onDeviceConnected(device) {
            self.openDevice(device)
        }
    }

    Component {
        id: jade_notification_dialog
        JadeNotificationDialog {
            onSetupClicked: (device) => {
                self.openDevice(device, { prompt: false })
                close()
            }
            onClosed: destroy()
        }
    }

    WalletsDrawer {
        id: wallets_drawer
        leftMargin: side_bar.width
        onWalletClicked: (wallet) => {
            wallets_drawer.close()
            self.openWallet(wallet)
        }
        onDeviceClicked: (device) => {
            wallets_drawer.close()
            self.openDevice(device)
        }
    }

    Component {
        id: preferences_dialog
        PreferencesView {
            onClosed: {
                side_bar.currentView = SideBar.View.Wallets
                destroy()
            }
        }
    }

    component Bip21Banner: Collapsible {
        readonly property Wallet wallet: stack_layout.currentItem?.wallet ?? null
        readonly property Context context: self.wallet?.context ?? null
        readonly property Account account: stack_layout.currentItem?.currentAccount ?? null
        readonly property bool compatible: {
            if (!self.account) return false
            const parts = WalletManager.openUrl.split(':')
            const bip21_prefix = self.account.network.data.bip21_prefix
            return bip21_prefix === (parts.length === 1 ? 'bitcoin' : parts[0])
        }
        id: self
        collapsed: !WalletManager.hasOpenUrl
        contentWidth: self.width
        contentHeight: pane.height - 20
        animationVelocity: 200
        Pane {
            id: pane
            leftPadding: 20
            rightPadding: 20
            topPadding: 20
            bottomPadding: 40
            x: 25
            width: self.width - 50
            background: Rectangle {
                color: '#00B45A'
                radius: 8
            }
            contentItem: RowLayout {
                spacing: 20
                ColumnLayout {
                    Label {
                        color: '#FFF'
                        font.pixelSize: 16
                        font.weight: 500
                        opacity: 0.9
                        text: {
                            if (!self.wallet) return 'Select wallet to pay'
                            if (!self.context) return 'Login to pay'
                            if (!self.compatible) return 'Select compatible account to pay'
                            return 'Payment'
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        color: '#FFF'
                        elide: Label.ElideMiddle
                        font.pixelSize: 12
                        font.weight: 600
                        text: WalletManager.openUrl
                    }
                }
                RegularButton {
                    topPadding: 10
                    bottomPadding: 10
                    enabled: self.compatible
                    text: 'Pay'
                    visible: !!self.context
                    onClicked: {
                        stack_layout.currentItem?.send(WalletManager.openUrl)
                        WalletManager.clearOpenUrl()
                    }
                }
                RegularButton {
                    topPadding: 10
                    bottomPadding: 10
                    text: qsTrId('id_cancel')
                    visible: !!self.context
                    onClicked: WalletManager.clearOpenUrl()
                }
                CloseButton {
                    visible: !self.context
                    onClicked: WalletManager.clearOpenUrl()
                }
            }
        }
    }
}
