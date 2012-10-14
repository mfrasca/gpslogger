import QtQuick 1.0
import com.nokia.meego 1.0
import QtMobility.location 1.1

import "." as MyComponents



Page {
//   orientationLock: PageOrientation.LockLandscape
//     orientationLock: PageOrientation.LockPortrait
    

    
    
    
    //We want to tell Python whenever our display orientation changes
    //This is done with the signal "onWidthChanged".
    //This how ever is not called at start up, because of that we also use a sigle shot timer
    onWidthChanged: {
      displayOrientationChanged()
    }

    Timer {
	interval: 1; running: true; repeat: false
	onTriggered: {
	  displayOrientationChanged()    
	}
    }
    
    //Tell Python that the display orientation changed
    function displayOrientationChanged(){
	if (width > 600) { // landscape			
	    console.log("[QML INFO] Landscape")
	} 
	else { // portrait		
	    console.log("[QML INFO] Portrait")
	}	
    }
    
    Timer {
	id: timerrecord
	interval: 1000; running: true; repeat: true
	onTriggered: {
	  sendGPSdata()    
	}
    }
    
    function sendGPSdata(){	
	if(bstart.enabled == false){ //recording
	    points = points + 1
	    lblsamples.text = "recorded " + points + " samples"
	    qml_to_python.add_point(positionSource.position.coordinate.longitude, positionSource.position.coordinate.latitude, positionSource.position.coordinate.altitude, positionSource.position.speed)
	    
	    mapPage.add_point(positionSource.position.coordinate)
	}
	else{
// 	  console.log("-", timerrecord.interval)
	}
    }
    
    
    function convertDecDeg(v,tipo) {
	if (!tipo) tipo='N';
	    var deg;
	    deg = v;
	    if (!deg){
	    return "";
	} else if (deg > 180 || deg < 0){
	    // convert coordinate from north to south or east to west if wrong tipo
	    return convertDecDeg(-v,(tipo=='N'?'S': (tipo=='E'?'W':tipo) ));
	} else {
	    var gpsdeg = parseInt(deg);
	    var remainder = deg - (gpsdeg * 1.0);
	    var gpsmin = remainder * 60.0;
	    var D = gpsdeg;
	    var M = parseInt(gpsmin);
	    var remainder2 = gpsmin - (parseInt(gpsmin)*1.0);
	    var S = parseInt(remainder2*60.0);
	    return tipo + " " + D + "° " +  Math.round(gpsmin * 1000) / 1000
	}
    }
    
    
    property int points: 0
    property int waypoint: 0
    
//     property variant mapPage: ""
    
    
//*******************************************************
    
    
    id: mainPage
    tools: toolbar

//     anchors.margins: 10
    
    
    Item{
	id: page
	width: parent.width   
	  
	PositionSource {
	    id: positionSource
	    updateInterval: 1000
	    active: true
	    // nmeaSource: "nmealog.txt"
	    onPositionChanged:{
	      
	      if(positionSource.position.longitudeValid){
		lbllon.text = convertDecDeg(positionSource.position.coordinate.longitude, "E")
	      }
	      else{
		lbllon.text = "-"
	      }
	      
	      if(positionSource.position.latitudeValid){
		lbllat.text = convertDecDeg(positionSource.position.coordinate.latitude, "N")
	      }
	      else{
		lbllat.text = "-"
	      }
	      
	      if(positionSource.position.altitudeValid){
		lblalt.text = Math.round(positionSource.position.coordinate.altitude) + " m"
	      }
	      else{
		//lblalt.text = "-"
	      }
	      
	      if(positionSource.position.speedValid){
		lblspeed.text = Math.round(positionSource.position.speed * 100) / 100 + " m/s (" +  Math.round(positionSource.position.speed * 360) / 100 + " km/h)"
	      }
	      else{
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
		color: "green";
	    }
	    //Row{
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
	    
	    Column{
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
		    Text{	
			text: "Current position data"
			font.bold: true;
			font.pixelSize: 26
			verticalAlignment: Text.AlignVCenter
		    }
			  
			
		    
		    Row{
			Text{	
			    text: "Longitude: "
			    font.pixelSize: 22
			}					    
			Text {         
			    id: lbllon
			    //text: positionSource.position.coordinate.longitude
			    font.pixelSize: 22
			}	
		    }
		    
		    Row{
			Text{	
			    text: "Latitude: "
			    font.pixelSize: 22
			}					    
			Text {         
			    id: lbllat
			    //text: positionSource.position.coordinate.latitude
			    font.pixelSize: 22
			}	
		    }   
		    
		    Row{
			Text{	
			    text: "Altitude: "
			    font.pixelSize: 22
			}					    
			Text {         
			    id: lblalt
// 			    text: positionSource.position.coordinate.altitude
			    font.pixelSize: 22
			}	
		    }
		    
		    Row{
			Text{	
			    text: "Speed: "
			    font.pixelSize: 22
			}					    
			Text {         
			    id: lblspeed
// 			    text: positionSource.position.speed
			    font.pixelSize: 22
			}	
		    }
		    
		    /*Row{
			Text{	
			    text: "Time: "
			    font.pixelSize: 22
			}					    
			Text {         
			    id: lbltime
			    text: positionSource.position.timestamp
			    font.pixelSize: 22
			}	
		    }*/
		    
		      
			
		    
		}
		
		Column {
		    width: parent.width
		    spacing: 20  
			  			  
		    Rectangle{
			id: separator
			height: 1
			width: parent.width - 20
			color: "green"
		    }
			  
		    Row{
			id: record
			Text{	
			    text: "Record"
			    font.bold: true;
			    font.pixelSize: 26
			    verticalAlignment: Text.AlignVCenter
			}
		    } 
		        
		    
		    Row{
			id:name
			width: parent.width
			Text{
			    id: lblname2
			    text: "Name: "
			    font.bold: true;
			    font.pixelSize: 22
			    verticalAlignment: Text.AlignVCenter
			    height: txtname.height
			}					    
			TextField {         
			    id: txtname
// 			    validator: IntValidator{bottom: 1; top: 31;}
// 			    inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
			    height: 50			    
			    width: parent.width - lblname2.width - 20
			}
			Text{
			    id: lblname
			    font.bold: true;
			    font.pixelSize: 22
			    verticalAlignment: Text.AlignVCenter
			    height: 50			    
			    width: parent.width - lblname2.width - 20
			    visible: false
			}
		    }
		    
		    Row{
			id:interval
			width: parent.width
			Text{	
			    id: lblinterval
			    text: "Interval: "
			    font.bold: true;
			    font.pixelSize: 22
			    verticalAlignment: Text.AlignVCenter
			    height: binterval.height
			}			
			
			/*Text { 
			    id: txtinterval
			    text: binterval.text 
			    font.bold: true;
			    font.pixelSize: 22
			    verticalAlignment: Text.AlignVCenter
			    height: slinterval.height	  
			}*/

			/*Slider {
			    id: slinterval
			    objectName: 'slinterval'
			    valueIndicatorVisible: true
			    minimumValue: 1
			    maximumValue: 600
			    stepSize:  1
			    value: 1
			    width: parent.width - lblinterval.width - txtinterval.width - 10
			}*/
			Button{	
			    id: binterval
			    text: "1 second"
			    font.bold: true;
			    font.pixelSize: 26
			    width: parent.width - lblinterval.width - 20
			    onClicked: {
			      dialoginterval.open();
			    }
			}
			
		    }
		    
		    Row{
			id:buttons
			width: parent.width
			Button{	
			    id: bstart
			    text: "Start"
			    font.bold: true;
			    font.pixelSize: 26
			    width: parent.width / 2 - 12
			    onClicked: {
// 				console.log("start")
				var r = qml_to_python.start(txtname.text, timerrecord.interval)				
				if(r != ""){ //ok
				  bstart.enabled = false
				  bstop.enabled = true
// 				  bwaypoint.enabled = true
				  txtname.enabled = false
				  binterval.enabled = false
				  //timerrecord.interval = slinterval.value * 1000
				  txtname.visible = false
				  lblname.visible = true
				  lblname.text = r
				  lblsamples.text = ""
				  points = 0
				  waypoint = 0
				  mapPage.remove_all_point()
				}
				else{ //failed
				  console.log("start failed")
				  //ToDo: show error
				}
			    }
			}
			Label {width:  5; height: 1} //spacer
			
			Button{	
			    id: bstop
			    text: "Stop"
			    font.bold: true;
			    font.pixelSize: 26
			    width: parent.width / 2 - 12
			    enabled: false
			    onClicked: {
			      dialogstop.open();
			    }
			}			
			
		    }
		    
// 		    Row{
// 			width: parent.width
// 			Button{	
// 			    id: bwaypoint
// 			    text: "Add waypoint"
// 			    font.bold: true;
// 			    font.pixelSize: 26
// 			    width: parent.width -20
// 			    enabled: false
// 			    onClicked: {
// 			      waypoint = waypoint + 1
// 			      bwaypoint = " Add waypoint (" + waypoint + ")"
// 			      qml_to_python.addwaypoint(positionSource.position.coordinate.longitude, positionSource.position.coordinate.latitude, positionSource.position.coordinate.altitude, positionSource.position.speed, waypoint)
// 			    }
// 			}		 
// 		    }
		    
		    Row{
			width: parent.width
			Text{	
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
        message: "Do you really want to stop reccording?"
	acceptButtonText: "Yes"
	rejectButtonText : "No"
	onAccepted: { 
	  //console.log("stop")
	  bstart.enabled = true
	  bstop.enabled = false
// 	  bwaypoint.enabled = false
	  txtname.enabled = true
	  binterval.enabled = true
	  txtname.visible = true
	  lblname.visible = false
	  qml_to_python.stop()
	}
    }

//*******************************************************


    SelectionDialog {
        id: dialoginterval
        titleText: "Recording interval"

        model: ListModel {
//             ListElement { name: "100 milliseconds"; value: 100 }
            ListElement { name: "1 second";   value:   1000 }
            ListElement { name: "10 seconds"; value:  10000 }
            ListElement { name: "15 seconds"; value:  15000 }
            ListElement { name: "20 seconds"; value:  20000 }
            ListElement { name: "30 seconds"; value:  30000 }
            ListElement { name: "1 minute";   value:  60000 }
            ListElement { name: "2 minute";   value: 120000 }
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
// 		    MyComponents.MapPage.id = "mapPage"
                    pageStack.push(mapPage)
		    mapPage.setmapplugin()
		    mapPage.centermyposition()
// 		    pageStack.push(Qt.resolvedUrl("MapPage.qml"))


//  var coord = Qt.createQmlObject()
   
   
// 		    pageLoader.source = "MapPage.qml"
// 		    pageStack.push(pageLoader)

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










