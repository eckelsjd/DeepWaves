import os
import argparse
import random
import math
from pathlib import Path

def main():
    # Get contents of image directory
    imgs = os.listdir(Path(args.img))

    # Randomize order
    random.shuffle(imgs)

    # Calculate total number of image files needed based off percent
    total_valid = int(math.ceil(args.pct * len(imgs)))

    # Open 'valid.txt' for writing
    fd = open("valid.txt","w+")

    # Loop through filenames and add count
    i = 0
    for img in imgs:
        if (i>=total_valid):
            break;

        # Avoid augmentation images
        if 'aug' in img:
            continue

        fd.write(f'{img}\n')
        i = i+1

    # Close file
    fd.close()

if __name__ == '__main__':
    # Parse user input
    parse = argparse.ArgumentParser(description="Generate valid.txt file")
    parse.add_argument("-p","--pct",type=float,default=0.2,help="Validation set percentage")
    parse.add_argument("-i","--img",required=True,help="Path to image directory")
    args = parse.parse_args()
    main()
