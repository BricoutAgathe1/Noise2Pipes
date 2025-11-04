%% Additive approach
folder_path = 'Capasee_2002';
mask_folder_path = 'masks_capasee2002';
output_folder = 'Capasee2002_Noise=1';

file_list = dir(fullfile(folder_path, '*.bmp'));
mkdir(output_folder);  % Make output folder if needed

for i = 1:length(file_list)
    [~, name, ~] = fileparts(file_list(i).name);
    imagePath = fullfile(folder_path, file_list(i).name);
    maskPath = fullfile(mask_folder_path, [name '_mask.png']);
    
    I_speckled = addContrast(imagePath, maskPath, 1, 10, 5);
    
    imwrite(I_speckled, fullfile(output_folder, [name '_speckled.png']));
end

%% Subtractive approach
% --- CONFIGURATION ---
mainImage1 = 'Elegra images/img1.png';  % For first 13 masks
mainImage2 = 'Elegra images/img2.png';  % For remaining masks
mainImage3 = 'Elegra images/img3.png';
mainImage4 = 'Elegra images/img4.png';

maskDir = 'masks_noise2pipes_updated';
outputDir = 'Subtractive/Elegra_Noise=1';
opacity = 1;    % Try 0.6–0.9 for visible darkening effect

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% --- Load main images (handles indexed grayscale PNGs properly) ---
targetSize = [666 888];

% Load all images correctly
img1 = load_img_safe(mainImage1, targetSize);
img2 = load_img_safe(mainImage2, targetSize);
img3 = load_img_safe(mainImage3, targetSize);
img4 = load_img_safe(mainImage4, targetSize);

% --- Get all mask files ---
maskFiles = dir(fullfile(maskDir, '*_mask.png'));

for k = 1:numel(maskFiles)
    maskPath = fullfile(maskDir, maskFiles(k).name);
    mask = imread(maskPath);

    % Convert to binary and invert
    mask = imbinarize(mask);
    invMask = double(~mask);
    
    invMask_blended = imgaussfilt(invMask,3); 
    invMask3 = cat(3, invMask_blended, invMask_blended, invMask_blended);
    
    % --- Select base image ---
    if k < 9
        base_img = img1;
    elseif k >= 9 && k < 13
        base_img = img2;
    elseif k >= 13 && k < 17
        base_img = img1;
    elseif k>= 17 && k <25
        base_img = img2;
    elseif k>=25 && k < 29
        base_img = img4;
    elseif k>=29 && k<33
        base_img = img3;
    elseif k>=33 && k<37
        base_img = img4;
    else
        base_img = img3;
    end

    % --- Apply subtractive blending ---
    blendedImage = uint8(double(base_img) .* (opacity + (1 - opacity) * invMask3));
   
    % --- Save result ---
    outName = strrep(maskFiles(k).name, '_mask.png', '_speckle.png');
    outPath = fullfile(outputDir, outName);
    imwrite(blendedImage, outPath);
end

% Helper function
function img = load_img_safe(path, targetSize)
    [A, map] = imread(path);
    if ~isempty(map)
        % Apply colormap (convert to real RGB intensities)
        img = im2uint8(ind2rgb(A, map));  % convert from indexed to true RGB
    else
        img = A;  % not indexed
    end
    img = imresize(img, targetSize);
end