#!/usr/bin/env python
##############################################################################################
# Copyright (c) by George Ruinelli 
# License: 	GPL3
# Modified by Hiroshi Miura, 2013
##############################################################################################

import sys
from PySide.QtCore import *
from PySide.QtGui import *
from PySide.QtDeclarative import *
from PySide.QtGui import QDesktopServices as QDS

#import math
import platform
import time
import datetime
import os
import string
import ConfigParser
#import gconf

from datetime import tzinfo, timedelta, datetime
import logging

class Data():
  root = "/opt/gps-logger/"
  filehandle = None
  recording = False
  path = "/home/user/MyDocs/GPS-Logger"	
  version = "??"
  build = "?"
  configpath = ""
  configfile = "config.conf"
  opt_in = False
  waypoints = ""

################################################################################
class Configuration():
  def __init__(self):
    data.configpath = os.path.join(QDS.storageLocation(QDS.DataLocation), "GPS-Logger")
    data.configfile = data.configpath + "/" + data.configfile
  
  def Load(self):
    logging.info("Loading configuration from:", data.configfile)
    self.ConfigParser = ConfigParser.SafeConfigParser()
    try:
      self.ConfigParser.read(data.configfile)
    except: #use default config
      logging.warning("Configuration file "+ data.configfile + " not existing or not compatible")
    try:
      self.ConfigParser.add_section('main')
    except:
      pass
    try:
      data.opt_in = self.ConfigParser.getboolean("main", "opt_in")
      logging.info("Configuration loaded")
    except:
      logging.warning("Error loading configuration, using default value")
  
  def Write(self):
    logging.info("Write configuration to:", data.configfile)
    #self.ConfigParser.add_section('main')
    self.ConfigParser.set('main', 'opt_in', str(data.opt_in))
    try:
      os.makedirs(data.configpath)
    except:
      pass
    try:
      handle = open(data.configfile, 'w')
      self.ConfigParser.write(handle)
      handle.close()
      logging.info("Configuration saved")
    except:
      logging.warning("Failed to write configuration file!")

################################################################################
class QML_to_Python_Interface(QObject):
  global data

  @Slot(str, int, result=str)
  def start(self, filename, interval):
    return start_recording(filename, interval)

  @Slot()
  def stop(self):
    logging.debug("stop")
    stop_recording()
      
  @Slot(float, float, float, float)
  def add_point(self, lon, lat, alt, speed):
    logging.debug("recording", lon, lat, alt, speed, time)
    add_entry(lon, lat, alt, speed)
    
  @Slot(float, float, float, float, int)
  def add_waypoint(self, lon, lat, alt, speed, waypoint):
    logging.debug("recording", lon, lat, alt, speed, time)
    add_waypoint(lon, lat, alt, speed, waypoint)

  @Slot(result=str)
  def get_version(self):      
    return str(data.version) + "-" + str(data.build)

  @Slot(bool)
  def Opt_In(self, v):      
    data.opt_in = v
    if(v == False):
      config.Write()
      logging.info("We have to quit now, sry")
      quit()
	
################################################################################################  
def start_recording(filename, interval):
  global data
  if(filename == ""):
    filename = "track"
    
  suffix = 1
  filename2 = filename + ".gpx" #try first without a suffix
  full_filename = data.path + "/" + filename2

  if(os.path.exists(full_filename)):
    while(os.path.exists(full_filename)):
      filename2 = filename + "_" + str(suffix) + ".gpx"
      full_filename = data.path + "/" + filename2
      suffix = suffix + 1
  logging.info("Start recording", full_filename, interval)
  try:
    data.filehandle = open(full_filename, 'w')
    data.recording = True
    data.filehandle.write("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n")
    txt = '''\
<gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance" creator="N9 GPS Logger" version="1.1" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">\n'''
    data.filehandle.write(txt)
    txt = '''\
  <metadata>
    <link href="http://www.ruinelli.ch">
	<text>N9 GPS Logger</text>
    </link>
  </metadata>
  '''
    data.filehandle.write(txt)
    txt = "<trk>\n" + \
    "<name>" + str(filename) + "</name>\n" + \
    "		<trkseg>\n"
    data.filehandle.write(txt)
    data.waypoints = ""
    return filename2
  except:
    logging.warning("failed to open file:", full_filename)
    return ""

