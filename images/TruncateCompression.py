import Image

def truncate1(imageFile, compressedImageFile):
    img = Image.open(imageFile).convert('L').tostring()
    compressed = ""
    for c in img:
        compressed += chr((ord(c) >> 1) << 1)
    Image.fromstring('L', (256,256), compressed).save(compressedImageFile)
    
def truncate2(imageFile, compressedImageFile):
    img = Image.open(imageFile).convert('L').tostring()
    compressed = ""
    for c in img:
        compressed += chr((ord(c) >> 2) << 2)
    Image.fromstring('L', (256,256), compressed).save(compressedImageFile)

def truncate4(imageFile, compressedImageFile):
    img = Image.open(imageFile).convert('L').tostring()
    compressed = ""
    for c in img:
        compressed += chr((ord(c) >> 4) << 4)
    Image.fromstring('L', (256,256), compressed).save(compressedImageFile)

if __name__ == "__main__":
    truncate1('original/aerial.tiff', 'truncate1/aerial.tiff')
    truncate1('original/airplane.tiff', 'truncate1/airplane.tiff')
    truncate1('original/chemicalplant.tiff', 'truncate1/chemicalplant.tiff')
    truncate1('original/clock.tiff', 'truncate1/clock.tiff')
    truncate1('original/moonsurface.tiff', 'truncate1/moonsurface.tiff')
    truncate1('original/resolutionchart.tiff', 'truncate1/resolutionchart.tiff')
    
    truncate2('original/aerial.tiff', 'truncate2/aerial.tiff')
    truncate2('original/airplane.tiff', 'truncate2/airplane.tiff')
    truncate2('original/chemicalplant.tiff', 'truncate2/chemicalplant.tiff')
    truncate2('original/clock.tiff', 'truncate2/clock.tiff')
    truncate2('original/moonsurface.tiff', 'truncate2/moonsurface.tiff')
    truncate2('original/resolutionchart.tiff', 'truncate2/resolutionchart.tiff')
    
    truncate4('original/aerial.tiff', 'truncate4/aerial.tiff')
    truncate4('original/airplane.tiff', 'truncate4/airplane.tiff')
    truncate4('original/chemicalplant.tiff', 'truncate4/chemicalplant.tiff')
    truncate4('original/clock.tiff', 'truncate4/clock.tiff')
    truncate4('original/moonsurface.tiff', 'truncate4/moonsurface.tiff')
    truncate4('original/resolutionchart.tiff', 'truncate4/resolutionchart.tiff')
