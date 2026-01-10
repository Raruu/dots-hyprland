import qs
import qs.services
import qs.modules.common
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.common.widgets

Scope {
    id: taskViewScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            screen: modelData

            visible: fadeRoot.opacity > 0 || GlobalStates.taskViewOpen

            WlrLayershell.namespace: "quickshell:taskview"
            // WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: Config.options.bar.cornerStyle === 1 ? -1 : 0 // Cover everything
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Wallpaper Background to hide actual windows
            property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
            property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
            property bool showBarBackground: Config.options.bar.showBackground

            Item {
                id: fadeRoot
                anchors.fill: parent
                focus: true
                opacity: GlobalStates.taskViewOpen ? 1 : 0
                enabled: opacity > 0

                onActiveFocusChanged: {
                    if (!activeFocus && GlobalStates.taskViewOpen) {
                        GlobalStates.taskViewOpen = false;
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }

                // Close when clicking empty space
                MouseArea {
                    anchors.fill: parent
                    onClicked: GlobalStates.taskViewOpen = false
                }

                // Solid background fallback
                Rectangle {
                    anchors.fill: parent
                    color: Appearance.colors.colLayer1 // Use theme background color
                    z: -2
                }

                Image {
                    id: bgWallpaper
                    anchors.fill: parent
                    source: root.wallpaperPath
                    fillMode: Image.PreserveAspectCrop
                    visible: false // Hidden, used as source for blur
                }

                GaussianBlur {
                    anchors.fill: bgWallpaper
                    source: bgWallpaper
                    radius: 100
                    samples: radius * 2 + 1
                    z: -1

                    // Dimming layer
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.4)
                    }
                }

                // The actual content
                TaskViewWidget {
                    anchors.fill: parent
                    panelWindow: root
                    isShowing: fadeRoot.opacity > 0
                }

                // Key handling to close (Escape) or navigate (Arrows - TODO)
                Item {
                    focus: true
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            GlobalStates.taskViewOpen = false;
                        }
                    }
                }
            }

            // Round decorators
            Loader {
                id: roundDecorators
                anchors {
                    left: !Config.options.bar.vertical ? parent.left : undefined
                    right: !Config.options.bar.vertical ? parent.right : undefined
                    top: !Config.options.bar.vertical && !Config.options.bar.bottom ? parent.top : undefined
                    bottom: !Config.options.bar.vertical && Config.options.bar.bottom ? parent.bottom : undefined
                }
                height: !Config.options.bar.vertical ? Appearance.rounding.screenRounding : undefined
                width: Config.options.bar.vertical ? Appearance.rounding.screenRounding : undefined
                active: showBarBackground && Config.options.bar.cornerStyle === 0 // Hug

                states: [
                    State {
                        name: "vertical-left"
                        when: Config.options.bar.vertical && !Config.options.bar.bottom
                        AnchorChanges {
                            target: roundDecorators
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                right: undefined
                            }
                        }
                    },
                    State {
                        name: "vertical-right"
                        when: Config.options.bar.vertical && Config.options.bar.bottom
                        AnchorChanges {
                            target: roundDecorators
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: undefined
                                right: parent.right
                            }
                        }
                    }
                ]

                sourceComponent: Item {
                    implicitHeight: Appearance.rounding.screenRounding

                    // For horizontal bars
                    RoundCorner {
                        id: leftCorner
                        visible: !Config.options.bar.vertical
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                        }

                        implicitSize: Appearance.rounding.screenRounding
                        color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"

                        corner: RoundCorner.CornerEnum.TopLeft
                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            PropertyChanges {
                                leftCorner.corner: RoundCorner.CornerEnum.BottomLeft
                            }
                        }
                    }
                    RoundCorner {
                        id: rightCorner
                        visible: !Config.options.bar.vertical
                        anchors {
                            right: parent.right
                            top: !Config.options.bar.bottom ? parent.top : undefined
                            bottom: Config.options.bar.bottom ? parent.bottom : undefined
                        }
                        implicitSize: Appearance.rounding.screenRounding
                        color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"

                        corner: RoundCorner.CornerEnum.TopRight
                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            PropertyChanges {
                                rightCorner.corner: RoundCorner.CornerEnum.BottomRight
                            }
                        }
                    }

                    // For vertical bars
                    RoundCorner {
                        id: topCorner
                        visible: Config.options.bar.vertical
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }

                        implicitSize: Appearance.rounding.screenRounding
                        color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"

                        corner: RoundCorner.CornerEnum.TopLeft
                        states: State {
                            name: "right"
                            when: Config.options.bar.bottom
                            PropertyChanges {
                                topCorner.corner: RoundCorner.CornerEnum.TopRight
                            }
                        }
                    }
                    RoundCorner {
                        id: bottomCorner
                        visible: Config.options.bar.vertical
                        anchors {
                            bottom: parent.bottom
                            left: !Config.options.bar.bottom ? parent.left : undefined
                            right: Config.options.bar.bottom ? parent.right : undefined
                        }
                        implicitSize: Appearance.rounding.screenRounding
                        color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"

                        corner: RoundCorner.CornerEnum.BottomLeft
                        states: State {
                            name: "right"
                            when: Config.options.bar.bottom
                            PropertyChanges {
                                bottomCorner.corner: RoundCorner.CornerEnum.BottomRight
                            }
                        }
                    }
                }
            }
        }
    }
}
