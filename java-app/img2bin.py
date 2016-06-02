#!/usr/bin/python

import Image
import sys

if len(sys.argv) < 3:
  print("usage: img2bin <source-img> <dest-img>")
  exit()

img = Image.open(sys.argv[1]).convert('L').tostring()
bitout = open(sys.argv[2], 'wb')
bitout.write(img)
bitout.close()
