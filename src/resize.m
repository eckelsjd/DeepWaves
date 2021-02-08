% Helper script to resize graphics for journal
% Author: Joshua Eckels (eckelsjd@rose-hulman.edu)
% Date: February 5, 2021
clear all;
close all;
clc;

test_path = './test/';
targ_path = './targ/';
new_path = './new/';
test_files = dir(test_path);
targ_files = dir(targ_path);

for i = 1:length(test_files)
    file = test_files(i).name;
    if ~strncmpi(file(1),'.',1) && ~isfolder(file)
        test_img = imread([test_path char(test_files(i).name)]);
        targ_img = imread([targ_path char(targ_files(i).name)]);
        rescale_size = size(targ_img,1:2);
        new_img = imresize(test_img,rescale_size);
        imwrite(new_img,[new_path char(test_files(i).name)]);
    end
end 

