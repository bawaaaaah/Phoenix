import QtQuick 2.3
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

ScrollView {
    id: scrollView;
    property string frameColor: "#292727";
    property bool borderEnabled: true;
    property int handleHeight: 30;

    style: ScrollViewStyle {
        id: scrollStyle;
        property int handleWidth: 12
        transientScrollBars: false;
        scrollToClickedPosition: false;
        handleOverlap: -3;

        Behavior on handleWidth {
            PropertyAnimation {
                easing {
                    type: Easing.Linear;
                }
                duration: 100;
            }
        }

        frame: Item {
            //width: 0;
        }

        handle: Rectangle {
            color: "red"
            radius: 3;
            x: 3;
            implicitWidth: scrollStyle.handleWidth - (x * 2);
            implicitHeight: scrollView.handleHeight;
            gradient: Gradient {
                GradientStop {position: 0.0; color: "#2b2a2b";}
                GradientStop {position: 1.0; color: "#252525";}
            }

            Rectangle {
                color: "#525254";
                anchors {
                    top: parent.top;
                    left: parent.left;
                    leftMargin: 1;
                    rightMargin: 1;
                    right: parent.right;
                }
                height: 1;
            }

            Rectangle {
                anchors {
                    left: parent.left;
                    top: parent.top;
                    bottom: parent.bottom;
                    bottomMargin: 1;
                    topMargin: 1;
                }
                color: "#414142";
                width: 1;
            }

            Rectangle {
                anchors {
                    right: parent.right;
                    top: parent.top;
                    bottom: parent.bottom;
                    bottomMargin: 1;
                    topMargin: 1;
                }
                color: "#414142";
                width: 1;
            }

            Rectangle {
                color: "#323233";
                anchors {
                    bottom: parent.bottom;
                    left: parent.left;
                    leftMargin: 1;
                    rightMargin: 1;
                    right: parent.right;
                }
                height: 1;
            }
        }

        scrollBarBackground: Rectangle {
            id: scrollBackground;
            radius: 3;
            color: "#1c1c1c";
            height: control.height;
            width: styleData.hovered ? 20 : 12;
            onWidthChanged:  {
                if (styleData.hovered)
                    scrollStyle.handleWidth = 20;
                else
                    scrollStyle.handleWidth = 12;
            }

            border {
                width: 1;
                color: "#1a1a1a";
            }

            Behavior on width {
                PropertyAnimation {
                    easing {
                        type: Easing.Linear;
                    }
                    duration: 100;
                }
            }
        }

        // hide these controls
        incrementControl: Rectangle {
            implicitWidth: 0;
            implicitHeight: 0;
        }

        decrementControl: Rectangle {
            implicitWidth: 0;
            implicitHeight: 0;

        }


    }
}
