import QtQuick 1.0
import com.nokia.meego 1.0
import QtMobility.location 1.1

import "." as MyComponents


Page {
    id: mainPage

    // We here define the portrait layout.  `displayOrientationChanged`
    // handles the switch to landscape or back to portrait.  We activate it
    // `onWidthChanged` and we make sure it is also called at start up, with
    // a single shot `Timer`, after 1ms.

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

    function displayOrientationChanged() {
        if (width > 600) { // landscape
            rowaltitude.anchors.left = current.horizontalCenter
            rowaltitude.anchors.top = txtcurrentlabel.bottom
            rowname.anchors.right = current.horizontalCenter
            rowinterval.anchors.left = current.horizontalCenter
            rowinterval.anchors.top = separator.bottom
            rowsamples.anchors.left = current.horizontalCenter
            rowsamples.anchors.top = current.top
            binterval.width = (width - 5*2 - 20) / 3
            // tie them to the label to the left
            txtfilename.anchors.right = undefined
            lblrecording.anchors.right = undefined
            txtfilename.anchors.left = lblfilename.right
            lblrecording.anchors.left = lblfilename.right
            rowwaypoint_1.anchors.right = current.horizontalCenter
            rowwaypoint_2.anchors.top = rowbuttons.bottom
            bwpt_1.width = (parent.width - 50) / 6
            bwpt_2.width = (parent.width - 50) / 6
            bwpt_3.width = (parent.width - 50) / 6
            bwpt_4.width = (parent.width - 50) / 6
            bwpt_5.width = (parent.width - 50) / 6
            bwpt_6.width = (parent.width - 50) / 6
            console.log("[QML INFO] Landscape")
        } else { // portrait
            rowaltitude.anchors.left = rowlongitude.left
            rowaltitude.anchors.top = rowlatitude.bottom
            rowname.anchors.right = current.right
            rowinterval.anchors.left = current.left
            rowinterval.anchors.top = rowname.bottom
            rowsamples.anchors.left = current.left
            rowsamples.anchors.top = rowwaypoint_2.bottom
            binterval.width = 2 * (width - 5*2 - 20) / 3 + 5
            txtfilename.width = 2 * (width - 5*2 - 20) / 3 + 5
            lblrecording.width = 2 * (width - 5*2 - 20) / 3 + 5
            // tie them to the containing box
            txtfilename.anchors.left = undefined
            lblrecording.anchors.left = undefined
            txtfilename.anchors.right = rowname.right
            lblrecording.anchors.right = rowname.right
            // tie second half of waypoint buttons
            rowwaypoint_1.anchors.right = current.right
            rowwaypoint_2.anchors.top = rowwaypoint_1.bottom
            bwpt_1.width = (parent.width - 32) / 3
            bwpt_2.width = (parent.width - 32) / 3
            bwpt_3.width = (parent.width - 32) / 3
            bwpt_4.width = (parent.width - 32) / 3
            bwpt_5.width = (parent.width - 32) / 3
            bwpt_6.width = (parent.width - 32) / 3
            console.log("[QML INFO] Portrait")
        }
    }

    Timer {
        id: timerrecord
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
            app.add_point(positionSource.position.coordinate.longitude,
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
        } else if (value > 180) {  // it's a longitude and we swap E/W
            return convertDecDeg(360.0-value, (tipo=='E'?'W':'E'));
        } else if (value < 0) {  // swap N/S and E/W
            return convertDecDeg(-value, (tipo=='N'?'S': (tipo=='E'?'W':tipo) ));
        } else {
            var gpsdegrees = parseInt(value);
            var remainder = value - (gpsdegrees * 1.0);
            var gpsminutes = remainder * 60.0;
            return tipo + " " + gpsdegrees + "° " + gpsminutes.toFixed(3) + "’"
        }
    }

    property int points: 0
    property int waypoint_no: 0

    tools: toolbar

    Item {
        id: page
        width: parent.width

        PositionSource {
            id: positionSource
            updateInterval: 1000  // update screen once per second, this is not logging.
            active: true
            onPositionChanged: {
                if(positionSource.position.longitudeValid) {
                    lbllon.text = convertDecDeg(positionSource.position.coordinate.longitude, "E")
                }

                if(positionSource.position.latitudeValid) {
                    lbllat.text = convertDecDeg(positionSource.position.coordinate.latitude, "N")
                }

                if(positionSource.position.altitudeValid) {
                    lblalt.text = Math.round(positionSource.position.coordinate.altitude) + " m"
                } // my GPS gives a valid altitude every two readings.

                if(positionSource.position.speedValid) {
                    lblbigspeed.text = Math.round(positionSource.position.speed * 3.60)
                    lblspeedmps.text = Math.round(positionSource.position.speed * 100) / 100
                    lblspeedkmph.text = Math.round(positionSource.position.speed * 360) / 100
                } else {
                    lblalt.text = "[2D fix]"
                    lblspeed.text = ""
                }
                if (positionSource.position.hasOwnProperty('timestamp')) {
                    // do something with positionSource.position.timestamp
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
        }

        Flickable {
            id: flickable
            width: parent.width
            anchors.top: titlebar.bottom
            height: mainPage.height - titlebar.height
            contentWidth: parent.width
            contentHeight: current.height + 20
            clip: true

            Column {
                id: current
                width: parent.width
                anchors {
                    left: parent.left
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 10
                    top: parent.top
                }

                spacing: 10

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
                        id: lblspeedmps
                        // font.family: "Courier New"
                        font.pixelSize: 22
                    }
                    Text {
                        text: "m/s  "
                        font.pixelSize: 22
                    }
                    Text {
                        id: lblspeedkmph
                        // font.family: "Courier New"
                        font.pixelSize: 22
                    }
                    Text {
                        text: "km/h"
                        font.pixelSize: 22
                    }
                }

                Row {
                    id: rowbigspeed
                    anchors {
                        right: parent.right
                        rightMargin: 20
                        bottom: rowspeed.bottom
                        bottomMargin: 0
                    }
                    Text {
                        id: lblbigspeed
                        font.pixelSize: 80
                        font.family: "Courier New"
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
                        anchors {
                            rightMargin: 20
                        }
                    }
                    Text {
                        id: lblrecording
                        font.bold: true
                        font.pixelSize: 22
                        verticalAlignment: Text.AlignVCenter
                        height: 50
                        visible: false
                        anchors {
                            rightMargin: 20
                        }
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
                        anchors {
                            left: parent.left
                        }
                    }
                    Button {
                        id: binterval
                        text: dialoginterval.model.get(1).name;
                        font.bold: true;
                        font.pixelSize: 26
                        width: bstart.width
                        onClicked: {
                            dialoginterval.open();
                        }
                        anchors {
                            left: undefined
                            right: parent.right
                            rightMargin: 20
                        }
                    }

                }

                Row {
                    id:rowbuttons
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
                        width: (parent.width - 5*2 - 20) / 3
                        onClicked: {
                            // console.log("start")
                            var r = app.start(txtfilename.text, timerrecord.interval)
                            if(r != "") { //ok
                                bstart.enabled = false
                                bstop.enabled = true
                                bpause.text = "Pause"
                                bpause.enabled = true
                                rowwaypoint_1.enabled = true
                                rowwaypoint_2.enabled = true
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
                        width: (parent.width - 5*2 - 20) / 3
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
                        width: (parent.width - 5*2 - 20) / 3
                        enabled: false
                        onClicked: {
                            if(bpause.text == "Pause") {
                                app.pause()
                                bpause.text = "Resume"
                            } else {
                                app.resume()
                                bpause.text = "Pause"
                            }
                        }
                    }

                }

                Row {
                    id: rowwaypoint_1
                    enabled: false
                    anchors {
                        top: rowbuttons.bottom
                        topMargin: 6
                        left: parent.left
                        right: parent.horizontalCenter
                    }
                    Button {
                        id: bwpt_1
                        text: "bridge"
                        font.bold: true;
                        font.pixelSize: 26
                        width: (parent.width - 32) / 3
                        onClicked: {
                            app.add_waypoint(positionSource.position.coordinate.longitude,
		                             positionSource.position.coordinate.latitude,
                                             positionSource.position.coordinate.altitude,
                                             positionSource.position.speed,
                                             text)
                         }
                     }
                    Button {
                        id: bwpt_2
                        text: "ford"
                        font.bold: true;
                        font.pixelSize: 26
                        width: (parent.width - 32) / 3
                        anchors {
                            left: bwpt_1.right
                            leftMargin: 6
                        }
                        onClicked: {
                            app.add_waypoint(positionSource.position.coordinate.longitude,
		                             positionSource.position.coordinate.latitude,
                                             positionSource.position.coordinate.altitude,
                                             positionSource.position.speed,
                                             text)
                        }
                    }
                    Button {
                        id: bwpt_3
                        text: "culvert"
                        font.bold: true;
                        font.pixelSize: 26
                        width: (parent.width - 32) / 3
                        anchors {
                            left: bwpt_2.right
                            leftMargin: 6
                        }
                        onClicked: {
                            app.add_waypoint(positionSource.position.coordinate.longitude,
		                             positionSource.position.coordinate.latitude,
                                             positionSource.position.coordinate.altitude,
                                             positionSource.position.speed,
                                             text)
                        }
                    }
                }

                Row {
                    id: rowwaypoint_2
                    enabled: false
                    anchors {
                        top: rowbuttons.bottom
                        topMargin: 6
                        right: parent.right
                    }
                    Button {
                        id: bwpt_6
                        text: "0"
                        font.bold: true;
                        font.pixelSize: 26
                        width: (parent.width - 32) / 3
                        anchors {
                            right: parent.right
                            rightMargin: 20
                        }
                        onClicked: {
                            text = (Number(text) + 1).toString()
                            app.add_waypoint(positionSource.position.coordinate.longitude,
		                             positionSource.position.coordinate.latitude,
                                             positionSource.position.coordinate.altitude,
                                             positionSource.position.speed,
                                             text)
                         }
                     }
                    Button {
                        id: bwpt_5
                        text: "hospital"
                        font.bold: true;
                        font.pixelSize: 26
                        width: (parent.width - 32) / 3
                        anchors {
                            right: bwpt_6.left
                            rightMargin: 6
                        }
                        onClicked: {
                            app.add_waypoint(positionSource.position.coordinate.longitude,
		                             positionSource.position.coordinate.latitude,
                                             positionSource.position.coordinate.altitude,
                                             positionSource.position.speed,
                                             text)
                        }
                    }
                    Button {
                        id: bwpt_4
                        text: "school"
                        font.bold: true;
                        font.pixelSize: 26
                        width: (parent.width - 32) / 3
                        anchors {
                            right: bwpt_5.left
                            rightMargin: 6
                        }
                        onClicked: {
                            app.add_waypoint(positionSource.position.coordinate.longitude,
		                             positionSource.position.coordinate.latitude,
                                             positionSource.position.coordinate.altitude,
                                             positionSource.position.speed,
                                             text)
                        }
                    }
                 }

                Row {
                    id: rowsamples
                    anchors {
                        top: rowwaypoint_2.bottom
                        topMargin: 6
                    }
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
            rowwaypoint_1.enabled = false
            rowwaypoint_2.enabled = false
            txtfilename.enabled = true
            binterval.enabled = true
            txtfilename.visible = true
            lblrecording.visible = false
            app.stop()
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
