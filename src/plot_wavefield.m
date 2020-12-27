% Los Alamos Dynamics Summer School (LADSS)
% DeepWaves 8/17/2020
% Matlab function written by: Joshua Eckels (eckelsjd@rose-hulman.edu)
% Function to save 4 output wavefield images:
% ../images/real.png        : Image of real part of wavefield surface response
% ../images/imaginary.png   : Image of imaginary part of response
% ../images/magnitude.png   : Image of magnitude of surface response
% ../labels/mask.png        : Masked image with class segmentation info
%
% Takes inputs:
% filename_real             : (string) real data text file (no path)
% filename_imag             : (string) imaginary data text file (no path)
% mode                      : "gray"=grayscale mask, "color"=RGB ground truth mask
%                             "default"=class codes (use for CNN input)
%                             "no_mask"=don't generate masks
% norm                      : [amin_re,amax_re,amin_im,amax_im,amin_mag,amax_mag] -> do batch
%                              normalization with these absolute max and min values
%                           : [] -> empty means don't do batch normalization
%
% Function can also generate complex-valued z-displacement matrix for AWS
% processing; find the associated lines and UNCOMMENT. The .txt data input
% files are the real and imaginary z-displacement values at each mesh node 
% exported from an Ansys harmonic response simulation.
%
% Known issues:
%   : Deeply dependent on format of filename (see Data import)
%   : Must contain thickness of defect in filename (such as "_3_" for 3mm)
%     to properly generate segmentation masks. This also means that you
%     should not include anything in the filename like "_3_" if it is not a
%     defect thickness
%   : Auto-segmentation mask creation assumes there is only one main
%     cluster defect at each thickness value (uses kmeans clustering)
%   : Must call "batch_norm.m" function to get array for batch
%     normalization
%   : Expects both real and imaginary filenames to be passed in and to have
%     the exact same format (redundant)
%   : RGB color list is hard-coded to 10 values; must change if you want to
%     segment images into more than 10 classes (RGB only). For 'default'
%     segmentation masks, this is not a problem.

% function [] = plot_wavefield(filename,seg_mode)
clear all; close all;clc;
filename="disp.txt";
seg_mode="no_mask";
tic
%% DEFINE COLORS (classification only)
colors = containers.Map('KeyType','double','ValueType','char');
color_list = [0,0,127; % 10mm = blue
              0,0,255;
              0,127,255;
              0,255,255;
              62,255,191;
              191,255,62;
              255,255,0;
              255,127,0;
              255,0,0;
              127,0,0]; % 1mm = red
          
% Set class values of each thickness from codes.txt
fd = fopen('codes.txt','r');
codes = fscanf(fd,"%f\n");
fclose(fd);
for i = 1:length(codes)
    colors(codes(i)*10^(-3)) = num2str(color_list(i,:));     % RGB
end

%% DATA IMPORT
% Make sure input data is of the right data type
filename = convertCharsToStrings(filename); 
base_file = extractBetween(filename,"",".txt");
seg_mode = convertCharsToStrings(seg_mode); % string
resolution = 0.001;     % 1 [mm] grid resolution
precision = 4;          % 6 digits of rounding
z_tune = 20000;           % help separate z-values for kmeans clustering (testing)
no_defects = 4;         % hard-coded??? or in filename
f = 80000;              % 80,000 Hz
tol = 1e-6;             % tolerance for comparing floats
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
plate_thickness = M;
max_k = 2*plate_thickness/resolution;  % estimate max possible clusters below a defect

figure()
scatter3(x_loc,y_loc,z_loc,'.k');
title('Raw data');

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

figure()
scatter3(x_loc,y_loc,z_loc,'.k');
title('Easy filters');

% filter internal vertical walls (below defects) using kmeans clustering
% determine optimal number of k clusters
% TRACK 'idxs' starting here to get back to the clean (x_loc,y_loc,z_loc)
idxs = find( (z_loc<plate_thickness) & (z_loc>0) );
loc_mat = [x_loc(idxs),y_loc(idxs),z_tune*z_loc(idxs)]; % internal nodes
eva = evalclusters(loc_mat,'kmeans','CalinskiHarabasz','KList',[1:max_k]);
[k_idxs,C,sumd,D] = kmeans(loc_mat,eva.OptimalK);
figure()
scatter3(loc_mat(:,1),loc_mat(:,2),loc_mat(:,3)/z_tune,10,k_idxs,'filled');

