# Los Alamos Dynamics Summer School (LADSS)
# Team: DeepWaves
# Date: 8/17/2020
# Author: Joshua Eckels (eckelsjd@rose-hulman.edu)
# Description:
# Script to augment dataset by generating new images in same directory

from skimage.util import random_noise # Gaussian noise function from skimage library (scikit-learn)
from skimage import io
import PIL
from pathlib import Path
import numpy as np
import os

path_img = Path("../noise")

files = [f for f in os.listdir(path_img) if not f.startswith(".")] # get all images

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

    variance = [0.001,0.005,0.01,0.02,0.04,0.06,0.08,0.1]
    for i in range(len(variance)):
        var = variance[i]
        newname = base + token + '_gauss_' + str(i+1) + ext
        img = io.imread(path_img/img_file,as_gray=True)
        noise_img = random_noise(img,mode='gaussian',var=var)
        noise_img = (255*noise_img).astype(np.uint8)
        PIL.Image.fromarray(noise_img).save(path_img/newname)
