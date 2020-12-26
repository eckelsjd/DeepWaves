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
%% DATA IMPORT
% Make sure input data is of the right data type
filename = convertCharsToStrings(filename); 
seg_mode = convertCharsToStrings(seg_mode); % string
resolution = 0.001;     % 1 [mm] grid resolution
precision = 6;          % 6 digits of rounding
z_tune = 1000;          % help separate z-values for kmeans clustering (testing)
no_defects = 1;         % hard-coded??? or in filename
max_k = no_defects*10;  % estimate 10 possible clusters per defect for vertical walls

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
if M == 0 % just in case the bottom of plate had more nodes than the surface
    z_temp = z_loc;
    z_temp(z_temp == M) = NaN;
    M = mode(z_temp); % assume surface has the next most nodes
end
plate_thickness = M;

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

% filter internal vertical walls (below defects) using kmeans clustering
% determine optimal number of k clusters
% TRACK 'idxs' starting here to get back to the clean (x_loc,y_loc,z_loc)
idxs = find( (z_loc<plate_thickness) & (z_loc>0) );
loc_mat = [x_loc(idxs),y_loc(idxs),z_tune*z_loc(idxs)]; % internal nodes
eva = evalclusters(loc_mat,'kmeans','CalinskiHarabasz','KList',[1:max_k]);
[k_idxs,C,sumd,D] = kmeans(loc_mat,eva.OptimalK);

% defect clusters will have the most nodes in them (could also use sumd)
k_defects = zeros(no_defects,1); % array to store k index of each defect
idx_temp = k_idxs;
for i = 1:no_defects
    M = mode(idx_temp);
    k_defects(i) = M;
    idx_temp(idx_temp == M) = [];
end

% Iterate through all defect clusters
del_idxs = [];
for i = 1:length(k_defects)
    curr_cluster = k_defects(i); % current cluster number (k)
    curr_centroid = C(curr_cluster,:);
    curr_centroid_x = curr_centroid(1);
    curr_centroid_y = curr_centroid(2);
    % Lchar is the cluster point farthest from its own centroid
    char_length = max(D(k_idxs==curr_cluster,curr_cluster)); % characteristic defect length
    
    % Check for clusters that align below the current defect cluster
    for c = 1:size(C,1)
        if c == i % skip the current defect cluster
            continue
        end
        C_x = C(c,1);   % x-coordinate
        C_y = C(c,2);   % y-coordinate
        % determine if this cluster is aligned X,Y with the current defect
        if ( (abs(C_x - curr_centroid_x) < char_length) && (abs(C_y - curr_centroid_y) < char_length) )
            del_idxs = [del_idxs; find(k_idxs==c)];
        end
    end
end
del_idxs = idxs(sort(del_idxs)); % go back to the original idxs
x_loc(del_idxs) = [];
y_loc(del_idxs) = [];
z_loc(del_idxs) = [];
z_disp_re(del_idxs) = [];
z_disp_im(del_idxs) = [];

figure()
scatter3(x_loc,y_loc,z_loc,'.k');

% Define grid
xmesh = linspace(0,x_width,Nx);
ymesh = linspace(0,y_width,Ny);
[xq,yq] = meshgrid(xmesh,ymesh);

%% SEGMENTATION MASKS

%% SURFACE RESPONSE WAVEFIELD IMAGES
% Retrieve only surface nodes
temp_thick = round(plate_thickness,precision); % mm precision
idxs_surf = find(z_loc == temp_thick); % Real
x_surf = x_loc(idxs_surf)+x_width/2;
y_surf = y_loc(idxs_surf)+y_width/2;
z_surf = z_loc(idxs_surf);
z_disp_re = z_disp_re(idxs_surf);
z_disp_im = z_disp_im(idxs_surf);

% % Plot surface of plate
figure()
scatter3(x_surf,y_surf,z_surf,'.k')

% Interpolate displacement vector to uniform grid
% % vq_im = griddata(x_im,y_im,z_disp_im,xq,yq);
% % vq_re = griddata(x_surf,y_re,z_disp_re,xq,yq);
% % vq_mag = sqrt(vq_im.^2 + vq_re.^2);
% % 
% % UNCOMMENT to save complex displacement value 400x400 matrix
% % filename = extractBetween(filename_real,"","_real.txt");
% % filename = ['../mat/' char(filename) '_vqz.mat'];
% % S.('vq_z') = complex(vq_re,vq_im);
% % save(filename,'-struct','S');
% % 
% % % Plot interpolated wavefields
% % figure()
% % imagesc([min(x_im) max(x_im)],[max(y_im) min(y_im)],vq_im)
% % set(gca,'Visible','off')
% % title('Imaginary')
% % colormap gray
% % colorbar
% % 
% % figure()
% % imagesc([min(x_re) max(x_re)],[max(y_re) min(y_re)],vq_re)
% % set(gca,'Visible','off')
% % title('Real')
% % colormap gray
% % colorbar
% % 
% % Normalization
% % if ~isempty(norm)
% %     Batch max and min displacement values
% %     min_re = norm(1);
% %     max_re = norm(2);
% %     min_im = norm(3);
% %     max_im = norm(4);
% %     min_mag = norm(5);
% %     max_mag = norm(6);
% %     
% %     img_re = mat2gray(vq_re,[min_re,max_re]);
% %     img_im = mat2gray(vq_im,[min_im,max_im]);
% %     img_mag = mat2gray(vq_mag,[min_mag,max_mag]);
% % else
% %     Use mat2gray normalization to [0,1] for each image individually
% %     img_re = mat2gray(vq_re);
% %     img_im = mat2gray(vq_im);
% %     img_mag = mat2gray(vq_mag);
% % end
% % 
% % Save grayscale wavefield images
% % Real
% % img_re = flip(img_re,1);
% % img_name = extractBetween(filename_real,"","_real.txt");
% % imwrite(img_re,['../images/' char(img_name) '_real.png']);
% % Imaginary
% % img_im = flip(img_im,1);
% % img_name = extractBetween(filename_imag,"","_imaginary.txt");
% % imwrite(img_im,['../images/' char(img_name) '_imaginary.png']);
% % Magnitude
% % img_mag = flip(img_mag,1);
% % img_name = extractBetween(filename_imag,"","_imaginary.txt");
% % imwrite(img_mag,['../images/' char(img_name) '_magnitude.png']);
% % 
% % fprintf("Final time = %6.4f s\n",toc);

% end