% Los Alamos Dynamics Summer School (LADSS)
% DeepWaves 12/27/2020 
% Matlab function written by: Joshua Eckels (eckelsjd@rose-hulman.edu)
% Function to save 4 output wavefield images:
% ../images/real.png                : Image of real part of wavefield surface response
% ../images/imaginary.png           : Image of imaginary part of response
% ../outputs/ground_truth/truth.png : RGB masked image with colorbar
% ../labels/mask.png                : Masked image with class segmentation info
%
% Takes inputs:
% filename                          : (string) displacement data text file (no path)
%
% Optional 'Name', 'Value' pair args:
% Debug                             : Plots intermediate results
% ExportMat                         : Complex-valued displacement matrix
% MakeGif                           : Create optional wavefield gif
% ClassFile                         : File to specify class identifiers
%
% Specify ExportMat=true to generate complex-valued z-displacement matrix for AWS
% processing; see arguments list below. The .txt data input
% file contains the real and imaginary z-displacement values at each external mesh node 
% exported from an ANSYS harmonic response simulation. Default ClassFile is
% "codes.txt". Class file has indexed list of class identifier names.
%
% Known issues:
%   : RGB color list is hard-coded to 10 values; must change if you want to
%     segment images into more than 10 classes (RGB only). Or specify a
%     linear color-scale using 'linspecer.m' function
%   : Grid resolution is hard-coded to 1mm.
%   : Input data must be ANSYS mesh nodes from a rectangular plate centered
%     at the origin. Bottom of plate must be at z=0
%   : Segmentation mask issues. Filtering ANSYS data assumes a ton of extra
%     points were exported at x=0 on 'accident'. Problem with ANSYS ADPL
%     export commands. See 'nsel'. Assume plate surface has the most nodes.
%   : Attempts at filtering out internal wall nodes. See variables
%     'z_tune','max_k','no_defects'. This may not be needed after all, but a couple
%     methods I tried involved using kmeans clustering to get rid of those
%     pesky inside walls.
%
% IF THINGS GO WRONG, here is where to start looking:
%   : ANSYS data given to the script was not properly exported. Check the
%     raw data. It should only contain nodes on external surfaces. (and a
%     ton of extra nodes on the x=0 plane for some reason)
%   : Dealing with those internal wall nodes messed up your segmentation
%     mask
%   : The wrong plate_thickness was chosen using the current naive approach
%   : A defect was present that was not one of the classification classes
%   : z-dilation and rounding will discontinue regression values.
%     CLASSIFICATION ONLY right now at discrete integer values.

function t_final = plot_wavefield(filename,options)
arguments
    filename string
    options.Debug (1,1) logical = false
    options.ExportMat (1,1) logical = false
    options.MakeGif (1,1) logical = false
    options.ClassFile (1,:) string = "codes.txt"
end
tic
%% DEFINE COLORS (classification only)
fd = fopen(options.ClassFile,'r');
codes = fscanf(fd,"%f\n");
fclose(fd);
thick_min = min(codes)*10^(-3); % min plate thickness [mm]
thick_max = max(codes)*10^(-3); % max plate thickness [mm]
num_classes = length(codes);

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
          
% c_map = flip(linspecer(num_classes,'sequential'),1); % generate N linear colors

%% DATA IMPORT
filename = convertCharsToStrings(filename); 
base_file = extractBetween(filename,"","_disp.txt");
resolution = 0.001;     % 1 [mm] grid resolution
tol = 1e-6;             % tolerance for comparing floats
f = 80000;              % 80,000 Hz
% z_tune = 20000;       % help separate z-values for kmeans clustering (testing)
% no_defects = 4;       % hard-coded??? or in filename

% Files imported from ANSYS
data = readtable(['../data/' char(filename)]);
data = table2array(data);

% Label the data columns
% Each column has data for all external ANSYS mesh nodes
x_loc = data(:,2);
y_loc = data(:,3);
z_loc = data(:,4);
z_disp_re = data(:,5); % Z-displacement = harmonic response of each node
z_disp_im = data(:,6); % imaginary part (out-of-plane; z-dir)

