function I = subtract_bg(I)
% estimate bg as the 25% of all voxels in the image (quite arbitrary)
% be cautious about cells with a large number of 0s!

% to check if bg subtraction has already been performed, compare smallest
% and second smallest values
Isorted_unique = unique(sort(I(:)));
if Isorted_unique(2) - Isorted_unique(1) >= 50
    % cropped and not bg subtracted
    bg = quantile(I(I > 50), .25);
else
    bg = quantile(I(:), .25);
end    

I = I - bg;
I(I < 0) = 0;
end