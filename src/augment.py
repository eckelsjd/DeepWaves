# Los Alamos Dynamics Summer School (LADSS)
# Team: DeepWaves
# Date: 8/17/2020
# Author: Joshua Eckels (eckelsjd@rose-hulman.edu)
# Description: Script to augment dataset by generating new images in same directory

from skimage.util import random_noise # Gaussian noise function from skimage library (scikit-learn)
from skimage import io
import PIL
from pathlib import Path
import numpy as np
import os

path_img = Path("../images")
path_lbl = Path("../labels")

files = os.listdir(path_img) # get all images

if '_magnitude' in files[0]:
    token = '_magnitude'
elif '_real' in files[0]:
    token = '_real'
elif '_imaginary' in files[0]:
    token = '_imaginary'
else:
    print("Error: image needs to contain one of the above")

for img_file in files:
    spl = img_file.split(token) # split at file extension
    base = spl[0]
    ext = spl[1]
    label_file = base + '_mask' + ext

    # Gaussian noise (don't generate new mask)
    newname = base + token + '_gauss' + ext
    img = io.imread(path_img/img_file,as_gray=True)
    # img = np.array(PIL.Image.open(path_img/img_file))
    noise_img = random_noise(img,mode='gaussian',var=0.01)
    noise_img = (255*noise_img).astype(np.uint8)
    PIL.Image.fromarray(noise_img).save(path_img/newname)

    # Rotate 180 degrees (generate new mask)
    # newname = base + '_rot180' + token + ext
    # PIL.Image.fromarray(np.rot90(img,2)).save(path_img/newname)
    # img_label = np.array(PIL.Image.open(path_lbl/label_file))
    # new_label_name = base + '_rot180' + token + '_mask' + ext
    # PIL.Image.fromarray(np.rot90(img_label,2)).save(path_lbl/new_label_name)

