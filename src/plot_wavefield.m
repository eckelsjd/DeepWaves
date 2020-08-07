% Function to save 3 output images:
% ../images/real.png        : Image of real part of wavefield surface response
% ../images/imaginary.png   : Image of imaginary part of response
% ../labels/mask.png        : Masked image with class segmentation info
% Takes inputs:
% filename_real             : string of real data text file (no path)
% filename_imag             : string of imaginary data text file (no path)
% mode                      : visual=see defects, default=class codes
%                           : no_mask=don't generate masks
% norm                      : [amin_re,amax_re,amin_im,amax_im] -> do batch
%                              normalization with these max and min values
%                           : [] -> empty means don't do batch normalization
function [] = plot_wavefield(filename_real,filename_imag,mode,norm)
tic
%% DATA IMPORT
% Get parameters from filename
% filename_real = 'rd1_square_or1_6_2_4_8_real.txt';
% filename_imag = 'rd1_square_or1_6_2_4_8_imaginary.txt';

% Make sure input data is of the right data type
filename_real = convertCharsToStrings(filename_real); % string
filename_imag = convertCharsToStrings(filename_imag); % string
mode = convertCharsToStrings(mode); % string
norm = cell2mat(norm); % numeric array

tokens = split(filename_real,'_');
if strcmp(tokens{1},'rd6') || strcmp(tokens{1},'rd7')
    plate_thickness = str2num(tokens{2})*10^(-3); % [m]
else
    plate_thickness = 0.01; % 10 mm for all other cases
end