################################################################################################
def get_iso_datetime():
  tt = datetime.utcnow().timetuple() #time in UTC
  #add leading zeros
  if(int(tt[1])<10):
    mm = "0" + str(tt[1])
  else:
    mm = str(tt[1])
  if(int(tt[2])<10):
    d = "0" + str(tt[2])
  else:
    d = str(tt[2])
  if(int(tt[3])<10):
    h = "0" + str(tt[3])
  else:
    h = str(tt[3])
  if(int(tt[4])<10):
    m = "0" + str(tt[4])
  else:
    m = str(tt[4])
  if(int(tt[5])<10):
    s = "0" + str(tt[5])
  else:
    s = str(tt[5])
  t = str(tt[0]) + "-" + str(mm) + "-" + str(d) + "T" + str(h) + ":" + str(m) + ":" + str(s) + "Z" #2012-07-31T20:44:36Z
  return t

################################################################################################
def add_entry(lon, lat, alt, speed):
  global data
  if(data.recording == True):    
    logging.debug("adding entry")
    try:
      alt = str(int(alt))
    except:
      alt ="0"

    t = get_iso_datetime();
    s = speed * 3.6
    logging.debug("trk:%s,%f,%f,%f,%f", t, lat, lon, alt, s)
    txt = "		<trkpt lat=\"" + str(lat) + "\" lon=\"" + str(lon) + "\">\n" + \
    "			<ele>" + str(int(alt)) + "</ele>\n" + \
    "			<time>" + t + "</time>\n" + \
    "			<desc>Lat.=" + str(lat) + ", Long.=" + str(lon) + ", Alt.=" + str(alt) + "m, Speed=" + str(s) + "Km/h</desc>\n" + \
    "		</trkpt>\n"
    data.filehandle.write(txt)
  else:
    logging.warning("file closed, can not add entry")

################################################################################################
def add_waypoint(lon, lat, alt, speed, waypoint): 
  global data
  if(data.recording == True):
    loging.debug("adding waypoint")
    t = get_iso_datetime()
    txt = "  <wpt lat=\"" + str(lat) + "\" lon=\"" + str(lon) + "\">\n" + \
    "    <ele>" + str(int(alt)) + "</ele>\n" + \
    "    <time>" + str(t) + "</time>\n" + \
    "    <name>" + str(waypoint) + "</name>\n" + \
    "  </wpt>\n"
    data.waypoints += txt
  else:
    logging.warning("file closed, can not add entry")

################################################################################################
def stop_recording():
  global data
  logging.debug("Stop recording")
  if(data.recording == True): 
    txt = '''\
    </trkseg>
  </trk>
'''
    data.filehandle.write(txt)
    data.filehandle.write(data.waypoints)
    data.filehandle.write("\n</gpx>")
  try:
    data.filehandle.close()
    data.recording = False
  except:
    pass

################################################################################################
if __name__ == '__main__':
  global data
  app = QApplication(sys.argv)
  logging.basicConfig(stream=sys.stderr, level=logging.WARNING)
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
      
  #Load version file
  try:
    file = open(data.root + "version", 'r')
    data.version = file.readline()
    data.version=data.version[:-1]
    data.build = file.readline()
    logging.info("Version: "+str(data.version)+ "-"+str(data.build))
  except:
    logging.warning("Version file not found, please check your installation!")

  #root.setQMLData(data.showHomeNetwork, data.useautoreset, data.resetday, data.usedifference, data.difference)

  try:
    os.makedirs(data.path)
  except:
    pass

  #Those lines has to be run AFTER the above root.-commands, else the dummy values in QML will overwrite our real values!
  # instantiate the Python object
  qml_to_python = QML_to_Python_Interface()

  # expose the object to QML
  context = view.rootContext()
  context.setContextProperty("qml_to_python", qml_to_python)

  if(platform.machine().startswith('arm')):
    view.showFullScreen()
    view.show()
    logging.info("data.opt_in:", data.opt_in)
    if(data.opt_in == False):
      root.show_Opt_In()

  app.exec_() #endless loop

  config.Write()
  if(data.recording == True):
    logging.info("we are still recording, close file properly")
    stop_recording()
  logging.debug("Closing")