%%% ASSUMPTIONS
% rectangular plate aligned with XY plane, centered at (X,Y) = (0,0)
% bottom of plate is at z=0
% Grid resolution is specified: res = mm/grid point
% Surface of plate has most nodes (besides the bottom of the plate)
x_width = 2*max(x_loc);
y_width = 2*max(y_loc);
Nx = x_width/resolution;    % number of X grid points
Ny = y_width/resolution;    % number of Y grid points
% Nx == Ny for square plate
M = mode(z_loc);
if abs(M-0.0) < tol % just in case the bottom of plate had more nodes than the surface
    z_temp = z_loc;
    z_temp(z_temp == M) = NaN;
    M = mode(z_temp); % assume surface has the next most nodes
end
plate_thickness = M; % [mm]
% max_k = 2*plate_thickness/resolution;  % estimate max possible clusters below a defect

if options.Debug % optional plotting
    figure()
    scatter3(x_loc,y_loc,z_loc,'.k');
    title('Raw data');
end

%% FILTER RAW ANSYS EXPORT
% filter out annoying ANSYS nodes at x=0 that got exported erroneously
idx1 = find(x_loc == 0);
% filter transducer nodes
idx2 = find(z_loc > plate_thickness);
% filter nodes on vertical sides of plate
idx3 = find(((z_loc < plate_thickness) & (z_loc > 0)) & ((abs(x_loc) == x_width/2) | (abs(y_loc) == y_width/2)));

del_idxs = [idx1; idx2; idx3];
x_loc(del_idxs) = [];
y_loc(del_idxs) = [];
z_loc(del_idxs) = [];
z_disp_re(del_idxs) = [];
z_disp_im(del_idxs) = [];

if options.Debug
    figure()
    scatter3(x_loc,y_loc,z_loc,'.k');
    title('Filtered data');
end

%% IGNORE THE INTERNAL WALLS. PLEASE. HELP.
% filter internal vertical walls (below defects) using kmeans clustering
% determine optimal number of k clusters
% TRACK 'idxs' starting here to get back to the clean (x_loc,y_loc,z_loc)
% idxs = find( (z_loc<plate_thickness) & (z_loc>0) );
% loc_mat = [x_loc(idxs),y_loc(idxs),z_tune*z_loc(idxs)]; % internal nodes
% eva = evalclusters(loc_mat,'kmeans','CalinskiHarabasz','KList',[1:max_k]);
% [k_idxs,C,sumd,D] = kmeans(loc_mat,eva.OptimalK);
% figure()
% scatter3(loc_mat(:,1),loc_mat(:,2),loc_mat(:,3)/z_tune,10,k_idxs,'filled');
% 
% % defect clusters will have the most nodes in them (could also use sumd)
% k_defects = zeros(no_defects,1); % array to store k index of each defect
% idx_temp = k_idxs;
% for i = 1:no_defects
%     M = mode(idx_temp);
%     k_defects(i) = M;
%     idx_temp(idx_temp == M) = [];
% end
% 
% figure()
% scatter3(loc_mat(k_idxs==k_defects,1),loc_mat(k_idxs==k_defects,2),loc_mat(k_idxs==k_defects,3),'.k');
% title('Defect cluster');
% 
% % Iterate through all clusters; delete non-defect clusters
% del_idxs = [];
% for i = 1:eva.OptimalK
%     if ~ismember(i,k_defects)
%         del_idxs = [del_idxs; find(k_idxs==i)];
%     end
% end
    
%%% CENTROID DELETION METHOD DOESN'T WORK (AND IS DUMB)
% del_idxs = [];
% for i = 1:length(k_defects)
%     curr_cluster = k_defects(i); % current cluster number (k)
%     curr_centroid = C(curr_cluster,:);
%     curr_centroid_x = curr_centroid(1);
%     curr_centroid_y = curr_centroid(2);
%     % Lchar is based on cluster point farthest from its own centroid
%     % D has squared euclidean distances, we want sqrt(x^2 + y^2) distance
%     char_length = sqrt(max(D(k_idxs==curr_cluster,curr_cluster))); % characteristic defect length
%     
%     % Check for clusters that align below the current defect cluster
%     for c = 1:size(C,1)
%         if c == curr_cluster % skip the current defect cluster
%             continue
%         end
%         C_x = C(c,1);   % x-coordinate
%         C_y = C(c,2);   % y-coordinate
%         Cpoints = [C_x, C_y; curr_centroid_x, curr_centroid_y];
%         Cdist = pdist(Cpoints,'euclidean');
%         % determine if this cluster is aligned X,Y with the current defect
%         if (Cdist < char_length)
%             del_idxs = [del_idxs; find(k_idxs==c)];
%         end
%     end
% end
% del_idxs = idxs(sort(del_idxs)); % go back to the original idxs
% 
% figure()
% scatter3(x_loc(del_idxs),y_loc(del_idxs),z_loc(del_idxs),'.k');
% title('internal wall nodes to delete');
% 
% x_loc(del_idxs) = [];
% y_loc(del_idxs) = [];
% z_loc(del_idxs) = [];
% z_disp_re(del_idxs) = [];
% z_disp_im(del_idxs) = [];