% defect clusters will have the most nodes in them (could also use sumd)
k_defects = zeros(no_defects,1); % array to store k index of each defect
idx_temp = k_idxs;
for i = 1:no_defects
    M = mode(idx_temp);
    k_defects(i) = M;
    idx_temp(idx_temp == M) = [];
end

% figure()
% scatter3(loc_mat(k_idxs==k_defects,1),loc_mat(k_idxs==k_defects,2),loc_mat(k_idxs==k_defects,3),'.k');
% title('Defect cluster');

% Iterate through all clusters; delete non-defect clusters
del_idxs = [];
for i = 1:eva.OptimalK
    if ~ismember(i,k_defects)
        del_idxs = [del_idxs; find(k_idxs==i)];
    end
end
    
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
del_idxs = idxs(sort(del_idxs)); % go back to the original idxs

figure()
scatter3(x_loc(del_idxs),y_loc(del_idxs),z_loc(del_idxs),'.k');
title('internal wall nodes to delete');

x_loc(del_idxs) = [];
y_loc(del_idxs) = [];
z_loc(del_idxs) = [];
z_disp_re(del_idxs) = [];
z_disp_im(del_idxs) = [];

figure()
scatter3(x_loc,y_loc,z_loc,'.k');
title('Final filtered node data');

%% SEPARATE FILTERED DATA
% Retrieve only surface nodes
temp_thick = round(plate_thickness,precision); % mm precision
idxs_surf = find(z_loc == temp_thick); % Real
x_surf = x_loc(idxs_surf)+x_width/2;
y_surf = y_loc(idxs_surf)+y_width/2;
z_surf = z_loc(idxs_surf);
z_disp_re = z_disp_re(idxs_surf);
z_disp_im = z_disp_im(idxs_surf);

% Retrieve all other nodes for seg masks
idxs_bottom = find(z_loc ~= temp_thick);
x_bottom = x_loc(idxs_bottom)+x_width/2;
y_bottom = y_loc(idxs_bottom)+y_width/2;
z_bottom = z_loc(idxs_bottom);

% Generate uniform grid
xmesh = linspace(0,x_width,Nx);
ymesh = linspace(0,y_width,Ny);
[xq,yq] = meshgrid(xmesh,ymesh);

%% SEGMENTATION MASKS
% Plot bottom of plate (with defects)
figure()
scatter3(x_bottom,y_bottom,z_bottom,'.k')

% Override points with duplicate (X,Y) (default to highest Z value)
% tol = 1e-12; by default
loc_mat = [x_bottom,y_bottom,z_bottom];
sorted_mat = sortrows(loc_mat,3,'descend'); 
[~,idxs,~] = uniquetol(sorted_mat(:,1:2),'ByRows',true); % tol
x_bottom = sorted_mat(idxs,1);
y_bottom = sorted_mat(idxs,2);
z_bottom = sorted_mat(idxs,3);

% Interpolate to uniform grid for segmentation
z_seg = griddata(x_bottom,y_bottom,z_bottom,xq,yq,'nearest');

% Invert from defect height to plate thickness
% mask = zeros(Ny,Nx) | z_seg;
% z_seg = (plate_thickness - z_seg) .* mask;

