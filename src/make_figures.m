% INPUT files come from test/targets and test/predictions folders
% OUTPUT files go to ouput/targets and output/predictions folders
% Pass in a color map with RGB values on range [0 1]
% pred_file = 'test_example_pred.png'
% targ_file = 'test_example_targ.png'
function make_figures(pred_file,targ_file,c_map)
    % codes.txt has all plate thickness classes mapped to indices 0:num_classes
    fd = fopen('codes.txt','r');
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
    % exportgraphics(gca,['../output/targets/',char(base_file),'_targ.tif'],'Resolution',300);
    exportgraphics(gca,['../output/targets/',char(base_file),'_targ.png']);
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
    % exportgraphics(gca,['../output/predictions/',char(base_file),'_pred.tif'],'Resolution',300);
    exportgraphics(gca,['../output/predictions/',char(base_file),'_pred.png']);
    set(f_seg,'ToolBar','figure');
    saveas(gcf,['../output/figs/',char(base_file),'_pred']);
    set(f_seg,'Visible','off');
end