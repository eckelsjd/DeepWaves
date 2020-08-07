%% HELPER FUNCTIONS
% Function to filter out 3D (x,y,z) points outside of main clustered defect region
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
        cluster_idxs = find(dist < 2.5*avg_dist);

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
    
%     % ROUND 1
%     if strcmp(round,'rd1')
%         % Determine if there are multiple thicknesses present
%         bool = has_mult_thicknesses(filename);
%         
%         % Multiple thicknesses present in plate; use k=2 clusters
%         if bool
%             [idx,C,sumd,D] = kmeans(points,2);
% 
%             % Defect cluster will have the greatest sumd metric (more points)
%             [~,max_cluster] = max(sumd);
% 
%             % Sort out only the points belonging to the max cluster
%             xf = points(idx==max_cluster,1);
%             yf = points(idx==max_cluster,2);
%             zf = z(idx==max_cluster);
% 
%             % Sort out points that are too far from the max cluster centroid
%             D = D(idx==max_cluster,max_cluster);
%             avg_dist = mean(D);
%             defect_idxs = find(D < 2.5*avg_dist);
% 
%             xf = xf(defect_idxs);
%             yf = yf(defect_idxs);
%             zf = zf(defect_idxs);
% 
%     %         x1 = points(idx==1,1);
%     %         y1 = points(idx==1,2);
%     %         x2 = points(idx==2,1);
%     %         y2 = points(idx==2,2);
%     %         figure()
%     %         plot(x1,y1,'r.','MarkerSize',12);
%     %         hold on
%     %         plot(x2,y2,'b.','MarkerSize',12);
%     %         plot(C(:,1),C(:,2),'kx','Markersize',15,'LineWidth',3);
%     %         plot(xf,yf,'ko','MarkerSize',5);
%     %         legend('Cluster 1','Cluster 2','Centroids','Defect');
%     %         hold off
% 
%         % If there is only 1 defect thickness present, use k=4 clusters
%         else
%             
%         end
%         
%     % ROUND 2
%     elseif strcmp(round,'rd2') || strcmp(round,'rd3') || strcmp(round,'test')
%         [idx,C,sumd,D] = kmeans(points,clusters);
% 
%         % Sort out only the points belonging to the max cluster
%         xf = points(idx==1,1);
%         yf = points(idx==1,2);
%         zf = z(idx==1);
% 
%         % Sort out points that are too far from the max cluster centroid
%         D = D(idx==1,1);
%         avg_dist = mean(D);
%         defect_idxs = find(D < 2.5*avg_dist);
% 
%         xf = xf(defect_idxs);
%         yf = yf(defect_idxs);
%         zf = zf(defect_idxs);
%     else
%         % Other rounds not implemented
%     end
end 