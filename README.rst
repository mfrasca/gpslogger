gpslogger
==========
gps-logger is Meego/Harmattan Nokia N9 GPS logging application, Licensed GPLv3. Original was written by George Ruinelli

short version
------------------

Install the original `gps-logger.deb
<https://www.ruinelli.ch/download/software/harmattan/gps-logger_0.2.5_armel.deb>`_
package, which should work already, then decide if you're happy with that
one, or if you want abitily to pause/resume, and grab waypoints.

If this is the case, after successful installation and having confirmed the
original `gps-logger` does work, overwrite part of it, as of `sync script
<https://github.com/mfrasca/gpslogger/blob/master/sync>`_.  You will need to
get permission to overwrite these files, I can help, but you better already
have some basic unix knowledge.

The map page does not work, not in the original (it needs nokia map which
isn't there any more), not here (I don't know how to link to OSM).

longish version
------------------

I've forked this in order to update it.  I found no app that would allow me see my position on a OSM map,
then I came across this project, which says it achieves precisely this, so let's have a look.

#. it will not run on a vanilla N9, I am now in the process of collecting dependencies.

#. it has no `setup.py` script, and also no `setup.cfg`, so it's going to be a trial/failure/correct loop, let's see how far we come.

first failure::

 user@theresia:~/MyDocs/Local/github/miurahr/gpslogger$ python main.py 
 Traceback (most recent call last):
   File "main.py", line 9, in <module>
     from PySide.QtCore import *
 ImportError: No module named PySide.QtCore

correction::

 root@theresia:~$ apt-get install python-pyside
 Reading package lists... Done
 Building dependency tree       
 Reading state information... Done
 The following extra packages will be installed:
   libpyside1.0 libpython2.6 libshiboken1.0 python-pyside.phonon python-pyside.qtcore
   python-pyside.qtdeclarative python-pyside.qtgui python-pyside.qtnetwork 
   python-pyside.qtopengl python-pyside.qtscript python-pyside.qtsql python-pyside.qtsvg
   python-pyside.qtwebkit python-pyside.qtxml python-support
 The following NEW packages will be installed
   libpyside1.0 libpython2.6 libshiboken1.0 python-pyside python-pyside.phonon 
   python-pyside.qtcore python-pyside.qtdeclarative python-pyside.qtgui 
   python-pyside.qtnetwork python-pyside.qtopengl python-pyside.qtscript
   python-pyside.qtsql python-pyside.qtsvg python-pyside.qtwebkit python-pyside.qtxml
   python-support
 0 upgraded, 16 newly installed, 0 to remove and 1 not upgraded.
 Need to get 9,354kB of archives.
 After this operation, 26.8MB of additional disk space will be used.
 Do you want to continue [Y/n]? 

failure::

  file:///opt/gps-logger/qml/main.qml: File not found 

correction::

  root@theresia:~$ ln -s /home/user/MyDocs/Local/github/miurahr/gpslogger/ /opt/gps-logger

now it does start, but it doesn't do much with the GPS signal.  it does not activate the GPS,
and if a different program does activate the GPS, gpslogger does not read the values.  

`trkpt` elements in the `gpx` file look like this::

                <trkpt lat="nan" lon="nan">
                        <ele>0</ele>
                        <time>2018-02-26T02:10:56Z</time>
                        <desc>Lat.=nan, Long.=nan, Alt.=0m, Speed=-3.6Km/h</desc>
                </trkpt>


also the map does not show at all, maybe (I'm guessing) it is using an obsolete OSM API?

I'll have a look at it in the following days.

I grabbed the (working) `gps-logger
<https://www.ruinelli.ch/download/software/harmattan/gps-logger_0.2.5_armel.deb>`_
by the original programmer, and installing it shows we need solving a few
more dependecies::
  
  Correcting dependencies...Done
  The following extra packages will be installed:
    libffi5 python-gconf python-gobject

    
I gave up on getting OSM working, I've reduced my expectations to being able
to record traces, and store waypoints.  what I suggest is that you install
the original software, then overwrite the qml and py files with what I've
edited here.  it works for me, and I am available for suggestions.