% Constants
plate_width = 0.4; % [m]
N_grid = 400; % Uniform grid resolution (and # of pixels)

% Files imported from ANSYS
data1 = readtable(['../data/' char(filename_real)]);
data2 = readtable(['../data/' char(filename_imag)]);
data_re = table2array(data1);
data_im = table2array(data2);

% Label the data columns
% Each column has data for every mesh node point from ANSYS
x_re = data_re(:,2); % real
y_re = data_re(:,3);
z_re = data_re(:,4);
z_disp_re = data_re(:,5); % Z-displacement = harmonic response of each node

x_im = data_im(:,2); % imaginary
y_im = data_im(:,3);
z_im = data_im(:,4);
z_disp_im = data_im(:,5);

% Define grid
xmesh = linspace(0,plate_width,N_grid);
ymesh = linspace(0,plate_width,N_grid);
[xq,yq] = meshgrid(xmesh,ymesh);

%% GENERATE SEGMENTATION MASK
if strcmp(mode,'no_mask')
    % do nothing
else
    % Set class values of each thickness from codes.txt
    fd = fopen('codes.txt','r');
    codes = fscanf(fd,"%f\n");
    fclose(fd);
    colors = containers.Map('KeyType','double','ValueType','uint8');
    color_interval = floor(255/length(codes));
    for i = 1:length(codes)
        % Store the index of the plate thickness
        if codes(i)*10^-3 == plate_thickness
            plate_idx = i;
        end
        
        if strcmp(mode,'visual')
            colors(codes(i)*10^(-3)) = color_interval*(i-1);
        elseif strcmp(mode,'default')
            colors(codes(i)*10^(-3)) = i-1; % colors = class values
        else
            % do nothing
        end
    end
    
    % Store separate mask for each thickness in "sheets" of a 3D matrix
    masks = uint8(ones(length(xq),length(xq),length(codes)-plate_idx)) * colors(plate_thickness);
    P_grid = [xq(:), yq(:)];  % vectorize (x,y) uniform grid points

    % Mask each thickness separately (not the plate thickness)
    % plate thickness should be at codes(plate_idx)
    for i = plate_idx+1:length(codes)
        str = sprintf("_%d_",codes(i)); % check if this thickness is present in filename
        if contains(filename_real,str)
            t_curr = codes(i)*10^(-3); % plate thickness [mm]
            mask = uint8(ones(length(xq))) * colors(plate_thickness);

            % only take ANSYS mesh points at current thickness
            temp = round(plate_thickness-t_curr,3); % mm precision
            t_idx = find(z_im==temp);     
            t_x = x_im(t_idx)+plate_width/2;   % Put lower left corner of plate at origin
            t_y = y_im(t_idx)+plate_width/2;
            t_z = z_im(t_idx);

            % Gets rid of node points that are too far away from the main cluster
            [t_xf,t_yf,t_zf] = filter_defect(t_x,t_y,t_z,1);
%                 figure()
%                 plot(t_xf,t_yf,'.k')

            PQ_grid = [t_xf, t_yf]; % query points in defect; (x,y)

            % Look for closest uniform grid points to all query defect points
            k = dsearchn(P_grid, PQ_grid); % Maps mesh node points to a uniform grid

            % Fill in the mask image
            for j=1:length(k)
                % k(i) gives the index into the uniform mesh grid
                closest_point_x = P_grid(k(j),1);
                closest_point_y = P_grid(k(j),2);

                row = find(ymesh==closest_point_y);
                col = find(xmesh==closest_point_x);

                mask(row,col) = 255;
            end
        else
            continue; % skip this thickness if it is not present
        end
            
        % Do blurring and edge detection to fill in holes
        % blur = imgaussfilt(mask,0.1);
    %         figure()
    %         imshow(mask);
        mask = imfill(mask);
    %         imshow(mask);
        e = edge(mask,'Canny');
        mask = (mask | e);
        mask = imfill(mask,'holes');
    %         imshow(mask);
        e = edge(mask);
        mask = (mask | e);
        mask = imfill(mask,'holes');
    %         imshow(mask);
        mask = uint8(mask) * colors(t_curr);
        masks(:,:,i-plate_idx) = flip(mask,1);
    end
    
    % Combine all thickness masks into one image.
    % Start at next smaller thickness from plate thickness
    % Overwrite pixels from previous thicknesses as thickness decreases
    final_mask = masks(:,:,1);
    for i = plate_idx+1:length(codes)-1
        % k = length(codes) - i;
        next = ~(final_mask & masks(:,:,i));
        final_mask = (final_mask .* uint8(next)) + masks(:,:,i);
    end
    % Save mask
    mask_name = extractBetween(filename_real,"","_real.txt");
    mask_name = ['../labels/' char(mask_name) '_mask.png'];
    imwrite(final_mask,mask_name);
end

% %% SURFACE RESPONSE WAVEFIELD IMAGES
% % Retrieve only surface nodes
% temp = round(plate_thickness,3); % mm precision
% idxs_re = find(z_re == temp); % Real
% x_re = x_re(idxs_re)+plate_width/2;
% y_re = y_re(idxs_re)+plate_width/2;
% z_re = z_re(idxs_re);
% z_disp_re = z_disp_re(idxs_re);
% 
% idxs_im = find(z_im == temp); % Imaginary
% x_im = x_im(idxs_im)+plate_width/2;
% y_im = y_im(idxs_im)+plate_width/2;
% z_im = z_im(idxs_im);
% z_disp_im = z_disp_im(idxs_im);
% 
% % % Plot surface of plate
% % figure()
% % scatter3(x_im,y_im,z_im,'.k')
% 
% % Interpolate displacement vector to uniform grid
% vq_im = griddata(x_im,y_im,z_disp_im,xq,yq);
% vq_re = griddata(x_re,y_re,z_disp_re,xq,yq);
% vq_mag = sqrt(vq_im.^2 + vq_re.^2);
% % filename = extractBetween(filename_real,"","_real.txt");
% % filename = [char(filename) '_vqz.mat'];
% % S.('vq_z') = complex(vq_re,vq_im);
% % save(filename,'-struct','S');
% 
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
% 
% % Normalization
% if ~isempty(norm)
%     % Batch max and min displacement values
%     min_re = norm(1);
%     max_re = norm(2);
%     min_im = norm(3);
%     max_im = norm(4);
%     min_mag = norm(5);
%     max_mag = norm(6);
%     
%     img_re = mat2gray(vq_re,[min_re,max_re]);
%     img_im = mat2gray(vq_im,[min_im,max_im]);
%     img_mag = mat2gray(vq_mag,[min_mag,max_mag]);
% else
%     % Use mat2gray normalization to [0,1] for each image individually
%     img_re = mat2gray(vq_re);
%     img_im = mat2gray(vq_im);
%     img_mag = mat2gray(vq_mag);
% end
% 
% % Save grayscale wavefield images
% % Real
% img_re = flip(img_re,1);
% img_name = extractBetween(filename_real,"","_real.txt");
% imwrite(img_re,['../images/' char(img_name) '_real.png']);
% % Imaginary
% img_im = flip(img_im,1);
% img_name = extractBetween(filename_imag,"","_imaginary.txt");
% imwrite(img_im,['../images/' char(img_name) '_imaginary.png']);
% % Magnitude
% img_mag = flip(img_mag,1);
% img_name = extractBetween(filename_imag,"","_imaginary.txt");
% imwrite(img_mag,['../images/' char(img_name) '_magnitude.png']);

fprintf("Final time = %6.4f s\n",toc);

end