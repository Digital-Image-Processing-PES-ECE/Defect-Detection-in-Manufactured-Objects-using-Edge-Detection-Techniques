%a=imread("C:\PESU\SEM5\DIP\DIP Project\defective1.png");
%b=imread("C:\PESU\SEM5\DIP\DIP Project\reference1.png");
%a=imread("C:\PESU\SEM5\DIP\DIP Project\defective2.png");
%b=imread("C:\PESU\SEM5\DIP\DIP Project\reference2.png");
%a=imread("C:\PESU\SEM5\DIP\DIP Project\defective3.png");
%b=imread("C:\PESU\SEM5\DIP\DIP Project\reference3.png");
%a=imread("C:\PESU\SEM5\DIP\DIP Project\defective4.png");
%b=imread("C:\PESU\SEM5\DIP\DIP Project\reference4.png");
%a=imread("C:\PESU\SEM5\DIP\DIP Project\defective5.png");
%b=imread("C:\PESU\SEM5\DIP\DIP Project\reference5.png");
opts.minarea=100;
opts.methods={'sobel', 'roberts', 'prewitt'};
opts.show_plot=false;
detectDefects(a,b);

function [defects, mask] = detectDefects(product_img, reference_img, opts)
   
  
    if nargin < 3 %Assuming opts is left blank
        opts.min_area = 50;
        opts.methods = {'sobel', 'roberts', 'prewitt'};
        opts.show_plot = true;
        
        %Classifying defect types
        opts.scratch_ar = 3.8;    % aspect ratio threshold
        opts.spot_circ = 2.5;    % circularity threshold
        opts.big_defect = 400;    % area threshold for big defects
    end

    try
        % Load images
        if ischar(product_img)
            img1 = imread(product_img);
            img2 = imread(reference_img);
        else
            img1 = product_img;
            img2 = reference_img;
        end
        % Convert to grayscale
        if size(img1,3) == 3 %Checking if inputs are color images
            img1 = rgb2gray(img1);
        end
        if size(img2,3) == 3 
            img2 = rgb2gray(img2);
        end
        %Resizing reference to product image dimensions
        img2 = imresize(img2, size(img1));
        
        % Edge detection using methods defined in opts struct
        mask = false(size(img1));
        for i = 1:length(opts.methods)
            m = opts.methods{i};
            diff = xor(edge(img1, m), edge(img2, m));%XOR gives differences
            mask = mask | diff;
        end
        
        
        mask = bwareaopen(mask, opts.min_area);
        
        %Obtaining Regions
        cc = bwconncomp(mask);
        stats = regionprops(cc, 'Area', 'BoundingBox', 'Perimeter', ...
                              'MajorAxisLength', 'MinorAxisLength', 'Centroid');
        
        defects = struct('bbox',{},'type',{},'conf',{});
        
        %Plot Setup
        if opts.show_plot
            figure;
            imshow(img1); hold on;
            colors = struct('scratch','r', 'spot','g', 'dent','b');%Colour coding each defect type
        end
        
        % Check each region
        for i = 1:length(stats)
            s = stats(i);
            
            % Shape analysis
            ar = s.MajorAxisLength / max(s.MinorAxisLength, eps);
            circ = 4*pi*s.Area / max(s.Perimeter^2, eps);
            
            % Classify defect
            if ar > opts.scratch_ar
                type = 'scratch';
                conf = min(0.9, ar/opts.scratch_ar);
            elseif circ > opts.spot_circ && s.Area < opts.big_defect
                type = 'spot';
                conf = circ;
            else
                type = 'dent';
                conf = min(1, s.Area/opts.big_defect);
            end
            
            % Save info
            defects(i).bbox = s.BoundingBox;
            defects(i).type = type;
            defects(i).conf = conf;
            
            % Draw if needed
            if opts.show_plot
                rectangle('Position', s.BoundingBox, ...
                         'EdgeColor', colors.(type), 'LineWidth', 1.5);
                text(s.Centroid(1), s.Centroid(2), ...
                     sprintf('%s %.2f', type, conf), ...
                     'Color', colors.(type), ...
                     'BackgroundColor', 'white');
            end
        end
        
        % Print summary
        fprintf('Found %d defects\n', length(defects));
        types = {defects.type};
        fprintf('Scratches: %d\n', sum(strcmp(types, 'scratch')));
        fprintf('Spots: %d\n', sum(strcmp(types, 'spot')));
        fprintf('Dents: %d\n', sum(strcmp(types, 'dent')));
        
    catch ME
        error('Detection failed: %s', ME.message);
    end
end