% figure()
% scatter3(x_loc,y_loc,z_loc,'.k');
% title('Final filtered node data. At long last.');

%% SEPARATE FILTERED DATA
% Retrieve only surface nodes
idxs_surf = find(abs(z_loc - plate_thickness) < tol);
x_surf = x_loc(idxs_surf)+x_width/2;
y_surf = y_loc(idxs_surf)+y_width/2;
z_surf = z_loc(idxs_surf);
z_disp_re = z_disp_re(idxs_surf);
z_disp_im = z_disp_im(idxs_surf);

% Retrieve all other nodes for segmentation masks
idxs_bottom = find(abs(z_loc-plate_thickness) > tol);
x_bottom = x_loc(idxs_bottom)+x_width/2;
y_bottom = y_loc(idxs_bottom)+y_width/2;
z_bottom = z_loc(idxs_bottom);

% Generate uniform grid
[xq,yq] = meshgrid(linspace(0,x_width,Nx),linspace(0,y_width,Ny));

%% SEGMENTATION MASKS
% Override points with duplicate (X,Y) (keeps point with highest Z value)
% tol = 1e-12; by default
% This has the effect of collapsing defect clusters down to bottom of plate
loc_mat = [x_bottom,y_bottom,z_bottom];
sorted_mat = sortrows(loc_mat,3,'descend'); 
[~,idxs,~] = uniquetol(sorted_mat(:,1:2),'ByRows',true); % tol
x_bottom = sorted_mat(idxs,1);
y_bottom = sorted_mat(idxs,2);
z_bottom = sorted_mat(idxs,3);

% Interpolate to uniform grid for segmentation
z_seg = griddata(x_bottom,y_bottom,z_bottom,xq,yq,'nearest');

% Flip matrix vertically for displaying as image
z_seg = flip(z_seg,1);

% Clean up edges of defect regions (artifact of internal wall clusters)
e = edge(z_seg,'Canny');
e = imdilate(e,strel([0 1 0; 1 1 1; 0 1 0])); % plus-shaped struct element
z_dilate = imdilate(z_seg,strel('disk',4,4));
borders = double(e) .* z_dilate;
z_seg(e) = 0;
z_seg = z_seg + borders;

if options.Debug
    figure()
    surf(xq,yq,z_seg);
end

% Convert to class pixel values: class = max_thick - local_thick
local_thick = plate_thickness - z_seg;
class_seg = thick_max - local_thick;
class_seg = round(1000*class_seg); % integers for classification

% CLASS VALUE LABEL FOR CNN
if contains(base_file,"test_")
    mask_name = ['../test/targets/' char(base_file) '_targ.png'];
    imwrite(uint8(class_seg),mask_name); % convert to 8-bit (0-255)
else
    mask_name = ['../labels/' char(base_file) '_mask.png'];
    imwrite(uint8(class_seg),mask_name); % convert to 8-bit (0-255)
end


% RGB GROUND TRUTH FOR VISUAL COMPARISON
local_thick = round(1000*local_thick);
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
exportgraphics(gca,['../output/ground_truth/',char(base_file),'_targ_rgb.tif'],'Resolution',300);
set(f_seg,'ToolBar','figure');
saveas(gcf,['../output/figs/',char(base_file),'_targ_rgb']);
set(f_seg,'Visible','off');


