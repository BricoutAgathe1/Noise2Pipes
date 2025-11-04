function [I_speckled] = addContrast(imagePath, maskPath, noiseLevel, blendSize, ringSize)
% addContrast - Blends speckle with soft Gaussian feathering, modelling
% contrast changes to pipes
%
% Inputs:
%   imagePath  - Path to image
%   maskPath   - Path to binary mask
%   noiseLevel - Blend strength (0–1)
%   blendSize  - Feathering distance (pixels)
%   ringSize   - Ring width for local speckle sampling (pixels)
%
% Output:
%   I_speckled - Image with added speckle in pipe

% --- Read images ---
I = im2double(imread(imagePath));
mask = imread(maskPath) > 0;

% --- Crop to bounding box around pipe ---
stats = regionprops(mask, 'BoundingBox');
bb = round(stats(1).BoundingBox);

rowRange = bb(2):(bb(2)+bb(4)-1);
colRange = bb(1):(bb(1)+bb(3)-1);

I_crop = I(rowRange, colRange);
pipeMask_crop = mask(rowRange, colRange);

% --- Create feather mask ---
se = strel('disk', blendSize);
outerMask = imdilate(pipeMask_crop, se);

distanceMap = bwdist(pipeMask_crop);  % Distance from outer ring
fadeWidth = blendSize*0.8;

featherMask = zeros(size(pipeMask_crop));
featherRegion = outerMask & ~pipeMask_crop;  % Only blend outside the pipe
featherMask(featherRegion) = max(0, 1 - distanceMap(featherRegion) / fadeWidth);  % 1 → 0 outward
featherMask(pipeMask_crop) = 1;

% --- Build speckle patch ---
ringMask = imdilate(mask, strel('disk', ringSize)) & ~mask;
ringMask_crop = ringMask(rowRange, colRange);

speckleSource = I_crop;
speckleSource(~ringMask_crop) = NaN;
specklePatch = regionfill(speckleSource, isnan(speckleSource));

% --- Fill the pipe ---
filled_crop = I_crop;
filled_crop(pipeMask_crop) = specklePatch(pipeMask_crop);

% --- Blend original and filled ---
blendFactor = noiseLevel * featherMask;
blended_crop = ((1 - blendFactor) .* I_crop) + ((blendFactor) .* filled_crop);

% --- Paste back into original image ---
I_speckled = I;
I_speckled(rowRange, colRange) = blended_crop;

end
