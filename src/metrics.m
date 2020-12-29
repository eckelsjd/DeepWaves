% Get Semantic segmentation metrics
% targs: test/targets
% preds: test/predictions
clear all;
close all;
clc;

% Things repeated from plot wavefield:
% - color map
% - reading codes.txt
% - making the colorbar
% - converting from class values to local thickness

c_map = [128 0 0; % manually make c_map here
          230 25 75;
          245 130 48;
          255 255 25;
          210 245 60;
          115, 250, 80
          170 255 195;
          70 240 240;
          0 130 200;
          0 0 128] / 255;
      
fd = fopen('codes.txt','r');
codes = fscanf(fd,"%f\n");
fclose(fd);
classIDs = [0:1:length(codes)-1];
classes = string(strsplit(sprintf('mm%d ',codes')));
classes(end) = [];

targetDir = '../test/targets';
predDir = '../test/predictions';
targDS = pixelLabelDatastore(targetDir,classes,classIDs);
predDS = pixelLabelDatastore(predDir,classes,classIDs);

seg_metrics = evaluateSemanticSegmentation(predDS,targDS);

% Save prediction figures
num_files = length(predDS.Files);
for i = 1 : num_files
    path = string(predDS.Files(i));
    tokens = strsplit(path,'\');
    file = tokens(end);
    base_file = extractBetween(file,"",".png");
    
    local_thick = 10 - imread(path); % read the prediction image into 400x400 matrix
    label = [0, flip(codes)']; % colorbar labels (classes)
    min_class_val = min(codes);
    max_class_val = max(codes);
    f_seg = figure('Visible','off');
    imshow(uint8(local_thick),'DisplayRange',[min_class_val max_class_val],'Colormap',c_map);
    cb = colorbar();
    caxis([min_class_val max_class_val+1]);
    inc = abs(codes(1)-codes(2));
    cb.YTick = (min_class_val - inc/2) : inc : max_class_val+1; % put ticks in middle of boxes
    labelChar = strsplit(sprintf('%d ',label));
    cb.TickLabels = labelChar(1:end-1);
    cb.TickLabelInterpreter = 'latex';
    cb.LineWidth = 0.8;
    cb.FontSize = 11;
    cb.TickLength = 0;
    set(get(cb,'label'),'string','Plate thickness ($mm$)')
    set(get(cb,'label'),'interpreter','latex');
    set(get(cb,'label'),'FontSize',11);
    set(f_seg,'Visible','on');
    set(f_seg,'ToolBar','none'); % annoying pop-up toolbar
    exportgraphics(gca,['../output/ground_truth/',char(base_file),'_rgb.tif'],'Resolution',300);
    set(f_seg,'ToolBar','figure');
    saveas(gcf,['../output/figs/',char(base_file),'_rgb']);
    set(f_seg,'Visible','off');
    
end

