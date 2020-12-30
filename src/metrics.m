% Get Semantic segmentation metrics
% targs: test/targets
% preds: test/predictions
clear all;
close all;
clc;
%% DATA IMPORT
% Get predefined color map
% c_map = flip(linspecer(num_classes,'sequential'),1); % generate N linear colors
load c_map
c_map = c_map/255;
% codes.txt has all plate thickness classes mapped to indices 0:num_classes
fd = fopen('codes.txt','r');
codes = fscanf(fd,"%f\n");
fclose(fd);
testDir = '../test/';
% dataDir = [testDir,'testset/'];
targetDir = [testDir,'targets/'];
predDir = [testDir,'predictions/'];

%% SET UP
% set up colorbar parameters
label = [0, flip(codes)']; % colorbar tick labels (classes)
labelChar = strsplit(sprintf('%d ',label));
labelChar(end) = [];
min_class_val = min(codes);
max_class_val = max(codes);
inc = abs(codes(1)-codes(2)); % color bar increment

% Set up Matlab datastores
classIDs = [0:1:length(codes)-1];
classes = string(strsplit(sprintf('mm%d ',codes')));
classes(end) = [];
targDS = pixelLabelDatastore(targetDir,classes,classIDs);
predDS = pixelLabelDatastore(predDir,classes,classIDs);

% Generate segmentation metrics
seg_metrics = evaluateSemanticSegmentation(predDS,targDS);
wIoU = weightedIoU(seg_metrics);

%% GENERATE AND SAVE FIGURES
% Save target and prediction figures
num_files = length(predDS.Files);
for i = 1 : num_files
    pred_path = string(predDS.Files(i));
    targ_path =string(targDS.Files(i));
    tokens = strsplit(pred_path,'\');
    file = tokens(end);
    base_file = extractBetween(file,"","_pred.png");
%     data_path = [dataDir,char(base_file),'_real.png'];
    
    % read the target image into matrix
    targ_classes = imread(targ_path);
    targ_thickness = max_class_val - targ_classes;
    
    % read the prediction image into matrix
    pred_classes = imread(pred_path); 
    pred_thickness = max_class_val - pred_classes; 
    
    f_seg = figure('Visible','off');
    imshow(uint8(targ_thickness),'DisplayRange',[min_class_val max_class_val],'Colormap',c_map);
    cb = colorbar();
    caxis([min_class_val max_class_val+1]);
    cb.YTick = (min_class_val - inc/2) : inc : max_class_val+1; % put ticks in middle of boxes
    cb.TickLabels = labelChar(1:end);
    cb.TickLabelInterpreter = 'latex';
    cb.LineWidth = 0.8;
    cb.FontSize = 11;
    cb.TickLength = 0;
    set(get(cb,'label'),'string','Plate thickness ($mm$)')
    set(get(cb,'label'),'interpreter','latex');
    set(get(cb,'label'),'FontSize',11);
    set(f_seg,'Visible','on');
    set(f_seg,'ToolBar','none'); % annoying pop-up toolbar
    exportgraphics(gca,['../output/ground_truth/',char(base_file),'_targ.tif'],'Resolution',300);
    set(f_seg,'ToolBar','figure');
    saveas(gcf,['../output/figs/',char(base_file),'_targ']);
    set(f_seg,'Visible','off');
 
    f_seg = figure('Visible','off');
    imshow(uint8(pred_thickness),'DisplayRange',[min_class_val max_class_val],'Colormap',c_map);
    cb = colorbar();
    caxis([min_class_val max_class_val+1]);
    cb.YTick = (min_class_val - inc/2) : inc : max_class_val+1; % put ticks in middle of boxes
    cb.TickLabels = labelChar(1:end);
    cb.TickLabelInterpreter = 'latex';
    cb.LineWidth = 0.8;
    cb.FontSize = 11;
    cb.TickLength = 0;
    set(get(cb,'label'),'string','Plate thickness ($mm$)')
    set(get(cb,'label'),'interpreter','latex');
    set(get(cb,'label'),'FontSize',11);
    set(f_seg,'Visible','on');
    set(f_seg,'ToolBar','none'); % annoying pop-up toolbar
    exportgraphics(gca,['../output/ground_truth/',char(base_file),'_pred.tif'],'Resolution',300);
    set(f_seg,'ToolBar','figure');
    saveas(gcf,['../output/figs/',char(base_file),'_pred']);
    set(f_seg,'Visible','off');
end

function wIoU = weightedIoU(ssm)
    % ssm: semanticSegmentationMetrics object
    cm = ssm.ConfusionMatrix;
    total_pixels = sum(cm{:,:},'all');
    class_pixels = sum(cm{:,:},2);
    weights = class_pixels/total_pixels;
    ious = ssm.ClassMetrics{:,2};
    ious(isnan(ious)) = 0;
    wIoU = sum(weights .* ious);
end

