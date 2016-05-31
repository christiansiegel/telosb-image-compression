import Image
import sys

if len(sys.argv) < 3:
  print("usage: bin2img <source-img> <dest-img>")
  exit()

bitout = open(sys.argv[1], 'rb')
img = bitout.read()
bitout.close()
Image.fromstring('L', (256,256), img).save(sys.argv[2])
