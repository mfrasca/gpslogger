import QtQuick 1.0
import com.nokia.meego 1.0
import QtMobility.location 1.1


Page {

    property double meter_per_pixel: 0


    function centermyposition() { // sets my position, but only once (do not update automatically)
        var coord = Qt.createQmlObject('import QtMobility.location 1.1; ' +
                                       'Coordinate {' +
                                       '  latitude:' + positionSource.position.coordinate.latitude + ';' +
                                       '  longitude:' + positionSource.position.coordinate.longitude + ';' +
                                       '}',
                                       positionSource, "coord");
        map.center = coord;
        myMapRoot.updateViewport()
    }

    function add_point(pos) {
        polyline.addCoordinate(pos)
        myMapRoot.updateViewport()
    }

    function remove_all_point() {
        while(polyline.path.length > 0) { // dirty workaround
            console.log(polyline.path.length)
            for (var index = 0; index < polyline.path.length; index++) {
                polyline.removeCoordinate(polyline.path[0])
            }
            console.log("Polyline cleared", polyline.path.length)
        }
        myMapRoot.updateViewport()
    }

    function setmapplugin() {
        map.plugin= mapplugin
        centermyposition()
    }


    // *******************************************************

    id: mapPage
    tools: toolbar

    Item {
        id: page
        width: parent.width
        height: parent.height

        /*
        Plugin {
            id: mapplugin
            name: "osm"
            PluginParameter { name: "osm.useragent"; value: "ghini.tour" }
            PluginParameter { name: "osm.mapping.host"; value: "http://c.tile.openstreetmap.org/" }
            PluginParameter { name: "osm.mapping.copyright"; value: "(c)" }
        }
        Plugin {
                  id: mapplugin
                  name: "nokia"
                  PluginParameter { name: "app_id"; value: "7FyznCdyZb5pU0pzECvK" } // https://api.developer.nokia.com/ovi-api/ui/registration?action=list
                  PluginParameter { name: "token"; value: "KVFpgX3oovrK7-VvV0g6OA" }
                }
        */

        Item {
            id: myMapRoot

            width: parent.width

            property Component itemMapDelegate
            property variant itemsModel
            signal viewportChanged(variant from, variant to)
            anchors.fill: parent
            anchors.top: parent.top
            onOpacityChanged: {
                if (opacity == 1) {
                    updateViewport();
                }
            }
            function updateViewport() {
                var coord1, coord2, dist
                viewportChanged(
                            map.toCoordinate(Qt.point(-map.anchors.leftMargin,-map.anchors.topMargin)),
                            map.toCoordinate(Qt.point(map.size.width + map.anchors.rightMargin,
                                                      map.size.height + map.anchors.bottomMargin)))

                // calculate meter per pixel (very ugly!)
                coord1 = map.toCoordinate(Qt.point(-map.anchors.leftMargin,-map.anchors.topMargin))
                coord2 = map.toCoordinate(Qt.point(map.size.width + map.anchors.rightMargin,-map.anchors.topMargin))
                dist = Math.round(coord1.distanceTo(coord2))
                console.log(dist, dist/map.size.width)
                meter_per_pixel = dist/map.size.width
                // myPosition.radius = meter_per_pixel*20
            }

            Map {
                id: map
                anchors.fill: parent
                anchors.top: parent.top
                anchors.margins: -80
                zoomLevel: 16

                plugin: Plugin {
                    name: "nokia"
                }
                // center: positionSource.position.coordinate

                onZoomLevelChanged: {
                    myMapRoot.updateViewport()
                    console.log("New zoomlevel:", zoomLevel)

                }
                onCenterChanged: {
                    var tmp = pinpointView.model
                    pinpointView.model = null
                    pinpointView.model = tmp
                }
                onSizeChanged: {
                    var tmp = pinpointView.model
                    pinpointView.model = null
                    pinpointView.model = tmp
                }

                MapCircle {
                    id: myPosition
                    color: "green"
                    radius: meter_per_pixel*15
                    center: positionSource.position.coordinate
                    z: 100
                }
                /*Landmark {
                    id: myLandmark
                    name: "my Position"
                    // iconSource: "../img/icon_80.png"
                    iconSource: "toolbar-back"
                    coordinate: positionSource.position.coordinate
                    radius: meter_per_pixel*15
                }*/

                MapPolyline {
                    id: polyline
                    border {color: "red"; width: 2}
                    z: 50
                }
            }



            Flickable {
                id: flickable
                anchors.fill: parent
                contentWidth: 8000
                contentHeight: 8000

                Component.onCompleted: setCenter()
                onMovementEnded: {
                    setCenter()
                    myMapRoot.updateViewport()
                }
                function setCenter() {
                    lock = true
                    contentX = contentWidth / 2
                    contentY = contentHeight / 2
                    lock = false
                    prevX = contentX
                    prevY = contentY
                }

                onContentXChanged: panMap()
                onContentYChanged: panMap()
                property double prevX: 0
                property double prevY: 0
                property bool lock: false
                function panMap() {
                    if (lock) return
                    map.pan(contentX - prevX, contentY - prevY)
                    prevX = contentX
                    prevY = contentY
                }
            }
            Item {
                id: pinpointViewContainer
                Repeater {
                    id: pinpointView
                    model: itemsModel
                    delegate: itemMapDelegate
                }
            }
        }

    }

    // *******************************************************



    ToolBarLayout {
        id: toolbar

        ToolIcon {
            iconId: "toolbar-back"
            onClicked: {
                pageStack.pop()
            }
        }

        ToolButtonRow {
            ToolButton {
                id: bzoomin
                text: "+"
                font.bold: true;
                font.pixelSize: 30
                width: 100
                onClicked: {
                    map.zoomLevel += 1
                    if(map.zoomLevel >= map.maximumZoomLevel) { bzoomin.enabled = false}
                    bzoomout.enabled = true
                }
            }
            ToolButton {
                id: bzoomout
                text: "-"
                font.bold: true;
                font.pixelSize: 30
                width: 100
                onClicked: {
                    map.zoomLevel -= 1
                    if(map.zoomLevel <= map.minimumZoomLevel) { bzoomout.enabled = false}
                    bzoomin.enabled = true
                }
            }
            ToolButton {
                id: bgotomyposition
                // text: "o"
                iconSource: "../img/gps_small.png"
                width: 100
                onClicked: {
                    centermyposition()
                }
            }
        }
        
        ToolIcon {
            iconId: "toolbar-view-menu" ;
            onClicked: myMenu.open();
        }
    }


    // *******************************************************
    // *******************************************************
    //      Component.onCompleted: {
    //          // map.size.width = page.width - 20
    //          // map.size.height = map.size.width // 500 // page.height - 20
    //          console.log("MapPage loaded")
    //          centermyposition()
    //      }
    // *******************************************************

}
