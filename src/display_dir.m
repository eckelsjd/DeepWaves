% Los Alamos Dynamics Summer School (LADSS)
% DeepWaves 8/17/2020
% Matlab function written by: Joshua Eckels (eckelsjd@rose-hulman.edu)
% Loops through all mask images and changes on button press for quick viewing
clear all;
close all;
clc;

path = '../output/predictions/';
files = dir(path);

for i = 1:length(files)
    file = files(i).name;
    if ~strncmpi(file(1),'.',1) && ~isfolder(file)
        img = imread([path char(files(i).name)]);
        fprintf("Image %d: %s\n",i,files(i).name);
        figure()
        imshow(img);
        title(files(i).name,'Interpreter','none');
        
        % Dispaly center pixel values to check default label case easier
%         P = impixel;
%         disp(P);
%         fprintf("Waiting...\n");
%         A = img(150:250,150:250);
%         disp(A);
        w = waitforbuttonpress;
        close;               
    end
end 