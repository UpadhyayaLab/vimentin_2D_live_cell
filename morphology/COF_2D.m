function [COF, FDD] = COF_2D(I, mask, gauss_sigma, noise_thresh, psize, plot_COF, vim_COF_folder, cellnum, framenum)

% The FDD (Fluorescence Dispersion Distance) provides a measure of
% clustering. Here, I is the 2D slice under consideration (vimentin)

I = imgaussfilt(I, gauss_sigma);
I(I < noise_thresh) = 0; % this is important to reduce contributions due to noise
I = I.*mask; % to avoid contributions from nearby cells


[X, Y] = ndgrid(1:size(I, 1), 1:size(I, 2));
% convert to microns
X = X*psize; Y = Y*psize;

xCOF = sum(X.*I, "all") / sum(I(:));
yCOF = sum(Y.*I, "all") / sum(I(:));

COF = [xCOF yCOF];

distances = sqrt((X - xCOF).^2 + (Y - yCOF).^2);

FDD = sum(distances.*I, "all")/sum(I(:));

if plot_COF
    figure('Visible', 'off');
    imagesc(I);
    colormap gray;
    set(gca,'dataAspectRatio',[1 1 1])
    hold on;
    plot(yCOF/psize, xCOF/psize, 'g*', 'MarkerSize', 25);
    axis off

    scale_bar_length_microns = 5; % Desired scale bar length in microns
    scale_bar_length_pixels = scale_bar_length_microns / psize; % Length in pixels

    image_size = size(I);
    scale_bar_x = image_size(2) - scale_bar_length_pixels - 10; % 10 pixels from the right edge
    scale_bar_y = 10; % 10 pixels from the top

    % Draw the scale bar
    rectangle('Position', [scale_bar_x, scale_bar_y, scale_bar_length_pixels, 10], ...
        'FaceColor', 'w', 'EdgeColor', 'none');
    hold off;

    % scalebar doesn't show up properly...
    saveas(gca, [vim_COF_folder, '\Cell_', num2str(cellnum), '_frame_', num2str(framenum), '_vim_COF'], 'jpg');
    % saveas(gca, [vim_COF_folder, '\Cell_', num2str(cellnum), '_frame_', num2str(framenum), '_vim_COF'], 'tif');
    % exportgraphics(gca, [vim_COF_folder, '\Cell_', num2str(cellnum), '_frame_', num2str(framenum), '_vim_COF.tif'], 'Resolution', 300)
    close;
end

end