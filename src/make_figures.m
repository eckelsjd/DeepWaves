% make_figures.m
% Author: Joshua Eckels (eckelsjd@rose-hulman.edu)
% Date: 1/20/21
% Purpose: Helper function called by get_results.m to make colored figures
%          for target and prediction segmentation maps
% Usage:
% INPUT files come from test/targets and test/predictions folders
% OUTPUT files go to ouput/targets and output/predictions folders
%        Also creates .figs in output/figs
% Pass in a color map with RGB values on range [0 1]
% pred_file = 'test_example_pred.png'
% targ_file = 'test_example_targ.png'
%
% Optional:
%    options.Colorbar - generate figures with colorbars (default=false)

function make_figures(pred_file,targ_file,c_map,options)
    arguments
        pred_file string
        targ_file string
        c_map (:,3) double
        options.Colorbar (1,1) logical = true
        options.ClassFile (:,1) string = "codes.txt"
    end
    fprintf("Processing: %s and %s",pred_file,targ_file);
    
    % codes.txt has all plate thickness classes mapped to indices 0:num_classes
    fd = fopen(options.ClassFile,'r');
    codes = fscanf(fd,"%f\n");
    fclose(fd);
    testDir = '../test/';
    targetDir = [testDir,'targets/'];
    predDir = [testDir,'predictions/'];

    % set up colorbar parameters
    label = [0, flip(codes)']; % colorbar tick labels (classes)
    labelChar = strsplit(sprintf('%d ',label));
    labelChar(end) = [];
    min_class_val = min(codes);
    max_class_val = max(codes);
    inc = abs(codes(1)-codes(2)); % color bar increment

    pred_path = string([predDir,char(pred_file)]);
    targ_path = string([targetDir,char(targ_file)]);
    tokens = strsplit(pred_path,'/');
    file = tokens(end);
    base_file = extractBetween(file,"","_pred.png");

    % read the target image into matrix
    targ_classes = imread(targ_path);
    targ_thickness = max_class_val - targ_classes;

    % read the prediction image into matrix
    pred_classes = imread(pred_path); 
    pred_thickness = max_class_val - pred_classes; 

    % Make figures
    clf('reset')
    imshow(uint8(targ_thickness),'DisplayRange',[min_class_val max_class_val],'Colormap',c_map);
    
    if options.Colorbar
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
    end
    
    set(gcf,'ToolBar','none'); % annoying pop-up toolbar
    exportgraphics(gca,['../output/targets/',char(base_file),'_targ.tif'],'Resolution',300);
%     exportgraphics(gca,['../output/targets/',char(base_file),'_targ.png']);

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
    set(gcf,'ToolBar','figure');
%     saveas(gcf,['../output/figs/',char(base_file),'_targ']);

    clf('reset')
    imshow(uint8(pred_thickness),'DisplayRange',[min_class_val max_class_val],'Colormap',c_map);
    if options.Colorbar
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
    end
    
    set(gcf,'ToolBar','none'); % annoying pop-up toolbar
    exportgraphics(gca,['../output/predictions/',char(base_file),'_pred.tif'],'Resolution',300);
    % exportgraphics(gca,['../output/predictions/',char(base_file),'_pred.png']);
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
    set(gcf,'ToolBar','figure');
%     saveas(gcf,['../output/figs/',char(base_file),'_pred']);
end