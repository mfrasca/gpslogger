import QtQuick 1.0
import com.nokia.meego 1.0
import QtMobility.location 1.1



Page {
  property double meter_per_pixel: 0

  function centermyposition(){ //sets my position, but only once (do not update automatically)
      var coord = Qt.createQmlObject('import QtMobility.location 1.1; Coordinate{latitude:' + positionSource.position.coordinate.latitude + ';longitude:' + positionSource.position.coordinate.longitude + ';}', positionSource, "coord");
      map.center = coord;
      myMapRoot.updateViewport()
  }
  
  function add_point(pos){
      polyline.addCoordinate(pos)
      myMapRoot.updateViewport()
  }
  
  function remove_all_point(){
    while(polyline.path.length > 0){ //dirty workaround
      console.log(polyline.path.length)
	for (var index = 0; index < polyline.path.length; index++)  {
	  polyline.removeCoordinate(polyline.path[0])
      }
      console.log("Polyline cleared", polyline.path.length)
    }
    myMapRoot.updateViewport()
  }
  
  function setmapplugin(){
      map.plugin= mapplugin 
      centermyposition()
  }
  
  
//*******************************************************
    
    id: mapPage
    tools: toolbar

    Item{
	id: page
	width: parent.width 
	height: parent.height   
	
    Plugin {
    id: mapplugin
    name: "openstreetmap"
    parameters: [
          PluginParameter {name: "mapping.servers";
             value: ["http://a.tile.cloudmade.com/f3f2cbe6a0c34bf8981a5be8426333a8/74884/256/",
                 "http://b.tile.cloudmade.com/f3f2cbe6a0c34bf8981a5be8426333a8/74884/256/",
                 "http://c.tile.cloudmade.com/f3f2cbe6a0c34bf8981a5be8426333a8/74884/256/"
              ]
          },
          PluginParameter {name: "mapping.cache.directory"
                  value: "/home/user/MyDocs/.maps/GPS-Logger/"
          },
          PluginParameter {name: "mapping.cache.size"
                  value: 2147483648
          }
       ]
    }

	Item {
	    id: myMapRoot
	    
	    width: parent.width

	    property Component itemMapDelegate
	    property variant itemsModel
	    signal viewportChanged(variant from, variant to)
	    anchors.fill: parent
	    anchors.top: titlebar.bottom
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
		
		//calculate meter per pixel (very ugly!)
		coord1 = map.toCoordinate(Qt.point(-map.anchors.leftMargin,-map.anchors.topMargin))
		coord2 = map.toCoordinate(Qt.point(map.size.width + map.anchors.rightMargin,-map.anchors.topMargin))
		dist = Math.round(coord1.distanceTo(coord2))
		console.log(dist, dist/map.size.width)
		meter_per_pixel = dist/map.size.width
	    }

	    Map {
		id: map
 		anchors.fill: parent
		anchors.top: titlebar.bottom
		anchors.margins: -80
		zoomLevel: 16

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

//*******************************************************

    ToolBarLayout {
	id: toolbar
	
	ToolIcon { iconId: "toolbar-back"; onClicked: { pageStack.pop();   } }	
	
	ToolButtonRow { 
	  ToolButton {
                id: bzoomin
                text: "+"
		font.bold: true;
		font.pixelSize: 30
		width: 100
                onClicked: {
		  map.zoomLevel += 1
		  if(map.zoomLevel >= map.maximumZoomLevel){ bzoomin.enabled = false}
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
		  if(map.zoomLevel <= map.minimumZoomLevel){ bzoomout.enabled = false}
		  bzoomin.enabled = true
                }
            }	 
	  ToolButton {
                id: bgotomyposition
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
}
