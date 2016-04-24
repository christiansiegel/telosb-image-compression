import filecmp

def compare(fileA, fileB):
    if not filecmp.cmp(fileA, fileB):
        print(fileA + ' <> ' + fileB)

if __name__ == "__main__":
    compare('original/aerial.tiff', 'backconverted/aerial.tiff')
    compare('original/airplane.tiff', 'backconverted/airplane.tiff')
    compare('original/chemicalplant.tiff', 'backconverted/chemicalplant.tiff')
    compare('original/clock.tiff', 'backconverted/clock.tiff')
    compare('original/moonsurface.tiff', 'backconverted/moonsurface.tiff')
    compare('original/resolutionchart.tiff', 'backconverted/resolutionchart.tiff')
