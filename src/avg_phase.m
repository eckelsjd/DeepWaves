% Helper function to average CNN predictions over phase shifts
% Author: Joshua Eckels (eckelsjd@rose-hulman.edu)
% Date: February 7, 2021
clear all;
close all;
clc;

test_path = '../test/predictions/';
deep_files = dir([test_path 'deeper']);
shallow_files = dir([test_path 'shallow']);

% Average over 0-360 phase shifts
avg_deep = zeros(400,400);
for i = 1:length(deep_files)
    file = deep_files(i).name;
    if ~strncmpi(file(1),'.',1) && ~isfolder(file)
        img = imread([test_path 'deeper/' char(deep_files(i).name)]);
        avg_deep = avg_deep + double(img);
    end
end
avg_deep = avg_deep ./ length(deep_files);

avg_shallow = zeros(400,400);
for i = 1:length(shallow_files)
    file = shallow_files(i).name;
    if ~strncmpi(file(1),'.',1) && ~isfolder(file)
        img = imread([test_path 'shallow/' char(shallow_files(i).name)]);
        avg_shallow = avg_shallow + double(img);
    end
end
avg_shallow = avg_shallow ./ length(shallow_files);

% Plot results
% codes.txt has all plate thickness classes mapped to indices 0:num_classes
fd = fopen('codes.txt','r');
codes = fscanf(fd,"%f\n");
fclose(fd);
min_class_val = min(codes);
max_class_val = max(codes);
deep_thick = max_class_val - avg_deep; % convert class to local thickness
shallow_thick = max_class_val - avg_shallow;

% Interpolate discrete color map
load c_map
x = min_class_val:1:max_class_val;
n = 64;
xq = linspace(min_class_val,max_class_val,n);
red = c_map(:,1);
green = c_map(:,2);
blue = c_map(:,3);
red_vq = interp1(x,red,xq);
green_vq = interp1(x,green,xq);
blue_vq = interp1(x,blue,xq);
cmap_new = [red_vq',green_vq',blue_vq']./255;

figure()
imshow(flip(deep_thick,1),'DisplayRange',[min_class_val max_class_val],'Colormap',cmap_new);
cb = colorbar();
caxis([min_class_val max_class_val+1]);
cb.TickLabelInterpreter = 'latex';
cb.LineWidth = 0.8;
cb.FontSize = 11;
cb.TickLength = 0;
set(get(cb,'label'),'string','Plate thickness ($mm$)')
set(get(cb,'label'),'interpreter','latex');
set(get(cb,'label'),'FontSize',11);
set(gcf,'ToolBar','none'); % annoying pop-up toolbar
exportgraphics(gca,'test_deeper_avg_360.tif','Resolution',300);

figure()
imshow(flip(shallow_thick,1),'DisplayRange',[min_class_val max_class_val],'Colormap',cmap_new);
cb = colorbar();
caxis([min_class_val max_class_val+1]);
cb.TickLabelInterpreter = 'latex';
cb.LineWidth = 0.8;
cb.FontSize = 11;
cb.TickLength = 0;
set(get(cb,'label'),'string','Plate thickness ($mm$)')
set(get(cb,'label'),'interpreter','latex');
set(get(cb,'label'),'FontSize',11);
set(gcf,'ToolBar','none'); % annoying pop-up toolbar
exportgraphics(gca,'test_shallow_avg_360.tif','Resolution',300);
    

% Average over real (0 deg) and imaginary (90 deg)
deep_real = imread([test_path 'deeper/test_deeper_banana_phase0_0.985_pred.png']);
deep_im = imread([test_path 'deeper/test_deeper_banana_phase90_0.985_pred.png']);
avg_deep = zeros(400,400);
avg_deep = (avg_deep + double(deep_real) + double(deep_im)) ./ 2;

shallow_real = imread([test_path 'shallow/test_shallow_banana_phase0_0.963_pred.png']);
shallow_im = imread([test_path 'shallow/test_shallow_banana_phase90_0.963_pred.png']);
avg_shallow = zeros(400,400);
avg_shallow = (avg_shallow + double(shallow_real) + double(shallow_im)) ./ 2;

deep_thick = max_class_val - avg_deep; % convert class to local thickness
shallow_thick = max_class_val - avg_shallow;

figure()
imshow(flip(deep_thick,1),'DisplayRange',[min_class_val max_class_val],'Colormap',cmap_new);
cb = colorbar();
caxis([min_class_val max_class_val+1]);
cb.TickLabelInterpreter = 'latex';
cb.LineWidth = 0.8;
cb.FontSize = 11;
cb.TickLength = 0;
set(get(cb,'label'),'string','Plate thickness ($mm$)')
set(get(cb,'label'),'interpreter','latex');
set(get(cb,'label'),'FontSize',11);
set(gcf,'ToolBar','none'); % annoying pop-up toolbar
exportgraphics(gca,'test_deeper_avg_90.tif','Resolution',300);

figure()
imshow(flip(shallow_thick,1),'DisplayRange',[min_class_val max_class_val],'Colormap',cmap_new);
cb = colorbar();
caxis([min_class_val max_class_val+1]);
cb.TickLabelInterpreter = 'latex';
cb.LineWidth = 0.8;
cb.FontSize = 11;
cb.TickLength = 0;
set(get(cb,'label'),'string','Plate thickness ($mm$)')
set(get(cb,'label'),'interpreter','latex');
set(get(cb,'label'),'FontSize',11);
set(gcf,'ToolBar','none'); % annoying pop-up toolbar
exportgraphics(gca,'test_shallow_avg_90.tif','Resolution',300);
