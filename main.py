#!/usr/bin/python
################################################################################
# Copyright (c) by George Ruinelli (2012)
# License:     GPL3
# Modified by Hiroshi Miura, 2013
# Modified by Mario Frasca, 2018
################################################################################


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
import logging
logger = logging.getLogger(__name__)


################################################################################
class GPSLoggerApp(QApplication):
    root = "/opt/gps-logger/"
    filehandle = None
    recording = False
    path = "/home/user/MyDocs/GPS-Logger"
    version = "??"
    build = "?"

    def __init__(self, argv):
        super(GPSLoggerApp, self).__init__(argv)
        
        if(platform.machine().startswith('arm')):
            pass
        else:
            self.root = "./"
            self.path = "./data/"
        try:
            os.makedirs(self.path)
        except:
            pass
        
        try:
            with open(os.path.join(self.root, "version"), 'r') as file:
                self.version = file.readline().strip()
                self.build = file.readline().strip()
                logger.info("Version: %s-%s" % (self.version, self.build))
        except:
            logger.error("Version file not found, please check your installation!")

        self.config = Configuration()
        self.gpx = GPX()

    def finished(self):
        self.config.write()
        if(self.gpx.recording == True):
            logger.info("we are still recording, close file properly")
            self.gpx.stop_recording()
        logger.debug("Closed")

    def does_opt_in(self):
        logger.info("config.opt_in:", self.config.opt_in)
        return self.config.opt_in

    @Slot(str, int, result=str)
    def start(self, filename, interval):
        return self.gpx.start_recording(self.path, filename, interval)

    @Slot()
    def stop(self):
        logger.debug("stop")
        self.gpx.stop_recording()

    @Slot()
    def pause(self):
        self.gpx.paused = True

    @Slot()
    def resume(self):
        self.gpx.start_new_segment()
        self.gpx.paused = False

    @Slot(float, float, float, float)
    def add_point(self, lon, lat, alt, speed):
        logger.debug("recording point - lon:%s lat:%s alt:%s speed:%s time:%s" % (lon, lat, alt, speed, time))
        self.gpx.add_entry(lon, lat, alt, speed)

    @Slot(float, float, float, float, str)
    def add_waypoint(self, lon, lat, alt, speed, waypoint):
        logger.debug("recording waypoint - lon:%s lat:%s alt:%s speed:%s time:%s" % (lon, lat, alt, speed, time))
        self.gpx.add_waypoint(lon, lat, alt, speed, waypoint)

    @Slot(result=str)
    def get_version(self):
        return str(self.version) + "-" + str(self.build)

    @Slot(bool)
    def Opt_In(self, v):
        self.opt_in = v
        if(v is False):
            config.write()
            logger.warn("We have to quit now, so sorry")
            quit()


################################################################################
class Configuration():
    configpath = ""
    configfile = "config.conf"
    opt_in = False

    def __init__(self):
        self.configpath = os.path.join(QDS.storageLocation(QDS.DataLocation), "GPS-Logger")
        self.configfile = self.configpath + "/" + self.configfile

        logger.debug("Loading configuration from: %s" % self.configfile)
        self.ConfigParser = ConfigParser.SafeConfigParser()
        try:
            self.ConfigParser.read(self.configfile)
        except:  # use default config
            logger.warn("Configuration file %s not existing or not compatible" % self.configfile)
        try:
            self.ConfigParser.add_section('main')
        except:
            pass

        try:
            self.opt_in = self.ConfigParser.getboolean("main", "opt_in")
            logger.debug("Configuration loaded")
        except:
            logger.error("Error loading configuration, using default value")

    def write(self):
        logger.debug("Write configuration to: %s" % self.configfile)
        self.ConfigParser.set('main', 'opt_in', str(self.opt_in))

        try:
            os.makedirs(self.configpath)
        except:
            pass

        try:
            with open(self.configfile, 'w') as handle:
                self.ConfigParser.write(handle)
            logger.debug("Configuration saved")
        except:
            logger.error("Failed to write configuration file!")


################################################################################
class GPX():
    filehandle = None
    recording = False
    waypoints = []
    paused = False

    def start_recording(self, datapath, filename, interval):
        if(filename == ""):
            filename = "track"

        suffix = 1
        filename2 = filename + ".gpx"  # try first without a numeric suffix
        full_filename = datapath + "/" + filename2

        if(os.path.exists(full_filename)):
            while(os.path.exists(full_filename)):
                filename2 = "%s_%04d.gpx" % (filename, suffix)
                full_filename = datapath + "/" + filename2
                suffix = suffix + 1

        logger.info("Start recording %s %s" % (full_filename, interval))
        try:
            self.filehandle = open(full_filename, 'w')
            self.recording = True

            self.filehandle.write("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n")
            txt = '''\
<gpx xmlns="http://www.topografix.com/GPX/1/1"
     xmlns:xsd="http://www.w3.org/2001/XMLSchema"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     creator="N9 GPS Logger"
     version="1.1"
     xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">'''
            self.filehandle.write(txt)
            txt = '''
  <metadata>
    <link href="http://github.com/mfrasca/gpslogger">
      <text>N9 GPS Logger</text>
    </link>
  </metadata>'''
            self.filehandle.write(txt)
            txt = '''
  <trk>
    <name>%s</name>
    <trkseg>''' % filename
            self.filehandle.write(txt)

            return filename2

        except:
            logger.error("failed to open file: %s" % full_filename)
            return ""

    def start_new_segment(self):
        if(self.recording is True):
            txt = '''
    </trkseg>
    <trkseg>'''
            self.filehandle.write(txt)
        else:
            logger.error("file closed, can not write to it")

    def add_entry(self, lon, lat, alt, speed):
        if(self.recording is True):
            if self.paused:
                return
            logger.debug("adding entry")

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
        <time>%(time)s</time>
        <desc>Lat.=%(lat)s, Long.=%(lon)s, Alt.=%(ele)sm, Speed=%(speed)sKm/h</desc>
      </trkpt>''' % {'lat': lat, 'lon': lon, 'ele': alt, 'time': t, 'speed': s}

            self.filehandle.write(txt)
        else:
            logger.warn("file closed, can not add entry")

    def add_waypoint(self, lon, lat, alt, speed, waypoint):
        if(self.recording is True):
            t = "%d-%02d-%02dT%02d:%02d:%02dZ" % datetime.utcnow().timetuple()[:6]
            self.waypoints.append({'lat': lat, 'lon': lon, 'ele': alt, 'time': t, 'name': waypoint})
        else:
            logger.warn("file closed, can not add entry")

    def stop_recording(self):
        logger.debug("Stop recording")
        if(self.recording is True):
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
            waypoints_xml = ''.join(waypoint_format % item for item in self.waypoints)
            self.filehandle.write(txt % waypoints_xml)
            self.waypoints = []

        try:
            self.filehandle.close()
            self.recording = False
        except:
            pass


################################################################################
if __name__ == '__main__':
    gpslogger = GPSLoggerApp(sys.argv)
    logging.basicConfig(stream=sys.stderr, level=logging.WARNING)

    view = QDeclarativeView()
    context = view.rootContext()
    context.setContextProperty("app", gpslogger)
    view.setSource(QUrl.fromLocalFile(gpslogger.root + 'qml/main.qml'))

    if(platform.machine().startswith('arm')):
        view.showFullScreen()
        view.show()
        if(gpslogger.does_opt_in() is False):
            root = view.rootObject()
            root.show_Opt_In()

    gpslogger.exec_()  # endless loop
    gpslogger.finished()
