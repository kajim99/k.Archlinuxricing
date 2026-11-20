import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property var taskList
    property string emptyPlaceholderIcon
    property string emptyPlaceholderText
    property int todoListItemSpacing: 5
    property int todoListItemPadding: 8
    property int listBottomPadding: 80

    StyledListView {
        id: listView
        anchors.fill: parent
        spacing: root.todoListItemSpacing
        animateAppearance: false
        model: ScriptModel {
            values: root.taskList
        }
        delegate: Item {
            id: todoItem
            required property var modelData
            property bool pendingDoneToggle: false
            property bool pendingDelete: false
            property bool enableHeightAnimation: false

            implicitHeight: todoItemRectangle.implicitHeight
            width: ListView.view.width
            clip: true

            Behavior on implicitHeight {
                enabled: enableHeightAnimation
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            Rectangle {
                id: todoItemRectangle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: todoContentRowLayout.implicitHeight
                color: Appearance.colors.colLayer2
                radius: Appearance.rounding.small

                ColumnLayout {
                    id: todoContentRowLayout
                    anchors.left: parent.left
                    anchors.right: parent.right

                    StyledText {
                        id: todoContentText
                        Layout.fillWidth: true // Needed for wrapping
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.topMargin: todoListItemPadding
                        text: todoItem.modelData.content
                        wrapMode: Text.Wrap
                    }
                    // Patched 2026-11-19: optional "cmd" field (todo add ... --cmd ...) shown as a copyable code box
                    Rectangle {
                        visible: (todoItem.modelData.cmd ?? "").length > 0
                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        implicitHeight: todoCmdText.implicitHeight + 12
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: Appearance.colors.colPrimary
                        StyledText {
                            id: todoCmdText
                            anchors.fill: parent
                            anchors.margins: 6
                            text: todoItem.modelData.cmd ?? ""
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colPrimary
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                    RowLayout {
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.bottomMargin: todoListItemPadding
                        Item {
                            Layout.fillWidth: true
                        }
                        TodoItemActionButton {
                            Layout.fillWidth: false
                            visible: (todoItem.modelData.cmd ?? "").length > 0
                            tooltipText: "Copy command"
                            onClicked: {
                                Quickshell.execDetached(["wl-copy", "--", todoItem.modelData.cmd]);
                                Quickshell.execDetached(["notify-send", "Copied", todoItem.modelData.cmd, "-a", "To Do"]);
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "content_copy"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                        TodoItemActionButton {
                            Layout.fillWidth: false
                            onClicked: {
                                if (!todoItem.modelData.done)
                                    Todo.markDone(todoItem.modelData.originalIndex);
                                else
                                    Todo.markUnfinished(todoItem.modelData.originalIndex);
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: todoItem.modelData.done ? "remove_done" : "check"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                        TodoItemActionButton {
                            Layout.fillWidth: false
                            onClicked: {
                                Todo.deleteItem(todoItem.modelData.originalIndex);
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "delete_forever"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        // Placeholder when list is empty
        visible: opacity > 0
        opacity: taskList.length === 0 ? 1 : 0
        anchors.fill: parent

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: Appearance.m3colors.m3outline
                text: emptyPlaceholderIcon
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3outline
                horizontalAlignment: Text.AlignHCenter
                text: emptyPlaceholderText
            }
        }
    }
}
