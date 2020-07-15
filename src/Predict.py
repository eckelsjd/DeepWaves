from fastai.vision import *
import torch
from torch.nn import functional as F

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
    # Load trained model from 'export.pkl'
    learn = load_learner(Path("."))
    img = open_image("test2.jpeg")
    img.show(figsize=(5,5))
    plt.show(block=False)

    res_img = learn.predict(img)
    res_img[0].show(figsize=(5,5))
    plt.show(block=False)

    plt.show()

if __name__ == '__main__':
    main()
