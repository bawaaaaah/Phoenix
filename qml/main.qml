import QtQuick 2.3
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.0
import Qt.labs.settings 1.0
import phoenix.window 1.0
import phoenix.library 1.0
import QtQuick.Window 2.0

PhoenixWindow {

      // The PhoenixWindow type is the window that Phoenix resides in.
      // Read phoenixwindow.h to find more info about this class.

    id: root;
    width: Screen.width / 2;
    height: Screen.height / 2;
    minimumHeight: 480;
    minimumWidth: 640;
    //swapInterval: 0;
    frameless: false;
    title: "Phoenix";

    property bool clear: false//(phoenixLibrary.count === 0);
    property string accentColor:"#e8433f";
    property int lastWindowStyle: Window.Windowed;
    property string borderColor: "#0b0b0b";
    property string flagValue: "";
    property bool gameShowing: false;
    property string saveDirectory: "";
    property real volumeLevel: 1.0;
    property string prevView: "";
    property bool ranOnce: false;
    property bool screenTimer: false;
    property int filtering: 2;
    property bool stretchVideo: false;
    property string itemInView: "grid";
    property string lastGameName: "Phoenix";
    property string lastSystemName: "";

    property int keyBoardFocus: 2;
    property bool gridFocus: keyBoardFocus === 2;
    property bool consoleBarFocus: keyBoardFocus === 1;

    function playGame(title, system, filename, core)
    {
        // This function is used should be used to play a game.

        if (root.gameAndCoreCheck(title, system, filename, core)) {
            root.lastGameName = title;
            root.lastSystemName = system;
            headerBar.userText = title;
        }
    }

    function gameAndCoreCheck(title, system, file_name, core)
    {
        // This function is used to call the gameAndCoreCheck(), that is
        // a slot defined in the PhoenixWindow class. This function is used
        // to see if the  ?and core loads properly, before actual game data is shown on
        // the screen. This is to hopefully, reduce the change of segment faults, because of
        // incompatible cores.

        // Please call playGame(), instead of this calling this function directly.

        if (phoenixGlobals.validCore(core)) {
            if (phoenixLibraryHelper.needsBios(core))
                return false;

            if (phoenixGlobals.validGame(file_name)) {
                windowStack.push({item: gameView, properties: {coreName: core, gameName: file_name, isRunning: true, replace: true}});
                return true;
             }
        }

        return false;
    }

    onGameShowingChanged: {
        if (gameShowing) {
            headerBar.previousViewIcon = headerBar.viewIcon;
            headerBar.viewIcon = "../assets/GameView/home.png";
        }
        else {
            headerBar.viewIcon = headerBar.previousViewIcon;
            if (root.visibility === Window.FullScreen)
                root.visibility = root.lastWindowStyle;
        }
    }

    onWidthChanged: {
        settingsDropDown.state = "retracted";
    }


    function swapScreenSize(){
        // This function is used to set the PhoenixWindow's visibility and make sure
        // that the proper visibility is set.
        if (root.visibility == Window.FullScreen)
            root.visibility = lastWindowStyle;
        else {
            lastWindowStyle = root.visibility;
            root.visibility = Window.FullScreen;
        }
    }

    Rectangle {
        id: leftBorder;
        anchors {
            top: parent.top;
            left: parent.left;
            bottom: parent.bottom;
        }
        width: 1;
        color: borderColor;
    }

    Rectangle {
        id: rightBorder;
        anchors {
            top: parent.top;
            right: parent.right;
            bottom: parent.bottom;
        }
        width: 1;
        color: borderColor;
    }

    Rectangle {
        id: bottomBorder;
        anchors {
            bottom: bottom.top;
            left: parent.left;
            right: parent.right;
        }
        height: 1;
        color: borderColor;
    }

    PhoenixLibrary {
        id: phoenixLibrary;
    }

    MouseArea {
        anchors.fill: parent;
        enabled: settingsDropDown.visible;
        onClicked: settingsDropDown.visible = false;
    }

    Component {
        id: gameGrid;

        // This is one of the components that the 'gameStack' is allowed to load.
        // The GameGrid class lives in this component.

        Item {
            id: backdropGrid;
            property string actionColor: "#e8433f";
            property int borderWidth: 5;
            property bool showBorder: false;
        Rectangle {
            id: actionBorderLeft;
            z: grid.z + 1;
            visible: parent.showBorder;
            color: parent.actionColor;
            anchors {
                top: parent.top;
                topMargin: 1;
                bottomMargin: 1;
                bottom: parent.bottom;
                left: parent.left;
            }
            width: parent.borderWidth;

            Rectangle {
                anchors {
                    left: parent.left;
                    top: parent.top;
                    bottom: parent.bottom;
                }
                width: 1;
                color: "#f27b77";
            }

            Rectangle {
                anchors {
                    left: parent.left;
                    top: parent.top;
                    right: parent.right;
                }
                height: 1;
                color: "#f27b77";
            }

            Rectangle {
                anchors {
                    left: parent.left;
                    right: parent.right;
                    bottom: parent.bottom;
                }
                height: 1;
                color: "#f27b77";
            }

        }

        Rectangle {
            id: actionBorderTop;
            color: parent.actionColor;
            z: grid.z + 1;
            visible: parent.showBorder;
            anchors {
                top: parent.top;
                topMargin: 1;
                left: actionBorderLeft.right;
                right: parent.right;
                rightMargin: 1;
            }
            height: parent.borderWidth;

            Rectangle {
                anchors {
                    left: parent.left;
                    top: parent.top;
                    right: parent.right;
                }
                height: 1;
                color: "#f27b77";
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom;
                    top: parent.top;
                    right: parent.right;
                }
                width: 1;
                color: "#f27b77";
            }
        }

        Rectangle {
            id: actionBorderRight;
            color: parent.actionColor;
            visible: parent.showBorder;
            z: grid.z + 1;
            anchors {
                top: actionBorderTop.bottom;
                bottom: actionBorderBottom.top;
                right: parent.right;
                rightMargin: 1;
            }
            width: parent.borderWidth

            Rectangle {
                anchors {
                    bottom: parent.bottom;
                    top: parent.top;
                    right: parent.right;
                }
                width: 1;
                color: "#f27b77";
            }
        }

        Rectangle {
            id: actionBorderBottom;
            color: parent.actionColor;
            visible: parent.showBorder;
            z: grid.z + 1;
            anchors {
                bottom: parent.bottom;
                bottomMargin: 1;
                left: actionBorderLeft.right;
                right: parent.right;
                rightMargin: 1;
            }
            height: parent.borderWidth;

            Rectangle {
                anchors {
                    left: parent.left;
                    bottom: parent.bottom;
                    right: parent.right;
                }
                height: 1;
                color: "#f27b77";
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom;
                    top: parent.top;
                    right: parent.right;
                }
                width: 1;
                color: "#f27b77";
            }
        }

        GameGrid {
            id: grid;

            DropArea {
                anchors.fill: parent;
                onEntered: {
                    backdropGrid.showBorder = true;
                    phoenixLibrary.cacheUrls(drag.urls);
                }

                onDropped: {
                    phoenixLibrary.importUrls = true;
                    backdropGrid.showBorder = false;
                }
                onExited:  backdropGrid.showBorder = false;
            }

            //MouseArea {
               // anchors.fill: parent;
                //propagateComposedEvents: true;
                //hoverEnabled: true;
                //onEntered: {
                //    backdropGrid.showBorder = true;
                //}

                //onExited: backdropGrid.showBorder = false;
            //}
            property string itemName: "grid";
            color: "#292727";
            zoomFactor: headerBar.sliderValue;
            zoomSliderPressed: headerBar.sliderPressed;
            anchors.fill: parent;
            //height: parent.height;
            //width: parent.width;
            Behavior on height {
                PropertyAnimation {}
            }

            Behavior on width {
                PropertyAnimation {}
            }
        }
        }
    }

    Component {

        // This component is another one of the valid components that the 'gameStack'
        // can load.

        id: gameTable;

        Item {
            id: backdropGrid;
            property string actionColor: "#e8433f";
            property int borderWidth: 5;
            property bool showBorder: false;
            Rectangle {
                id: actionBorderLeft;
                z: table.z + 1;
                visible: parent.showBorder;
                color: parent.actionColor;
                anchors {
                    top: parent.top;
                    topMargin: 1;
                    bottomMargin: 1;
                    bottom: parent.bottom;
                    left: parent.left;
                }
                width: parent.borderWidth;

                Rectangle {
                    anchors {
                        left: parent.left;
                        top: parent.top;
                        bottom: parent.bottom;
                    }
                    width: 1;
                    color: "#f27b77";
                }

                Rectangle {
                    anchors {
                        left: parent.left;
                        top: parent.top;
                        right: parent.right;
                    }
                    height: 1;
                    color: "#f27b77";
                }

                Rectangle {
                    anchors {
                        left: parent.left;
                        right: parent.right;
                        bottom: parent.bottom;
                    }
                    height: 1;
                    color: "#f27b77";
                }

            }

            Rectangle {
                id: actionBorderTop;
                color: parent.actionColor;
                z: table.z + 1;
                visible: parent.showBorder;
                anchors {
                    top: parent.top;
                    topMargin: 1;
                    left: actionBorderLeft.right;
                    right: parent.right;
                    rightMargin: 1;
                }
                height: parent.borderWidth;

                Rectangle {
                    anchors {
                        left: parent.left;
                        top: parent.top;
                        right: parent.right;
                    }
                    height: 1;
                    color: "#f27b77";
                }

                Rectangle {
                    anchors {
                        bottom: parent.bottom;
                        top: parent.top;
                        right: parent.right;
                    }
                    width: 1;
                    color: "#f27b77";
                }
            }

            Rectangle {
                id: actionBorderRight;
                color: parent.actionColor;
                visible: parent.showBorder;
                z: table.z + 1;
                anchors {
                    top: actionBorderTop.bottom;
                    bottom: actionBorderBottom.top;
                    right: parent.right;
                    rightMargin: 1;
                }
                width: parent.borderWidth

                Rectangle {
                    anchors {
                        bottom: parent.bottom;
                        top: parent.top;
                        right: parent.right;
                    }
                    width: 1;
                    color: "#f27b77";
                }
            }

            Rectangle {
                id: actionBorderBottom;
                color: parent.actionColor;
                visible: parent.showBorder;
                z: table.z + 1;
                anchors {
                    bottom: parent.bottom;
                    bottomMargin: 1;
                    left: actionBorderLeft.right;
                    right: parent.right;
                    rightMargin: 1;
                }
                height: parent.borderWidth;

                Rectangle {
                    anchors {
                        left: parent.left;
                        bottom: parent.bottom;
                        right: parent.right;
                    }
                    height: 1;
                    color: "#f27b77";
                }

                Rectangle {
                    anchors {
                        bottom: parent.bottom;
                        top: parent.top;
                        right: parent.right;
                    }
                    width: 1;
                    color: "#f27b77";
                }
            }
            GameTable {
                id: table;
                itemName: "table";
                highlightColor: "#4a4a4a";
                textColor: "#f1f1f1";
                headerColor: "#262626";
                anchors.fill: parent;
                DropArea {
                    anchors.fill: parent;
                    onEntered: {
                        backdropGrid.showBorder = true;
                        phoenixLibrary.cacheUrls(drag.urls);
                    }

                    onDropped: {
                        phoenixLibrary.importUrls = true;
                        backdropGrid.showBorder = false;
                    }
                    onExited:  backdropGrid.showBorder = false;
                }
            }
        }
    }

    Settings {

        // This is the Settings type that is used to save and load U.I. information.

        id: settings;
        category: "UI";
        //property alias windowX: root.x;
        //property alias windowY: root.y;
        //property alias windowWidth: root.width;
        //property alias windowHeight: root.height;
        property alias volumeLevel: root.volumeLevel;
        property alias smooth: root.filtering;
        property alias stretchVideo: root.stretchVideo;
    }

    HeaderBar {
        id: headerBar;
        anchors {
            left: parent.left;
            right: parent.right;
            top: parent.top;
        }

        Behavior on height {
            NumberAnimation {
                duration: 150;
            }
        }

        height: 62;
        //color: "#3b3b3b";
        fontSize: 14;
    }

    DropShadow {
        anchors.fill: source;
        source: biosWarning;
        color: "black";
        transparentBorder: true;
        verticalOffset: 1;
        horizontalOffset: 0;
        radius: 4;
        samples: radius * 2;
        visible: biosWarning.visible;
    }

    Rectangle {

        // This Rectangle is the warning that shows up whenever a game is launched
        // and it contains missing bios files. This type is complete and so,
        // can and should, be work on. Also, this type should be moved into it's own
        // .qml file. Maybe even rename the 'id' value of this type, so that it can accept any
        // type of warning.

        // Use the userNotifications Q_PROPERTIES in order to set and show useful information
        // to the user.

        id: biosWarning;
        visible: userNotifications.biosNotification !== "";
        anchors {
            top: headerBar.bottom;
            horizontalCenter: parent.horizontalCenter;
            topMargin: 12;
        }
        border {
            width: 1;
            color: "#a42d45";
        }

        MouseArea {
            anchors.fill: parent;
            onClicked: parent.height = (parent.height == 28) ? 300 : 28;
        }

        Behavior on height {
            PropertyAnimation {
                duration: 200;

            }
        }

        width: 250;
        height: 28;
        radius: 8;
        gradient: Gradient {
            GradientStop {position: 0.0; color: "#db3e5b";}
            GradientStop {position: 1.0; color: "#db2346";}
        }

        Column {
            anchors {
                top: parent.top;
                topMargin: 28;
                left: parent.left;
                right: parent.right;
                leftMargin: 16;
                rightMargin: 16;
            }

            Rectangle {
                color: "black";
                opacity: 0.25;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
                height: 1;
            }
            Rectangle {
                color: "white";
                opacity: 0.25;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
                height: 1;
            }
        }

        Rectangle {
            anchors {
                left: parent.left;
                top: parent.top;
                leftMargin: 6;
                topMargin: 5;
            }
            height: 19;
            width: height;
            radius: width / 2;
            color: "black";
            opacity: 0.2;

            CustomBorder {
                color: "white";
                opacity: 0.8;
            }

            MouseArea {
                anchors.fill: parent;
                onClicked: {
                    userNotifications.biosNotification = "";
                    biosWarning.visible = false;
                }
            }
        }

        Text {
            text: userNotifications.biosNotification;
            anchors {
                top: parent.top;
                topMargin: 7;
                horizontalCenter: parent.horizontalCenter;
            }


            color: "#f1f1f1";
            font {
                family: "Sans";
                bold: true;
                pixelSize: 12;
            }
        }

        Rectangle {
            radius: parent.radius;
            anchors {
                fill: parent;
                margins: 1;
            }

            color: "transparent";
            border {
                width: 1;
                color: "white"
            }
            opacity: 0.3;
        }
    }

    SettingsDropDown {
        id: settingsDropDown;
        z: headerBar.z + 1;
        visible: false;

        anchors {
            top: headerBar.bottom;
            topMargin: 3;
            left: parent.left;
            leftMargin: 10;
        }
        height: 275;
        width: 125;
        stackBackgroundColor: "#2e2e2e";
        contentColor: "#f4f4f4";
        textColor: "#f1f1f1";
    }

    RectangularGlow {
        anchors.fill: settingsDropDown;
        visible: settingsDropDown.visible;
        color: "#80000000";
        glowRadius: 10
        spread: 0;
        cornerRadius: 6;
    }


    StackView {
        id: windowStack;
        z: headerBar.z - 1;

        height: headerBar.visible ? (parent.height - headerBar.height) : (parent.height);
        anchors {
            top: (currentItem !== null && currentItem.stackName == "gameview") ? headerBar.top : headerBar.bottom;
            left: parent.left;
            right: parent.right;
            bottom: parent.bottom;
        }

        initialItem: homeScreen;

        property string gameStackItemName: {
            if (currentItem != null && typeof currentItem.stackName !== "undefined") {
                return currentItem.stackName;
            }
            else {
                return "";
            }
        }

        delegate: StackViewDelegate {
            function transitionFinished(properties)
            {
                properties.exitItem.x = 0;
            }
            pushTransition: StackViewTransition {
                PropertyAnimation {
                    target: enterItem;
                    property: "x";
                    from: -enterItem.width;
                    to: 0;
                    duration: 600;
                }
                PropertyAnimation {
                    target: exitItem;
                    property: "x";
                    from: 0;
                    to: -exitItem.width;
                    duration: 600;
                }
            }
       }
    }

    Component {
        id: gameView;
        GameView {
        }
    }

    Component {
        id: homeScreen;

        Item {
            id: backdropGrid;
            property string stackName: "homescreen";
            property StackView stackId: gameStack;

            property string actionColor: "#e8433f";
            property int borderWidth: 5;
            property bool showBorder: false;

                    //Rectangle {
                      //  anchors {
                        //    fill: parent;
                       // }
                       // opacity: 0.1;



                       // color: "#f27b77";
                    //}


            Rectangle {
                id: actionBorderLeft;
                z: consoleBar.z + 1;
                visible: parent.showBorder;
                color: parent.actionColor;
                anchors {
                    top: parent.top;
                    topMargin: 1;
                    bottomMargin: 1;
                    bottom: parent.bottom;
                    left: parent.left;
                }
                width: parent.borderWidth;

                Rectangle {
                    anchors {
                        left: parent.left;
                        top: parent.top;
                        bottom: parent.bottom;
                    }
                    width: 1;
                    color: "#f27b77";
                }

                Rectangle {
                    anchors {
                        left: parent.left;
                        top: parent.top;
                        right: parent.right;
                    }
                    height: 1;
                    color: "#f27b77";
                }

                Rectangle {
                    anchors {
                        left: parent.left;
                        right: parent.right;
                        bottom: parent.bottom;
                    }
                    height: 1;
                    color: "#f27b77";
                }

            }

            Rectangle {
                id: actionBorderTop;
                color: parent.actionColor;
                z: consoleBar.z + 1;
                visible: parent.showBorder;
                anchors {
                    top: parent.top;
                    topMargin: 1;
                    left: actionBorderLeft.right;
                    right: consoleBar.right;
                    rightMargin: 1;
                }
                height: parent.borderWidth;

                Rectangle {
                    anchors {
                        left: parent.left;
                        top: parent.top;
                        right: parent.right;
                    }
                    height: 1;
                    color: "#f27b77";
                }

                Rectangle {
                    anchors {
                        bottom: parent.bottom;
                        top: parent.top;
                        right: parent.right;
                    }
                    width: 1;
                    color: "#f27b77";
                }
            }

            Rectangle {
                id: actionBorderRight;
                color: parent.actionColor;
                visible: parent.showBorder;
                z: consoleBar.z + 1;
                anchors {
                    top: actionBorderTop.bottom;
                    bottom: actionBorderBottom.top;
                    right: consoleBar.right;
                    rightMargin: 1;
                }
                width: parent.borderWidth

                Rectangle {
                    anchors {
                        bottom: parent.bottom;
                        top: parent.top;
                        right: parent.right;
                    }
                    width: 1;
                    color: "#f27b77";
                }
            }

            Rectangle {
                id: actionBorderBottom;
                color: parent.actionColor;
                visible: parent.showBorder;
                z: consoleBar.z + 1;
                anchors {
                    bottom: parent.bottom;
                    bottomMargin: 1;
                    left: actionBorderLeft.right;
                    right: consoleBar.right;
                    rightMargin: 1;
                }
                height: parent.borderWidth;

                Rectangle {
                    anchors {
                        left: parent.left;
                        bottom: parent.bottom;
                        right: parent.right;
                    }
                    height: 1;
                    color: "#f27b77";
                }

                Rectangle {
                    anchors {
                        bottom: parent.bottom;
                        top: parent.top;
                        right: parent.right;
                    }
                    width: 1;
                    color: "#f27b77";
                }
            }

            ConsoleBar {
                id: consoleBar;
                z: headerBar.z - 1;
                color: "#292727";
                anchors {
                    left: parent.left;
                    top: parent.top;
                    bottom: parent.bottom;
                }
                width: 225;

                DropArea {
                    anchors.fill: parent;
                    onEntered: {
                        backdropGrid.showBorder = true;
                        phoenixLibrary.cacheUrls(drag.urls);
                    }

                    onDropped: {
                        phoenixLibrary.importUrls = true;
                        backdropGrid.showBorder = false;
                    }
                    onExited:  backdropGrid.showBorder = false;
                }
            }

            StackView {
                id: gameStack;
                z: windowStack.z;

                initialItem: {
                    if (root.clear === true)
                        return emptyScreen;

                    return gameGrid;
                }

                anchors {
                    left: consoleBar.right;
                    right: parent.right;
                    top: parent.top;
                    bottom: parent.bottom;
                }

                InputIndicator {
                    z: 100;
                    id: inputIndicator;
                    visible: false;
                    anchors {
                        left: parent.left;
                        top: parent.top;
                        topMargin: 12;
                        leftMargin: 12;
                    }

                    height: 50;
                    width: height;
                }

            }

            Component {
                id: emptyScreen;

                Rectangle {
                    property string itemName: "empty";
                    color: "#1d1e1e";

                    Column {
                        anchors.centerIn: parent;
                        spacing: 30;

                        Column {
                            //anchors.horizontalCenter: parent.horizontalCenter;
                            spacing: 2;
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter;
                                text: "Get Some Games"
                                color: "#f1f1f1";
                                font {
                                    family: "Sans";
                                    pixelSize: 26;
                                }
                                horizontalAlignment: Text.AlignHCenter;
                            }

                            Label {

                                text: "Phoenix can't seem to find your games."
                                color: "gray";
                                font {
                                    family: "Sans";
                                    pixelSize: 16;
                                }
                                horizontalAlignment: Text.AlignHCenter;
                            }

                        }


                        FileDialog {
                            id: pathDialog;
                            selectFolder: true;
                            title: "Add Game Folder";
                            onAccepted: {
                                phoenixLibrary.startAsyncScan(fileUrl);
                            }
                        }

                        Button {
                            id: importGamesBtn;
                            onClicked: pathDialog.open();
                            property string backgroundColor: "#000000FF";
                            onHoveredChanged: {
                                if (hovered) {
                                    backgroundColor = "#525252";
                                }
                                else
                                    backgroundColor = "#000000FF";
                            }

                            style: ButtonStyle {
                                background: Rectangle {
                                    color: importGamesBtn.backgroundColor;
                                }

                                label: Row {
                                    spacing: 25;
                                    Image {
                                        source: "../assets/folder-8x.png"
                                        height: 40;
                                        width: 40;
                                        sourceSize {
                                            width: 40;
                                            height: 40;
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter;
                                        spacing: 2;
                                        Label {
                                            text: "Add Games";
                                            color: "#f1f1f1";
                                            font {
                                                family: "Sans";
                                                pixelSize: 18;
                                                bold: true;
                                            }
                                        }

                                        Label {
                                            text: "Choose your games folder.";
                                            color: "gray";
                                            font {
                                                family: "Sans";
                                                pixelSize: 16;
                                            }
                                        }
                                    }

                                }

                            }
                        }

                        Button {
                            id: importLibrarBtn;
                            property string backgroundColor: "#000000FF";
                            onClicked: {
                                pathDialog.selectFolder = false;
                                pathDialog.title = "Import Library File";
                                pathDialog.nameFilters = ["Library file (*.json)", "All files (*)"];
                                pathDialog.open();
                            }
                            onHoveredChanged: {
                                if (hovered) {
                                    backgroundColor = "#525252";
                                }
                                else
                                    backgroundColor = "#000000FF";
                            }

                            style: ButtonStyle {
                                background: Rectangle {
                                    //opacity: 0.3;
                                    color: importLibrarBtn.backgroundColor;
                                }
                                label: Row {
                                    spacing: 25;
                                    Image {
                                        source: "../assets/file-8x.png";
                                        height: 40;
                                        width: 40;
                                        sourceSize {
                                            width: 40;
                                            height: 40;
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter;
                                        spacing: 2;
                                        Label {
                                            text: "Import Library";
                                            color: "#f1f1f1";
                                            font {
                                                family: "Sans";
                                                pixelSize: 18;
                                            }
                                        }
                                        Label {
                                            text: "Add from a Hard Drive.";
                                            color: "gray";
                                            font {
                                                family: "Sans";
                                                pixelSize: 16;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
