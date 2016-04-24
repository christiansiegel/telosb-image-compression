import Image

def imageFromBinary(imageFile, binaryFile):
    bitout = open(binaryFile, 'rb')
    img = bitout.read()
    bitout.close()
    Image.fromstring('L', (256,256), img).save(imageFile)

if __name__ == "__main__":
    imageFromBinary('backconverted/aerial.tiff', 'binary/aerial.bin')
    imageFromBinary('backconverted/airplane.tiff', 'binary/airplane.bin')
    imageFromBinary('backconverted/chemicalplant.tiff', 'binary/chemicalplant.bin')
    imageFromBinary('backconverted/clock.tiff', 'binary/clock.bin')
    imageFromBinary('backconverted/moonsurface.tiff', 'binary/moonsurface.bin')
    imageFromBinary('backconverted/resolutionchart.tiff', 'binary/resolutionchart.bin')
