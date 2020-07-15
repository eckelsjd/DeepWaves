#!/usr/bin/env python3

from fastai.vision import *
from fastai.metrics import dice
from torch import cuda as cd
import torch
from torch.nn import functional as F
from functools import partial

# accuracy function for Camvid dataset
# this is basically foreground_acc
def acc_camvid(inputs, target):
    # DONE: write a generic accuracy function (not camvid)
    # type = torch.Tensor
    # shape = [B, C, H, W]
    # B=num_batches,C=num_classes,H=height,W=width
    target = target.squeeze(1)
    mask = target != void_code
    return (inputs.argmax(dim=1)[mask]==target[mask]).float().mean()

# Return Jaccard index, or Intersection over Union (IoU) value
def jaccard_loss(input:Tensor, targs:Tensor, eps:float=1e-8)->Rank0Tensor:
    """Computes the Jaccard loss, a.k.a the IoU loss.
    Note that PyTorch optimizers minimize a loss. In this
    case, we would like to maximize the jaccard loss so we
    return the negated jaccard loss.
    Args:
        targs: a tensor of shape [B, H, W] or [B, 1, H, W].
        input: a tensor of shape [B, C, H, W]. Corresponds to
            the raw output or logits of the model. (prediction)
        eps: added to the denominator for numerical stability.
    Returns:
        jacc_loss: the Jaccard loss.
    """
    num_classes = input.shape[1]
    if num_classes == 1:
        true_1_hot = torch.eye(num_classes + 1)[targs.squeeze(1)]
        true_1_hot = true_1_hot.permute(0, 3, 1, 2).float()
        true_1_hot_f = true_1_hot[:, 0:1, :, :]
        true_1_hot_s = true_1_hot[:, 1:2, :, :]
        true_1_hot = torch.cat([true_1_hot_s, true_1_hot_f], dim=1)
        pos_prob = torch.sigmoid(input)
        neg_prob = 1 - pos_prob
        probas = torch.cat([pos_prob, neg_prob], dim=1)
    else:
        true_1_hot = torch.eye(num_classes)[targs.squeeze(1)]
        true_1_hot = true_1_hot.permute(0, 3, 1, 2).float()
        probas = F.softmax(input, dim=1)
    true_1_hot = true_1_hot.type(input.type())
    dims = (0,) + tuple(range(2, targs.ndimension()))
    intersection = torch.sum(probas * true_1_hot, dims)
    cardinality = torch.sum(probas + true_1_hot, dims)
    union = cardinality - intersection
    jacc_loss = (intersection / (union + eps)).mean()
    return jacc_loss

def main():
    # get path to data images and labels
    path_lbl = path/'labels'
    path_img = path/'images'

    fnames = get_image_files(path_img)
    lbl_names = get_image_files(path_lbl)

    # show example image
    img_f = fnames[10]
    # img = open_image(img_f)
    # img.show(figsize=(5,5))
    # plt.show(block=False)

    # function to get label path from image filename
    get_y_fn = lambda x: path_lbl/f'{x.stem}_P{x.suffix}'

    # show image mask (Ground truth labeled image)
    mask = open_mask(get_y_fn(img_f))
    # mask.show(figsize=(5,5), alpha=1)
    # plt.show(block=False)
    
    # SIZE input
    src_size = np.array(mask.shape[1:])
    # torch.Size([1,720,960]) H=720, W=960
    # size = src_size//2 # SMALL
    size = src_size      # BIG
    bs = 4 # SMALL->12 : BIG->4

    # GET images
    src = SegmentationItemList.from_folder(path_img)
    # fastai.vision.data.SegmentationItemList :: ItemList

    # SPLIT train/valid
    src = src.split_by_fname_file(str(path/'valid.txt'))
    # fastai.data_block.ItemLists

    # LABEL classes
    src = src.label_from_func(get_y_fn, classes=codes)
    # fastai.data_block.LabelLists

    # TODO: replace split_by_fname_file, or write code to generate valid.txt automatically
    # ItemList.split_by_rand_pct
    # ItemList.split_by_folder

    # TODO: augment dataset size with apply_tfms or other
    # get_transforms() does not increase dataset size;
    # it gives randomness to images before training each round

    # Create normalized ImageDataBunch
    data = src.transform(get_transforms(), size=size, tfm_y=True).databunch(bs=bs).normalize(imagenet_stats)
    # fastai.basic_data.DataBunch

    # data.show_batch(rows=3, figsize=(12,9))
    # plt.show(block=False)

    # METRICS
    # jaccard_loss
    # foreground_acc

    # Create U-net learner
    learn = unet_learner(data, models.resnet34,metrics=[jaccard_loss,acc_camvid,dice])
    learn.path = Path(".")
    # wd = weight decay = around 0.1 or 0.01; prevent overfitting
    # TODO: Custom U-net class to implement Refine-Net

    # TRAIN model
    # learn.load('stage-1') # SMALL
    learn.load('stage-1-big')

    # STAGE 1 : OPTIMIZE learning rate
    # learn.lr_find()
    # lr_fig = learn.recorder.plot(return_fig=True)
    # lr_fig.savefig("lr_find.png")
    lr = 3e-03
    # learn.fit_one_cycle(10,slice(lr))
    # learn.save('stage-1')
    # learn.save('stage-1-big')

    # STAGE 2 : UNFREEZE
    learn.unfreeze()
    # learn.lr_find()
    # lr_fig2 = learn.recorder.plot(return_fig=True)
    # lr_fig2.savefig("lr_find2.png") 

    learn.fit_one_cycle(12,slice(4e-05,lr/5))
    # learn.save('stage-2')
    learn.save('stage-2-big')
    # pct_start -> how long to spend on lr increasing = 0.3 default

    # RESULTS
    # res_fig = learn.show_results(rows=3, figsize=(8,9))
    # res_fig.savefig("res_fig.png")
    loss_fig = learn.recorder.plot_losses(return_fig=True)
    loss_fig.savefig("losses.png")
    lr_dist = learn.recorder.plot_lr(return_fig=True)
    lr_dist.savefig("lr_dist.png")

    # EXPORT model
    learn.export()

    # LOAD model
    # INFERENCE

    # TODO: Better output format for presentation
    # plt.show()

if __name__ == '__main__':
    # clear GPU cache
    cd.empty_cache()

    # get training data
    path = untar_data(URLs.CAMVID)
    codes = np.loadtxt(path/'codes.txt',dtype=str)
    # write codes.txt by hand for desired classes

    name2id = {v:k for k,v in enumerate(codes)}
    void_code = name2id['Void']
    # use 'Void' class for background

    main()
