#!/usr/bin/env python

# Written by Bram Cohen
# this file is public domain

import sys
assert sys.version >= '2', "Install Python 2.0 or greater"
from distutils.core import setup, Extension

setup(
    name = "BitTorrent",
    version = "2.5.0",
    author = "Bram Cohen",
    author_email = "<bram@bitconjurer.org>",
    url = "http://www.bitconjurer.org/BitTorrent/",
    license = "Public Domain",
    
    ext_modules = [
    Extension(name    = "_StreamEncrypter",
              sources = ["_StreamEncrypter.c"]
              )
    ],

    packages = ["BitTorrent"],

    scripts = ["btdownloadgui.py", "btdownloadheadless.py", "btdownloadlibrary.py", 
        "btdownloadprefetched.py", "bttrack.py", "btpublish.py"]
    
    )
