# Deep Waves: Defect Characterization in Ultrasonic Wavefield Measurements using Deep Learning

Contributors: Joshua Eckels, Isabel Fernandez, Kelly Ho, Adam Wachtor, Erica Jacobson

## Setup

1. Setup a python 3 virtual environment to work on a Fast AI project. See https://www.bogotobogo.com/python/python_virtualenv_virtualenvwrapper.php . Virtualenvwrapper will be used here in a virtual environment named 'fastai'.

2. ```workon fastai``` to enter the virtual environment.

3. ```pip install fastai``` to install the fast.ai library with all dependencies included.

4. ```pip install opencv-python``` for basic access to the OpenCV library. This is used during the dataset generation steps and for image processing.

5. ```pip install requests argparse imutils``` for other dependencies. 

6. There is a problem using PyTorch 1.5.0 vs. 1.4.0 under the current installation of the fastai library. Install PyTorch 1.4.0 instead of 1.5.0 to fix this (potentially). Or make the small fix as described below:

   Navigate to ```~/.virtualenv/fastai/lib/python3.6/site-packages/fastai/vision/image.py``` . Open the file and navigate to line 540. Add the keyword argument  ```recompute_scale_factor=True``` to the function call. Line 540 should now look like this: ``` x = F.interpolate(x[None], ... , recompute_scale_factor=True)[0]``` . See this post https://forums.fast.ai/t/fastai-throwing-a-runtime-error-when-using-custom-train-test-sets/70262/6 in the fast.ai forums for more information.
   
   

## Directory Structure

```src``` : all Python source files.

```data``` : ImageNet-typical formatted structure for holding training data. All subfolders in the ```data``` directory are named with the labels of objects. All images of a given object are located as a .jpg file within its respective data subdirectory. Images are not included in the git repository.

## Generating a Dataset

1. Open Google Images and search for a desired object.
2. ```Ctrl+Shft+j``` to enter the Javascript command window (on Windows/Linux + Chrome).
3. Copy and paste all functions located in ```src/js_console.js``` into the command window. This will download a "urls.txt" file to your default download directory. Move this file into the ```src``` directory. It contains a line-separated list of several image hyperlinks on the current webpage.
4. Navigate to the ```src``` directory and run ```python3 dowload_images.py --urls urls.txt --output ../data/desired_object_folder_name```. This will download all of the images to the indicated data directory.
5. Repeat for all desired objects. Navigate through all the downloaded images by hand and delete undesirable/erroneous images.

## Training

1. Run ```./Train.py``` from the ```src``` directory.

## TO DO

1. Automate the image download and cleaning process.
2. Display intermediate Fast AI result figures in the terminal or on-screen in a non-blocking fashion, perhaps with libsixel package.
3. Add data augmentation using Fast AI library.
4. Export trained model to a file.
5. Create a script for loading the model and running predictions on new images.
6. Use Fast AI library to perform object localization and gather bounding box information. If not Fast AI, then import model into OpenCV and then gather bounding box information.
7. Use OpenCV (or some other image processing) to generate a wavefield map based on bounding box information. Use different wavenumber values to color the image pixel by pixel. (Resolution will be determined by accuracy of the trained model).
8. Simulate wavefield images using MATLAB, k-wave, Abaqus, ANSYS, etc.

## Current bugs