#!/usr/bin/python
##############################################################################################
# Copyright (c) by George Ruinelli (2012)
# License:     GPL3
# later modified by Mario Frasca
##############################################################################################


import sys
from PySide.QtCore import *
from PySide.QtGui import *
from PySide.QtDeclarative import *
from PySide.QtGui import QDesktopServices as QDS

# import math
import platform
import time
import datetime
import os
import string
import ConfigParser
# import gconf


from datetime import tzinfo, timedelta, datetime


class Data():
    root = "/opt/gps-logger/"
    filehandle = None
    recording = False
    paused = False
    path = "/home/user/MyDocs/GPS-Logger"
    version = "??"
    build = "?"
    configpath = ""
    configfile = "config.conf"
    opt_in = False
    waypoints = []


####################################################################################################
class Configuration():
    def __init__(self):
        data.configpath = os.path.join(QDS.storageLocation(QDS.DataLocation), "GPS-Logger")
        data.configfile = data.configpath + "/" + data.configfile

    def Load(self):
        print "Loading configuration from:", data.configfile
        self.ConfigParser = ConfigParser.SafeConfigParser()
        try:
            self.ConfigParser.read(data.configfile)
        except:  # use default config
            print "Configuration file " + data.configfile + " not existing or not compatible"

        try:
            self.ConfigParser.add_section('main')
        except:
            pass

        try:
            data.opt_in = self.ConfigParser.getboolean("main", "opt_in")
            print "Configuration loaded"
        except:
            print "Error loading configuration, using default value"

    def Write(self):
        print "Write configuration to:", data.configfile
        # self.ConfigParser.add_section('main')
        self.ConfigParser.set('main', 'opt_in', str(data.opt_in))

        try:
            os.makedirs(data.configpath)
        except:
            pass

        try:
            handle = open(data.configfile, 'w')
            self.ConfigParser.write(handle)
            handle.close()
            print "Configuration saved"
        except:
            print "Failed to write configuration file!"


################################################################################################


class QML_to_Python_Interface(QObject):
    global data

    @Slot(str, int, result=str)
    def start(self, filename, interval):
        return start_recording(filename, interval)

    @Slot()
    def stop(self):
        # print "stop"
        stop_recording()

    @Slot()
    def pause(self):
        data.paused = True

    @Slot()
    def resume(self):
        start_new_segment()
        data.paused = False

    @Slot(float, float, float, float)
    def add_point(self, lon, lat, alt, speed):
        # print "recording", lon, lat, alt, speed, time
        add_entry(lon, lat, alt, speed)

    @Slot(float, float, float, float, str)
    def add_waypoint(self, lon, lat, alt, speed, waypoint):
        # print "recording", lon, lat, alt, speed, time
        add_waypoint(lon, lat, alt, speed, waypoint)

    @Slot(result=str)
    def get_version(self):
        return str(data.version) + "-" + str(data.build)

    @Slot(bool)
    def Opt_In(self, v):
        data.opt_in = v
        if(v is False):
            config.Write()
            print "We have to quit now, sry"
            quit()


################################################################################################


def start_recording(filename, interval):
    global data
    if(filename == ""):
        filename = "track"

    suffix = 1
    filename2 = filename + ".gpx"  # try first without a numeric suffix
    full_filename = data.path + "/" + filename2

    if(os.path.exists(full_filename)):
        while(os.path.exists(full_filename)):
            filename2 = "%s_%04d.gpx" % (filename, suffix)
            full_filename = data.path + "/" + filename2
            suffix = suffix + 1

    print "Start recording", full_filename, interval
    try:
        data.filehandle = open(full_filename, 'w')
        data.recording = True

        data.filehandle.write("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n")
        txt = '''\
<gpx xmlns="http://www.topografix.com/GPX/1/1"
     xmlns:xsd="http://www.w3.org/2001/XMLSchema"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     creator="N9 GPS Logger"
     version="1.1"
     xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">'''
        data.filehandle.write(txt)
        txt = '''
  <metadata>
    <link href="http://github.com/mfrasca/gpslogger">
      <text>N9 GPS Logger</text>
    </link>
  </metadata>'''
        data.filehandle.write(txt)
        txt = '''
  <trk>
    <name>%s</name>
    <trkseg>''' % filename
        data.filehandle.write(txt)

        return filename2

    except:
        print "failed to open file:", full_filename
        return ""


