% Loops through all mask images and changes on button press for quick
% viewing
path = '../labels/';
files = dir(path);

for i = 1:length(files)
    if ~files(i).isdir
        img = imread([path char(files(i).name)]);
        fprintf("Image %d: %s\n",i,files(i).name);
        figure()
        imshow(img);
        title(files(i).name,'Interpreter','none');
        
        % Dispaly center pixel values to check default label case easier
%         P = impixel;
%         disp(P);
%         fprintf("Waiting...\n");
        A = img(150:250,150:250);
        disp(A);
        w = waitforbuttonpress;
        close;               
    end
end 