% Get Semantic segmentation metrics
% targs: test/targets
% preds: test/predictions
clear all;
close all;
clc;
set(0,'defaulttextinterpreter','latex')
%% DATA IMPORT
% Get predefined color map
% c_map = flip(linspecer(num_classes,'sequential'),1); % generate N linear colors
load c_map
c_map = c_map/255;
% codes.txt has all plate thickness classes mapped to indices 0:num_classes
fd = fopen('codes.txt','r');
codes = fscanf(fd,"%f\n");
fclose(fd);
min_class_val = min(codes);
max_class_val = max(codes);
testDir = '../test/';
targetDir = [testDir,'targets/'];
predDir = [testDir,'predictions/'];

% Set up classes
classIDs = [0:1:length(codes)-1];
classes = string(strsplit(sprintf('mm%d ',codes')));
classes(end) = [];

%% IoU on each test image individually
targDS = pixelLabelDatastore(targetDir,classes,classIDs);
predDS = pixelLabelDatastore(predDir,classes,classIDs);
num_files = length(predDS.Files);

% Matrix to store class IoUs for every image
% index 1 = 1mm plate thickness
classIoUs = zeros(length(classes),num_files);

% Create a dictionary mapping defect sizes to an index
curr_idx = 1;
size_map = containers.Map;

% j will be the index to access the current image in the datastores
for j = 1 : num_files
    % convert to plate thickness (jaccard computes over nonzero values)
    targ_img = max_class_val - imread(targDS.Files{j});
    pred_img = max_class_val - imread(predDS.Files{j});
    iou = jaccard(double(pred_img),double(targ_img));
    classIoUs(:,j) = iou;
    
    % map defect size to an index
    filepath = string(targDS.Files{j});
    tokens = strsplit(filepath,'\');
    curr_file = tokens(end);
    tokens = strsplit(curr_file,'_');
    curr_size = tokens(4); % filename pattern: test_drop_1_50_real.png
    if ~size_map.isKey(curr_size)
        size_map(curr_size) = curr_idx;
        curr_idx = curr_idx + 1;
    end
end

% Create matrix to rearrange IoU data
num_ptr = length(classes) - 1;     % number of percent thickness reductions
num_sizes = length(size_map.keys); % number of defect sizes
iou_data = zeros(num_ptr,num_sizes);
    
for j = 1 : num_files
    filepath = string(targDS.Files{j});
    tokens = strsplit(filepath,'\');
    curr_file = tokens(end);
    tokens = strsplit(curr_file,'_');
    curr_thick = tokens(3); % filename pattern: test_drop_1_50_real.png
    curr_size = tokens(4); 
    
    thick_idx = str2num(curr_thick); % coincidence that the defect thickness is equal to its index
    size_idx = size_map(curr_size);
    curr_iou = classIoUs(thick_idx,j); % current defect iou
    
    iou_data(thick_idx,size_idx) = curr_iou;
end

%% Results
thicknesses = flip(codes);
thicknesses(end) = [];
ptrs = thick2ptr(thicknesses,max_class_val); % percent thickness reduction array
sizes = str2num(char(size_map.keys));        % defect size array

% Reorder defect sizes and make table headers
A = [sizes,iou_data'];
A = sortrows(A,1);
iou_data = A';
size_headers = string(iou_data(1,:));
iou_data(1,:) = [];
iou_data = flipud(iou_data);
ptr_cell = num2cell(flipud(ptrs));
row_labels = sprintf("%2.f\\%% ",ptr_cell{:});
row_labels = split(row_labels);
row_labels(end) = [];

% Make table
% T = array2table(iou_data,'VariableNames',size_headers,'RowNames',row_labels);
H = heatmap(size_headers,row_labels,round(iou_data,3));
H.YDisplayLabels = repmat({''}, size(H.YData));  %remove row labels
H.XDisplayLabels = repmat({''}, size(H.XData));  %remove column labels
a2 = axes('Position', H.Position);               %new axis on top
a2.Color = 'none';                               %new axis transparent
a2.YTick = 1:size(H.ColorData,1);                %set y ticks to number of rows
a2.XTick = 1:size(H.ColorData,2);                %set x ticks to number of col
xlim(a2, [0.5, size(H.ColorData,2)+0.5]);        %center x ticks
ylim(a2, [0.5, size(H.ColorData,1)+.5])          %center y ticks
a2.YDir = 'Reverse';                             %flip y axis to correspond with heatmap's
a2.XTickLabel = size_headers;                    %set xtick labels
a2.YTickLabel = row_labels;                      %set ytick labels
a2.TickLabelInterpreter = 'latex';
set(a2.XLabel,'Interpreter','latex');
set(a2.XLabel,'String','Defect characteristic length [mm]');
set(a2.YLabel,'Interpreter','latex');
set(a2.YLabel,'String','Percent thickness reduction (\%)');
set(a2,'TickLength',[0 0]);
% set(a2.Title,'String','Intersection over Union (IoU) at defect');
% set(a2.Title,'Interpreter','latex');
H.Colormap = summer(64);
set(gcf,'color','white');
exportgraphics(gcf,['../output/metrics/','exact_iou','.tif'],'Resolution',300);


%% Other plots
% Percent thickness reduction
% figure()
% hold on
% set(gcf,'color','white')
% for j = 1:size(iou_data,2)
%     plot(ptrs,iou_data(:,j),'-o');
% end
% plot(ptrs,iou_data(:,2),'-o');
% plot(ptrs,iou_data(:,4),'-o');
% plot(ptrs,iou_data(:,1),'-o');
% leg = legend('20 mm', '60 mm', '100 mm');
% set(leg,'Interpreter','latex');
% xlabel('Percent thickness reduction (\%)','Interpreter','latex');
% ylabel('Intersection over union (IoU) at defect','Interpreter','latex');

% Defect size
% figure()
% hold on
% set(gcf,'color','white')
% for i = 1:size(iou_data,1)
%     A = [sizes,iou_data(i,:)'];
%     A = sortrows(A,1);
%     plot(A(:,1), A(:,2),'-o');
% end
% A = [sizes,iou_data(9,:)'];
% A = sortrows(A,1);
% plot(A(:,1), A(:,2),'-o');
% 
% A = [sizes,iou_data(5,:)'];
% A = sortrows(A,1);
% plot(A(:,1), A(:,2),'-o');
% 
% A = [sizes,iou_data(1,:)'];
% A = sortrows(A,1);
% plot(A(:,1), A(:,2),'-o');
% leg = legend('10\%','50\%','90\%');
% set(leg,'Interpreter','latex');
% xlabel('Defect characteristic length (mm)','Interpreter','latex');
% ylabel('Intersection over union (IoU) at defect','Interpreter','latex');

% Average metrics over testset
% seg_metrics = evaluateSemanticSegmentation(predDS,targDS);
% wIoU = weightedIoU(seg_metrics);

% Make figures
% for i = 1 : num_files
%     pred_path = string(predDS.Files(i));
%     targ_path = string(targDS.Files(i));
%     tokens = strsplit(pred_path,'\');
%     pred_file = tokens(end);
%     tokens = strsplit(targ_path,'\');
%     targ_file = tokens(end);
%     make_figures(pred_file,targ_file,c_map);
% end
        
%% FUNCTIONS
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

% Convert defect thickness to percent thickness reduction
function ptr = thick2ptr(thickness,max_class_val)
    ptr = (1 - (thickness/max_class_val))*100;
end