def start_new_segment():
    global data
    if(data.recording is True):
        txt = '''
    </trkseg>
    <trkseg>'''
        data.filehandle.write(txt)
    else:
        print "file closed, can not write to it"
    
    
def add_entry(lon, lat, alt, speed):
    global data
    if(data.recording is True):
        if data.paused:
            return
        # print "adding entry"

        tt = datetime.utcnow().timetuple()  # time in UTC
        try:
            alt = str(int(alt))
        except:
            alt = "0"

        t = "%d-%02d-%02dT%02d:%02d:%02dZ" % tt[:6]
        s = speed * 3.6
        txt = '''
      <trkpt lat="%(lat)s" lon="%(lon)s">
        <ele>%(ele)s</ele>
        <time>%(ele)s</time>
        <desc>Lat.=%(lat)s, Long.=%(lon)s, Alt.=%(ele)sm, Speed=%(speed)sKm/h</desc>
      </trkpt>''' % {'lat': lat, 'lon': lon, 'ele': alt, 'time': t, 'speed': s}

        data.filehandle.write(txt)
    else:
        print "file closed, can not add entry"


def add_waypoint(lon, lat, alt, speed, waypoint):
    global data
    if(data.recording is True):
        t = "%d-%02d-%02dT%02d:%02d:%02dZ" % datetime.utcnow().timetuple()[:6]
        data.waypoints.append({'lat': lat, 'lon': lon, 'ele': alt, 'time': t, 'name': waypoint})
    else:
        print "file closed, can not add entry"


def stop_recording():
    global data
    print "Stop recording"
    if(data.recording is True):
        txt = '''
    </trkseg>
  </trk>%s
</gpx>
'''
        waypoint_format = '''
  <wpt lat="%(lat)s" lon="%(lon)s">
    <ele>%(ele)s</ele>
    <time>%(time)s</time>
    <name>%(name)s</name>
  </wpt>'''
        waypoints_xml = ''.join(waypoint_format % item for item in data.waypoints)
        data.filehandle.write(txt % waypoints_xml)
        data.waypoints = []

    try:
        data.filehandle.close()
        data.recording = False
    except:
        pass


if __name__ == '__main__':
    global data
    app = QApplication(sys.argv)

    data = Data()

    if(platform.machine().startswith('arm')):
        pass
    else:
        data.root = "./"
        data.path = "./data/"

    config = Configuration()
    config.Load()

    view = QDeclarativeView()
    view.setSource(QUrl.fromLocalFile(data.root + 'qml/main.qml'))
    root = view.rootObject()

    # Load version file
    try:
        file = open(data.root + "version", 'r')
        data.version = file.readline()
        data.version = data.version[:-1]
        data.build = file.readline()
        print "Version: " + str(data.version) + "-" + str(data.build)
    except:
        print "Version file not found, please check your installation!"

    # root.setQMLData(data.showHomeNetwork, data.useautoreset, data.resetday, data.usedifference, data.difference)

    try:
        os.makedirs(data.path)
    except:
        pass

    # Those lines has to be run AFTER the above root.-commands, else the dummy values in QML will overwrite our real values!
    # instantiate the Python object
    qml_to_python = QML_to_Python_Interface()
    # expose the object to QML
    context = view.rootContext()
    context.setContextProperty("qml_to_python", qml_to_python)

    if(platform.machine().startswith('arm')):
        view.showFullScreen()
    view.show()

    print "data.opt_in:", data.opt_in
    if(data.opt_in is False):
        root.show_Opt_In()

    app.exec_()  # endless loop

    config.Write()

    print "Closing"

    if(data.recording is True):
        print "we are still recording, close file properly"
        stop_recording()