%%% THIS IDEA IS DUMB (to convert to RGB image)
% % Classification: find and replace each class with desired RGB
% % Regression: Create a linear color map from min to max thickness value
% z_seg_rgb = zeros(Ny,Nx,3); % matrix to hold RGB image
% 
% % Find and replace each class value with the set RGB value
% for i = 1:length(codes)
%     % reset the rgb search matrices
%     red_blank = zeros(size(z_seg)); 
%     green_blank = zeros(size(z_seg)); 
%     blue_blank = zeros(size(z_seg)); 
%     
%     tcurr = codes(i)*10^(-3); % [m]
%     curr_class = (plate_thickness-tcurr)*1000; % [mm]
%     rgb = str2num(colors(tcurr));
%     red_blank( abs(z_seg - curr_class) < tol) = rgb(1);
%     green_blank( abs(z_seg - curr_class) < tol) = rgb(2);
%     blue_blank( abs(z_seg - curr_class) < tol) = rgb(3);
%     
%     z_seg_rgb(:,:,1) = z_seg_rgb(:,:,1) + red_blank;
%     z_seg_rgb(:,:,2) = z_seg_rgb(:,:,2) + green_blank;
%     z_seg_rgb(:,:,3) = z_seg_rgb(:,:,3) + blue_blank;
% end
% mask_name = ['../ground_truth/' char(base_file) '_truth.png'];
% imwrite(uint8(z_seg_rgb),mask_name);

if options.Debug
    figure()
    set(gcf,'color','white');
    imshow(uint8(class_seg),[min_class_val-1 max_class_val-1]);
    title('Class value label mask for CNN');
    set(f,'Visible','on'); % RGB version
end

%% SURFACE RESPONSE WAVEFIELD IMAGES
% Plot surface of plate
if options.Debug
    figure()
    scatter3(x_surf,y_surf,z_surf,'.k')
    title('Plate surface');
end

% Interpolate displacement vectors to uniform grid
vq_im = griddata(x_surf,y_surf,z_disp_im,xq,yq);
vq_re = griddata(x_surf,y_surf,z_disp_re,xq,yq);

% Use mat2gray normalization to [0,1] for each image individually
img_re = mat2gray(vq_re);
img_im = mat2gray(vq_im);

% Save grayscale wavefield images
% Real
img_re = flip(img_re,1);
imwrite(img_re,['../images/' char(base_file) '_real.png']);
% Imaginary
img_im = flip(img_im,1);
imwrite(img_im,['../images/' char(base_file) '_imaginary.png']);

% MAKE COOL WAVEFIELD GIF
if options.MakeGif
    vqz = complex(vq_re,vq_im);
    vq_mag = abs(vqz);
    vq_phi = angle(vqz);
    omega = 2*pi*f;
    t_max = 3*(1/f); % 3 cycles
    f_sample = 20*f; % 20 frames per cycle
    t = 0:1/f_sample:t_max;

    f_gif = figure();
    colormap gray
    max_amplitude = 1.4*max(max(vq_mag)); % dull the colors by factor of 1.4
    clims = [-max_amplitude max_amplitude];
    axis tight manual % this ensures that getframe() returns a consistent size
    gif_file = ['../output/gifs/', char(base_file), '_wavefield.gif'];  
    for i = 1:length(t)
        plot_mat = vq_mag.*sin(omega.*t(i) + vq_phi);
        imagesc([min(x_surf) max(x_surf)],[max(y_surf) min(y_surf)],plot_mat,clims);
        set(gca,'XTick',[]);
        set(gca,'YTick',[]);
        box off
        drawnow
        % Capture the plot as an image 
        frame = getframe; 
        im = frame2im(frame); 
        [imind,cmap] = rgb2ind(im,256); 
        % Write to the GIF File 
        if i == 1 
            imwrite(imind,cmap,gif_file,'gif','DelayTime',0.1, 'Loopcount',inf); 
        else 
            imwrite(imind,cmap,gif_file,'gif','DelayTime',0.1,'WriteMode','append'); 
        end 
    end
    set(f_gif,'Visible','off');
end

% SAVE complex displacement value 400x400 matrix
if options.ExportMat
    mat_file = ['../output/mat/' char(base_file) '_vqz.mat'];
    S.('vq_z') = complex(vq_re,vq_im);
    save(mat_file,'-struct','S');
end

% Plot wavefield images
if options.Debug
    figure()
    subplot(1,2,1)
    imagesc([min(x_surf) max(x_surf)],[max(y_surf) min(y_surf)],vq_re)
    title('Real wavefield')
    colormap gray
    colorbar
    subplot(1,2,2);
    imagesc([min(x_surf) max(x_surf)],[max(y_surf) min(y_surf)],vq_im)
    title('Imaginary wavefield')
    colormap gray
    colorbar
end
t_final = toc;
fprintf("Final time = %6.4f s\n",t_final);

end