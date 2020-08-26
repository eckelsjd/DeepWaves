% Los Alamos Dynamics Summer School (LADSS)
% DeepWaves 8/17/2020
% Matlab function written by: Joshua Eckels (eckelsjd@rose-hulman.edu)
%
% Runs plot_wavefield.m script in parallel on all ANSYS data files.
% Can generate grayscale,color, or default segmentation masks.
% Can generate batchnorm or single image norm wavefield images.
% Uses Matlab parallel computing toolbox. See "parfor" loop below.
% SEE plot_wavefield.m documentation for more help
clear all
close all
clc

% Get list of all data files
datapath = '../data/';
files = dir(datapath);
real = [];
imaginary = [];
for i = 1:length(files)
    if ~files(i).isdir
        if contains(files(i).name,'real','IgnoreCase',true)
            real = [real,string(files(i).name)];
        elseif contains(files(i).name,'imaginary','IgnoreCase',true)
            imaginary = [imaginary,string(files(i).name)];
        else
            str = sprintf('Incorrect file format: %s',files(i).name);
            fprintf("%s\n",str);
            continue
        end
    end
end

% Obtain max and min displacement values to batch normalize data
% norm = norm_batch(real,imaginary);

funs = {}; % store function handles

% Get real,imaginary data filenames (they are at same index)
for i = 1:length(real)
    real_filename = real(i);
    imag_filename = imaginary(i);
    
    % Setup a function to run later
    fun = @()plot_wavefield(real_filename,imag_filename,'color',[]);
%     fun = @()plot_wavefield(real_filename,imag_filename,'no_mask',norm);
    funs{end+1} = fun;
end

% Run all collected functions in parallel
% Simply change "parfor" loop to "for" loop if you do not have Matlab
% parallel computing toolbox installed
parfor k = 1:length(funs)
    funs{k}();
end