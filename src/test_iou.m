clear all;
close all;
clc;


classIDs = [0 1 2];
classes = ["black" "white" "red"];

size = 100;
w = 10;
h = 10;
disp = 5;
corner = 45;

targ = zeros(size,size);
y_dim = linspace(corner,corner+h-1,h);
x_dim = linspace(corner,corner+w-1,w);
targ(y_dim,x_dim) = 1;

targ(1:end,1:20) = 2;

pred = zeros(100,100);
pcorner = corner - disp;
py_dim = linspace(pcorner,pcorner+h-1,h);
px_dim = linspace(pcorner,pcorner+w-1,h);
pred(py_dim,px_dim) = 1;

figure()
subplot(2,1,1)
imshow(targ)
subplot(2,1,2)
imshow(pred)

imwrite(uint8(targ),'targ/targ1.png');
imwrite(uint8(pred),'pred/pred1.png');

targetDir = 'targ';
predDir = 'pred';
targDS = pixelLabelDatastore(targetDir,classes,classIDs);
predDS = pixelLabelDatastore(predDir,classes,classIDs);

seg_metrics = evaluateSemanticSegmentation(predDS,targDS);