import QtQuick 1.0
import com.nokia.meego 1.0
import QtMobility.location 1.1

import "." as MyComponents


Page {
    // orientationLock: PageOrientation.LockLandscape
    // orientationLock: PageOrientation.LockPortrait


    // We want to tell Python whenever our display orientation changes.
    // This is done with the signal "onWidthChanged".  This however is not
    // called at start up, so we also use a single shot timer.
    
    onWidthChanged: {
        displayOrientationChanged()
    }

    Timer {
        interval: 1;
        running: true;
        repeat: false;
        onTriggered: {
            displayOrientationChanged()
        }
    }

    //Tell Python that the display orientation changed
    function displayOrientationChanged() {
        if (width > 600) { // landscape
            rowaltitude.anchors.left = current.horizontalCenter
            rowaltitude.anchors.top = txtcurrentlabel.bottom
            rowname.anchors.right = current.horizontalCenter
            rowinterval.anchors.left = current.horizontalCenter
            rowinterval.anchors.top = separator.bottom
            console.log("[QML INFO] Landscape")
        } else { // portrait
            rowaltitude.anchors.left = rowlongitude.left
            rowaltitude.anchors.top = rowlatitude.bottom
            rowname.anchors.right = current.right
            rowinterval.anchors.left = current.left
            rowinterval.anchors.top = rowname.bottom
            console.log("[QML INFO] Portrait")
        }
    }

    Timer {
        id: timerrecord;
        interval: dialoginterval.model.get(1).value;
        running: true;
        repeat: true;
        onTriggered: {
            sendGPSdata()
        }
    }

    function sendGPSdata() {
        if(bstart.enabled == false && bpause.text == "Pause") { //recording
            points = points + 1
            lblsamples.text = "recorded " + points + " samples"
            qml_to_python.add_point(positionSource.position.coordinate.longitude,
                                    positionSource.position.coordinate.latitude,
                                    positionSource.position.coordinate.altitude,
                                    positionSource.position.speed)

            mapPage.add_point(positionSource.position.coordinate)
        }
        else {
            // console.log("-", timerrecord.interval)
        }
    }

    function convertDecDeg(value, tipo) {
        if (!tipo)
            tipo='N';
        if (!value) {
            return "-";
        } else if (value > 180 || value < 0) {
            // convert coordinate from north to south or east to west if wrong tipo
            return convertDecDeg(-value, (tipo=='N'?'S': (tipo=='E'?'W':tipo) ));
        } else {
            var gpsdeg = parseInt(value);
            var remainder = value - (gpsdeg * 1.0);
            var gpsmin = remainder * 60.0;
            var D = gpsdeg;
            var M = parseInt(gpsmin);
            var remainder2 = gpsmin - (parseInt(gpsmin)*1.0);
            var S = parseInt(remainder2*60.0);
            return tipo + " " + D + "° " +  Math.round(gpsmin * 1000) / 1000
        }
    }

    property int points: 0
    property int waypoint_no: 0

    id: mainPage
    tools: toolbar

    Item {
        id: page
        width: parent.width

        PositionSource {
            id: positionSource
            updateInterval: 1000
            active: true
            // nmeaSource: "nmealog.txt"
            onPositionChanged: {

                if(positionSource.position.longitudeValid) {
                    lbllon.text = convertDecDeg(positionSource.position.coordinate.longitude, "E")
                }

                if(positionSource.position.latitudeValid) {
                    lbllat.text = convertDecDeg(positionSource.position.coordinate.latitude, "N")
                }

                if(positionSource.position.altitudeValid) {
                    lblalt.text = Math.round(positionSource.position.coordinate.altitude) + " m"
                } else {
                    // lblalt.text = "-"
                }

                if(positionSource.position.speedValid) {
                    lblspeed.text = Math.round(positionSource.position.speed * 100) / 100 + " m/s (" +  Math.round(positionSource.position.speed * 360) / 100 + " km/h)"
                } else {
                    lblspeed.text = ""
                }

            }
        }


        Item {
            id: titlebar
            width: parent.width
            height: 70

            Rectangle {
                anchors.fill: parent
                color: "green"
            }
            //Row {
            Image {
                id: imggps
                source: "../img/gps_256.png"
                width: 62
                height: 62
            }

            Label {
                anchors {
                    left: imggps.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                    top: parent.top
                    topMargin: 20
                }
                font.bold: true;
                font.pixelSize: 32
                color: "White"

                text: "GPS-Logger"
            }
            // }
        }


        Flickable {
            id: flickable
            width: parent.width
            anchors.top: titlebar.bottom
            height: mainPage.height - titlebar.height
            contentWidth: parent.width
            contentHeight: col.height + 20
            clip: true

            Column {
                width: parent.width
                id: col
                anchors {
                    left: parent.left
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 10
                    top: parent.top
                }

                Column {
                    width: parent.width
                    spacing: 10

                    id: current
                    Text {
                        id: txtcurrentlabel
                        text: "Current position data"
                        font.bold: true;
                        font.pixelSize: 26
                        verticalAlignment: Text.AlignVCenter
                    }

                    Row {
                        id: rowlongitude
                        anchors {
                            left: parent.left
                            top: txtcurrentlabel.bottom
                            topMargin: 6
                        }
                        Text {
                            text: "Longitude: "
                            font.pixelSize: 22
                        }
                        Text {
                            id: lbllon
                            //text: positionSource.position.coordinate.longitude
                            font.pixelSize: 22
                        }
                    }

                    Row {
                        id: rowlatitude
                        anchors {
                            left: parent.left
                            top: rowlongitude.bottom
                            topMargin: 6
                        }
                        Text {
                            text: "Latitude: "
                            font.pixelSize: 22
                        }
                        Text {
                            id: lbllat
                            //text: positionSource.position.coordinate.latitude
                            font.pixelSize: 22
                        }
                    }

                    Row {
                        id: rowaltitude
                        anchors {
                            left: parent.left
                            top: rowlatitude.bottom
                            topMargin: 6
                        }
                        Text {
                            text: "Altitude: "
                            font.pixelSize: 22
                        }
                        Text {
                            id: lblalt
                            // text: positionSource.position.coordinate.altitude
                            font.pixelSize: 22
                        }
                    }

                    Row {
                        id: rowspeed
                        anchors {
                            left: rowaltitude.left
                            top: rowaltitude.bottom
                            topMargin: 6
                        }
                        Text {
                            text: "Speed: "
                            font.pixelSize: 22
                        }
                        Text {
                            id: lblspeed
                            // text: positionSource.position.speed
                            font.pixelSize: 22
                        }
                    }

                    Rectangle {
                        id: separator
                        height: 1
                        width: parent.width - 20
                        color: "green"
                        anchors {
                            top: rowspeed.bottom
                            topMargin: 6
                        }
                    }

                    Row {
                        id: rowname
                        width: parent.width
                        anchors {
                            left: parent.left
                            top: separator.bottom
                            topMargin: 6
                        }
                        Text {
                            id: lblfilename
                            text: "Name: "
                            font.bold: true
                            font.pixelSize: 22
                            verticalAlignment: Text.AlignVCenter
                            height: txtfilename.height
                        }
                        TextField {
                            id: txtfilename
                            height: 50
                            width: parent.width - lblfilename.width - 20
                        }
                        Text {
                            id: lblrecording
                            font.bold: true
                            font.pixelSize: 22
                            verticalAlignment: Text.AlignVCenter
                            height: 50
                            width: parent.width - lblfilename.width - 20
                            visible: false
                        }
                    }

                    Row {
                        id: rowinterval
                        width: parent.width
                        anchors {
                            right: parent.right
                            top: rowname.bottom
                            topMargin: 6
                        }
                        Text {
                            id: lblinterval
                            text: "Interval: "
                            font.bold: true
                            font.pixelSize: 22
                            verticalAlignment: Text.AlignVCenter
                            height: binterval.height
                        }
                        Button {
                            id: binterval
                            text: dialoginterval.model.get(1).name;
                            font.bold: true;
                            font.pixelSize: 26
                            width: parent.width - lblinterval.width - 20
                            onClicked: {
                                dialoginterval.open();
                            }
                        }

                    }

                    Row {
                        id:buttons
                        width: parent.width

                        anchors {
                            top: rowinterval.bottom
                            topMargin: 6
                        }
                        Button {
                            id: bstart
                            text: "Start"
                            font.bold: true;
                            font.pixelSize: 26
                            width: (parent.width - 5*2 - 6) / 3
                            onClicked: {
                                // console.log("start")
                                var r = qml_to_python.start(txtfilename.text, timerrecord.interval)
                                if(r != "") { //ok
                                    bstart.enabled = false
                                    bstop.enabled = true
                                    bpause.text = "Pause"
                                    bpause.enabled = true
                                    bwaypoint.enabled = true
                                    bwaypoint.text = "Add waypoint"
                                    txtfilename.enabled = false
                                    binterval.enabled = false
                                    txtfilename.visible = false
                                    lblrecording.visible = true
                                    lblrecording.text = r
                                    lblsamples.text = ""
                                    points = 0
                                    waypoint_no = 0
                                    mapPage.remove_all_point()
                                } else { //failed
                                    console.log("start failed")
                                    //ToDo: show error
                                }
                            }
                        }
                        
                        Label {width: 5; height: 1} //spacer
                        
                        Button {
                            id: bstop
                            text: "Stop"
                            font.bold: true;
                            font.pixelSize: 26
                            width: (parent.width - 5*2 - 6) / 3
                            enabled: false
                            onClicked: {
                                dialogstop.open();
                            }
                        }
                        
                        Label {width: 5; height: 1} //spacer
                        
                        Button {
                            id: bpause
                            text: "Pause"
                            font.bold: true;
                            font.pixelSize: 26
                            width: (parent.width - 5*2 - 6) / 3
                            enabled: false
                            onClicked: {
                                if(bpause.text == "Pause") {
                                    qml_to_python.pause()
                                    bpause.text = "Resume"
                                } else {
                                    qml_to_python.resume()
                                    bpause.text = "Pause"
                                }
                            }
                        }

                    }

                    Row {
                        width: parent.width
                        anchors {
                            top: buttons.bottom
                            topMargin: 6
                        }
                        Button {
                            id: bwaypoint
                            text: "Add waypoint"
                            font.bold: true;
                            font.pixelSize: 26
                            width: parent.width -20
                            enabled: false
                            onClicked: {
                                waypoint_no = waypoint_no + 1
                                bwaypoint.text = "Add waypoint (" + waypoint_no + ")"
                                qml_to_python.add_waypoint(positionSource.position.coordinate.longitude,
                                                           positionSource.position.coordinate.latitude,
                                                           positionSource.position.coordinate.altitude,
                                                           positionSource.position.speed,
                                                           waypoint_no)
                             }
                         }
                     }

                    Row {
                        width: parent.width
                        Text {
                            id: lblsamples
                            font.bold: true;
                            font.pixelSize: 22
                        }
                    }

                }

            }
        }

    }



//*******************************************************

    QueryDialog {
        id: dialogstop
        icon: "../img/icon_80.png"
        titleText: "Stop recording"
        message: "Do you really want to stop recording?"
        acceptButtonText: "Yes"
        rejectButtonText : "No"
        onAccepted: {
            //console.log("stop")
            bstart.enabled = true
            bpause.enabled = false
            bpause.text = "Pause"
            bstop.enabled = false
            bwaypoint.enabled = false
            txtfilename.enabled = true
            binterval.enabled = true
            txtfilename.visible = true
            lblrecording.visible = false
            qml_to_python.stop()
        }
    }

//*******************************************************


    SelectionDialog {
        id: dialoginterval
        titleText: "Recording interval"

        model: ListModel {
            //ListElement { name: "½ second";   value:    500 }
            ListElement { name: "1 second";   value:   1000 }
            ListElement { name: "2 seconds";  value:   2000 }
            ListElement { name: "5 seconds";  value:   5000 }
            ListElement { name: "10 seconds"; value:  10000 }
            ListElement { name: "30 seconds"; value:  30000 }
            ListElement { name: "1 minute";   value:  60000 }
            ListElement { name: "2 minutes";  value: 120000 }
            ListElement { name: "5 minutes";  value: 300000 }
            ListElement { name: "10 minutes"; value: 600000 }
        }
        onAccepted: {
            binterval.text = dialoginterval.model.get(dialoginterval.selectedIndex).name
            timerrecord.interval = dialoginterval.model.get(dialoginterval.selectedIndex).value
        }
    }

//*******************************************************



    ToolBarLayout {
        id: toolbar

        ToolButtonRow {
            ToolButton {
                id: bshowmap
                text: "Show map"
                onClicked: {
                    // MyComponents.MapPage.id = "mapPage"
                    pageStack.push(mapPage)
                    mapPage.setmapplugin()
                    mapPage.centermyposition()
                    // pageStack.push(Qt.resolvedUrl("MapPage.qml"))

                    // var coord = Qt.createQmlObject()

                    // pageLoader.source = "MapPage.qml"
                    // pageStack.push(pageLoader)

                    // mapPage = Qt.createComponent("MapPage.qml");
                    // pageStack.push(mapPage)

                }
            }
        }

        ToolIcon {
            iconId: "toolbar-view-menu" ;
            onClicked: myMenu.open();
        }
    }


//*******************************************************


// Loader { id: pageLoader }


    MyComponents.MapPage {
        id: mapPage
    }

//*******************************************************

}
