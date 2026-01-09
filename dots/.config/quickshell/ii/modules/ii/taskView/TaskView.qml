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

                // Round decorators
                Loader {
                    id: roundDecorators
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: barContent.bottom
                        bottom: undefined
                    }
                    height: Appearance.rounding.screenRounding
                    active: showBarBackground && Config.options.bar.cornerStyle === 0 // Hug

                    states: State {
                        name: "bottom"
                        when: Config.options.bar.bottom
                        AnchorChanges {
                            target: roundDecorators
                            anchors {
                                right: parent.right
                                left: parent.left
                                top: undefined
                                bottom: barContent.top
                            }
                        }
                    }

                    sourceComponent: Item {
                        implicitHeight: Appearance.rounding.screenRounding
                        RoundCorner {
                            id: leftCorner
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
                    }
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
        }
    }
}