% Convert to mm (round for classification, later regression won't round)
z_seg = flip(round(1000*z_seg),1);

% Replace (0,0,0) pixels with correct plate thickness
plate_class = (codes(1)*10^(-3) - plate_thickness)*1000;
z_seg( abs(z_seg-0.0) < tol ) = plate_class;

% defect z-val corresponds to pixel value; i.e. 1mm = 9mm height = (9,9,9)
% eventually move to actual thickness = class value (regression-ish)
figure()
surf(xq,yq,z_seg);

% GROUND TRUTH LABEL FOR CNN
mask_name = ['../labels/' char(base_file) '_mask.png'];
imwrite(uint8(z_seg),mask_name); % convert to 8-bit (0-255)

% RGB GROUND TRUTH FOR VISUAL COMPARISON
% Classification: find and replace each class with desired RGB
% Regression: Create a linear color map from min to max thickness value
z_seg_rgb = zeros(Ny,Nx,3); % matrix to hold RGB image

% Find and replace each class value with the set RGB value
for i = 1:length(codes)
    % reset the rgb search matrices
    red_blank = zeros(size(z_seg)); 
    green_blank = zeros(size(z_seg)); 
    blue_blank = zeros(size(z_seg)); 
    
    tcurr = codes(i)*10^(-3); % [m]
    curr_class = (plate_thickness-tcurr)*1000; % [mm]
    rgb = str2num(colors(tcurr));
    red_blank( abs(z_seg - curr_class) < tol) = rgb(1);
    green_blank( abs(z_seg - curr_class) < tol) = rgb(2);
    blue_blank( abs(z_seg - curr_class) < tol) = rgb(3);
    
    z_seg_rgb(:,:,1) = z_seg_rgb(:,:,1) + red_blank;
    z_seg_rgb(:,:,2) = z_seg_rgb(:,:,2) + green_blank;
    z_seg_rgb(:,:,3) = z_seg_rgb(:,:,3) + blue_blank;
end

mask_name = ['../ground_truth/' char(base_file) '_truth.png'];
imwrite(uint8(z_seg_rgb),mask_name);

%% SURFACE RESPONSE WAVEFIELD IMAGES
% Plot surface of plate
% figure()
% scatter3(x_surf,y_surf,z_surf,'.k')

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

% % UNCOMMENT TO MAKE COOL WAVEFIELD GIF
% vqz = complex(vq_re,vq_im);
% vq_mag = abs(vqz);
% vq_phi = angle(vqz);
% omega = 2*pi*f;
% t_max = 3*(1/f); % 3 cycles
% f_sample = 20*f; % 20 frames per cycle
% t = 0:1/f_sample:t_max;
%     
% figure()
% colormap gray
% max_amplitude = 1.4*max(max(vq_mag)); % dull the colors by factor of 1.4
% clims = [-max_amplitude max_amplitude];
% axis tight manual % this ensures that getframe() returns a consistent size
% gif_file = ['../gifs/', char(base_file), '_wavefield.gif'];  
% for i = 1:length(t)
%     plot_mat = vq_mag.*sin(omega.*t(i) + vq_phi);
%     imagesc([min(x_surf) max(x_surf)],[max(y_surf) min(y_surf)],plot_mat,clims);
%     set(gca,'XTick',[]);
%     set(gca,'YTick',[]);
%     box off
%     drawnow
%     % Capture the plot as an image 
%     frame = getframe; 
%     im = frame2im(frame); 
%     [imind,cmap] = rgb2ind(im,256); 
%     % Write to the GIF File 
%     if i == 1 
%         imwrite(imind,cmap,gif_file,'gif','DelayTime',0.1, 'Loopcount',inf); 
%     else 
%         imwrite(imind,cmap,gif_file,'gif','DelayTime',0.1,'WriteMode','append'); 
%     end 
% end

% UNCOMMENT to save complex displacement value 400x400 matrix
% mat_file = ['../mat/' char(base_file) '_vqz.mat'];
% S.('vq_z') = complex(vq_re,vq_im);
% save(mat_file,'-struct','S');

% UNCOMMENT to plot wavefield images
% figure()
% imagesc([min(x_surf) max(x_surf)],[max(y_surf) min(y_surf)],vq_re)
% set(gca,'Visible','off')
% title('Real')
% colormap gray
% colorbar
% figure()
% imagesc([min(x_surf) max(x_surf)],[max(y_surf) min(y_surf)],vq_im)
% set(gca,'Visible','off')
% title('Imaginary')
% colormap gray
% colorbar

fprintf("Final time = %6.4f s\n",toc);

% end