#!/usr/bin/env python3

from fastai.vision import *
from fastai.metrics import error_rate
import os

data_dir = "../data"

# remove hidden files in os.listdir()
def remove_hidden(dir_list):
    for element in dir_list:
        if (element.startswith(".")):
            dir_list.remove(element)

def main():
    # TODO: Generate simulated data from Matlab code here
    # TODO: Make the next 3 comments automatic here

    # collect dataset using .js and download_images.py

    # organize dataset into data subfolders by hand

    # clean data by hand (delete bad images)

    # TODO: Use data augmentation to bloat dataset size
    # TODO: Incorporate cool data sifter widget from Jupyter (not a priority)

    # verify images
    classes = os.listdir(data_dir)
    remove_hidden(classes)
    path = Path(data_dir)
    for c in classes:
        verify_images(path/c,delete=True)

    # Create ImageDataBunch
    np.random.seed(42)
    data = ImageDataBunch.from_folder(path, train=path,valid_pct=0.2,
            ds_tfms=get_transforms(),size=224,num_workers=4).normalize(imagenet_stats)
    data.show_batch(rows=3,figsize=(7,8))
    plt.show() # exit matplotlib figure to continue code execution
    print(f'Classes: {data.classes}, Num classes: {data.c}, Training data: {len(data.train_ds)}, Validation data: {len(data.valid_ds)}')
    
    # Train resnet34 via transfer learning
    learn = cnn_learner(data,models.resnet34,metrics=error_rate)
    learn.fit_one_cycle(4) # transfer learning
    interp = ClassificationInterpretation.from_learner(learn)
    interp.plot_confusion_matrix()
    plt.show() # exit matplotlib figure to continue code execution

    # Plot top losses and learning rate curve

    # Export model to file

    # TODO: Make plt.show() non-blocking, or display in terminal with libsixel


if __name__ == '__main__':
    main()
