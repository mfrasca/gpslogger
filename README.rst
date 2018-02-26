gpslogger
==========
gps-logger is Meego/Harmattan Nokia N9 GPS logging application, Licensed GPLv3. Original was written by George Ruinelli

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

attempt at correcting the failure::

 root@theresia:~$ apt-get install python-pyside
 Reading package lists... Done
 Building dependency tree       
 Reading state information... Done
 The following extra packages will be installed:
   libpyside1.0 libpython2.6 libshiboken1.0 python-pyside.phonon python-pyside.qtcore python-pyside.qtdeclarative python-pyside.qtgui
   python-pyside.qtnetwork python-pyside.qtopengl python-pyside.qtscript python-pyside.qtsql python-pyside.qtsvg
   python-pyside.qtwebkit python-pyside.qtxml python-support
 The following NEW packages will be installed
   libpyside1.0 libpython2.6 libshiboken1.0 python-pyside python-pyside.phonon python-pyside.qtcore python-pyside.qtdeclarative
   python-pyside.qtgui python-pyside.qtnetwork python-pyside.qtopengl python-pyside.qtscript python-pyside.qtsql python-pyside.qtsvg
   python-pyside.qtwebkit python-pyside.qtxml python-support
 0 upgraded, 16 newly installed, 0 to remove and 1 not upgraded.
 Need to get 9,354kB of archives.
 After this operation, 26.8MB of additional disk space will be used.
 Do you want to continue [Y/n]? 
