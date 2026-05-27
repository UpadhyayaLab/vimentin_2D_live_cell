% Driver: replot BARCODE per-frame intensity distributions for paper figures.
% Produces two PNG/TIF/FIG outputs per cell (with and without kurtosis in legend)
% into a matlab_for_paper/ subfolder inside each cell's data directory.

clear; close all;

this_dir = fileparts(mfilename('fullpath'));
addpath(this_dir);                  % helpers in this folder
addpath(fullfile(this_dir, '..'));  % parent plotting/ (for any future shared helpers)

data_root = 'J:\FF\vim_data\Vimentin_2D_tighter_cropping\Vimentin_2D\BARCODE Analysis for Figures\Individual Video Data Points\';

% Colors follow the repo convention from vimentin_2D_live_cells_postprocessing_combined_data.m:
% PLL=r, CD3=b for the activation pair; DMSO=b, Ciliobrevin=m for the dynein pair.
cells(1) = struct('folder', 'CD3 20220719 Cell 9', 'color', 'b');
cells(2) = struct('folder', 'PLL 20220623 Cell 2', 'color', 'r');
cells(3) = struct('folder', 'DMSO Cell 6',         'color', 'b');
cells(4) = struct('folder', 'Ciliobrevin Cell 11', 'color', 'm');

for k = 1:numel(cells)
    cell_dir = fullfile(data_root, cells(k).folder);
    csv_path = fullfile(cell_dir, 'IntensityDistribution.csv');
    figs_dir = fullfile(cell_dir, 'matlab_for_paper');

    plot_first_last_intensity_distribution(csv_path, cells(k).color, figs_dir, 'frame');
    plot_first_last_intensity_distribution(csv_path, cells(k).color, figs_dir, 'kurtosis');
    plot_first_last_intensity_distribution(csv_path, cells(k).color, figs_dir, 'none');
end
