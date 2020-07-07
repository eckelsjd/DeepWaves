#!/usr/bin/env python3

from fastai.vision import *
from torch import cuda as cd

# accuracy function for Camvid dataset
def acc_camvid(inputs, target):
    target = target.squeeze(1)
    mask = target != void_code
    return (inputs.argmax(dim=1)[mask]==target[mask]).float().mean()

def main():
    # get path to data images and labels
    # path = untar_data(URLs.CAMVID)
    path_lbl = path/'labels'
    path_img = path/'images'

    fnames = get_image_files(path_img)
    lbl_names = get_image_files(path_lbl)

    # show example image
    img_f = fnames[10]
    img = open_image(img_f)
    # img.show(figsize=(5,5))
    # plt.show(block=False)

    # function to get label path from image filename
    get_y_fn = lambda x: path_lbl/f'{x.stem}_P{x.suffix}'

    # show image mask (Ground truth labeled image)
    mask = open_mask(get_y_fn(img_f))
    # mask.show(figsize=(5,5), alpha=1)
    # plt.show(block=False)
    
    # get class names
    src_size = np.array(mask.shape[1:])
    size = src_size//2
    bs = 2

    # divide into train and valid lists; label images
    src = SegmentationItemList.from_folder(path_img).split_by_fname_file(str(path/'valid.txt')).label_from_func(get_y_fn, classes=codes)

    # Create normalized ImageDataBunch
    data = src.transform(get_transforms(), size=size, tfm_y=True).databunch(bs=bs).normalize(imagenet_stats)

    data.show_batch(rows=3, figsize=(12,9))
    plt.show(block=False)

    # Create U-net learner
    learn = unet_learner(data, models.resnet34,metrics=acc_camvid,wd=1e-2)

    # look for good learning rate
    # learn.lr_find()
    # lr = learn.recorder.plot(return_fig=True)
    # lr.savefig("learning_rate.png")
    
    # train model
    learn.fit_one_cycle(4,max_lr=slice(1e-5,1e-3),pct_start=0.9)
    learn.save('camvid-stage-1')
    learn.show_results(rows=3, figsize=(8,9))
    learn.export()
    plt.show(block=False)

    # display all figures at the end
    plt.show()

if __name__ == '__main__':
    cd.empty_cache()
    path = Path("/home/eckelsjd/.fastai/data/camvid")
    codes = np.loadtxt(path/'codes.txt',dtype=str)
    name2id = {v:k for k,v in enumerate(codes)}
    void_code = name2id['Void']
    main()
