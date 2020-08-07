function norm = norm_batch(re_files,im_files)

    plate_thickness=0.01;
    plate_width=0.04;
    N_grid=400;
    
    min_re_values = zeros(1,length(re_files));
    max_re_values = zeros(1,length(re_files));
    
    min_im_values = zeros(1,length(im_files));
    max_im_values = zeros(1,length(im_files));
    
    min_mag_values = zeros(1,length(im_files));
    max_mag_values = zeros(1,length(im_files));
    
    parfor i=1:length(re_files)
        filename_real = re_files(i);
        filename_imag = im_files(i);
        
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
        
        % Retrieve only surface nodes
        idxs_re = find(z_re == plate_thickness); % Real
        x_re = x_re(idxs_re)+plate_width/2;
        y_re = y_re(idxs_re)+plate_width/2;
        z_re = z_re(idxs_re);
        z_disp_re = z_disp_re(idxs_re);

        idxs_im = find(z_im == plate_thickness); % Imaginary
        x_im = x_im(idxs_im)+plate_width/2;
        y_im = y_im(idxs_im)+plate_width/2;
        z_im = z_im(idxs_im);
        z_disp_im = z_disp_im(idxs_im);

        % Interpolate displacement vector to uniform grid
        vq_im=griddata(x_im,y_im,z_disp_im,xq,yq);
        vq_re=griddata(x_re,y_re,z_disp_re,xq,yq);
        vq_mag = sqrt(vq_im.^2 + vq_re.^2);
        
        % Save max and min displacement values from each image
        min_re_values(i)=min(min(vq_re));
        max_re_values(i)=max(max(vq_re));
        
        min_im_values(i)=min(min(vq_im));
        max_im_values(i)=max(max(vq_im));
        
        min_mag_values(i)=min(min(vq_mag));
        max_mag_values(i)=max(max(vq_mag));
    end
    
    % Return absolute max and min displacements in whole dataset
    amin_re=min(min_re_values);
    amax_re=max(max_re_values);
    
    amin_im=min(min_im_values);
    amax_im=max(max_im_values);
    
    amin_mag=min(min_mag_values);
    amax_mag=max(max_mag_values);
    
    norm = [amin_re,amax_re,amin_im,amax_im,amin_mag,amax_mag];

end