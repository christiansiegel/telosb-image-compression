import Image

def imageToBinary(imageFile, binaryFile):
    img = Image.open(imageFile).convert('L').tostring()
    bitout = open(binaryFile, 'wb')
    bitout.write(img)
    bitout.close()

if __name__ == "__main__":
    imageToBinary('original/aerial.tiff', 'binary/aerial.bin')
    imageToBinary('original/airplane.tiff', 'binary/airplane.bin')
    imageToBinary('original/chemicalplant.tiff', 'binary/chemicalplant.bin')
    imageToBinary('original/clock.tiff', 'binary/clock.bin')
    imageToBinary('original/moonsurface.tiff', 'binary/moonsurface.bin')
    imageToBinary('original/resolutionchart.tiff', 'binary/resolutionchart.bin')
