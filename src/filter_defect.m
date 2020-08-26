% Los Alamos Dynamics Summer School (LADSS)
% DeepWaves 8/17/2020
% Matlab function written by: Joshua Eckels (eckelsjd@rose-hulman.edu)
% Helper function to filter out 3D (x,y,z) points outside of main clustered defect region
% Input: x,y,z : column vectors of grid coordinates at one z-value
%        clusters  : number of clusters to pass to kmeans
% Output: xf,yf,zf : column vectors of filtered grid coordinates
function [xf,yf,zf] = filter_defect(x,y,z,clusters)
    points = [x, y];
    [idx,C,sumd,D] = kmeans(points,clusters);
    xf = [];
    yf = [];
    zf = [];

    % Sort out points that are too far from each cluster centroid
    for k = 1:clusters
        xc = points(idx==k,1);
        yc = points(idx==k,2);
        zc = z(idx==k);

        dist = D(idx==k,k);
        avg_dist = mean(dist);
        cluster_idxs = find(dist < 1*avg_dist);

        xc = xc(cluster_idxs);
        yc = yc(cluster_idxs);
        zc = zc(cluster_idxs);

        xf = [xf; xc];
        yf = [yf; yc];
        zf = [zf; zc];

%             figure()
%             plot(xc,yc,'r.','MarkerSize',12);
%             hold on
%             plot(C(:,1),C(:,2),'kx','Markersize',15,'LineWidth',3);
%             plot(xf,yf,'ko','MarkerSize',5);
%             str = sprintf('Cluster %d',k);
%             legend(str,'Centroids','Defect');
%             hold off
    end
end 