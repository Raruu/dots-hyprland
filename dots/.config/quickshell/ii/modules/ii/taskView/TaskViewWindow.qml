pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item { // Window
    id: root
    property var toplevel
    property var windowData
    property var monitorData
    property var scale
    property bool isShowing: true

    // Properties for smart packing layout
    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 0
    property real targetHeight: 0

    property var widgetMonitor

    property bool hovered: false
    property bool pressed: false

    property string iconPath: Quickshell.iconPath(AppSearch.guessIcon(windowData?.class), "image-missing")

    // Reset animation
    property bool enableAnimation: GlobalStates.taskViewOpen

    // Animate position and size
    x: targetX
    y: targetY
    width: targetWidth
    height: targetHeight

    Behavior on x {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
            from: (widgetMonitor.transform & 1 ? widgetMonitor.height : widgetMonitor.width) / 2
        }
    }
    Behavior on y {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: 300 
            easing.type: Easing.OutCubic
            from: (widgetMonitor.transform & 1 ? widgetMonitor.width : widgetMonitor.height) / 2
        }
    }
    Behavior on width {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
            from: root.width / 2
        }
    }
    Behavior on height {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
            from: root.height / 2
        }
    }
 
    // Rounded corners
    property real radius: Appearance.rounding.normal

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }

    ScreencopyView {
        id: windowPreview
        anchors.fill: parent
        captureSource: root.isShowing ? root.toplevel : null
        live: Config.options.taskView.livePreview

        // Color overlay for interactions
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: pressed ? ColorUtils.transparentize(Appearance.colors.colLayer2Active, 0.5) : hovered ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.7) : "transparent"
            border.width: 0
        }

        Image {
            id: windowIcon
            property real iconSize: Math.min(root.width, root.height) * 0.2
            // Clamp icon size
            readonly property real finalIconSize: Math.max(32, Math.min(64, iconSize))

            anchors.centerIn: parent
            width: finalIconSize
            height: finalIconSize
            source: root.iconPath
            sourceSize: Qt.size(finalIconSize, finalIconSize)
            opacity: hovered ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: hovered = true
            onExited: hovered = false
            onClicked: {
                GlobalStates.taskViewOpen = false;
                if (windowData) {
                    // Focus and bring window to top
                    Hyprland.dispatch(`focuswindow address:${windowData.address}`);
                    Hyprland.dispatch("bringactivetotop");
                }
            }
        }
    }

    // Close Button
    RippleButton {
        id: closeButton
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 10
            rightMargin: 10
        }
        implicitWidth: 36
        implicitHeight: 36
        buttonRadius: Appearance.rounding.full
        // Always visible
        visible: true
        opacity: 1
        z: 10

        onClicked: {
            if (windowData) {
                Hyprland.dispatch(`closewindow address:${windowData.address}`);
            }
        }

        // Red background for close button
        Rectangle {
            anchors.fill: parent
            radius: parent.buttonRadius
            color: Appearance.colors.colError
            opacity: 1
        }

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            iconSize: 20
            text: "close"
            color: Appearance.colors.colOnError
        }
    }
}
