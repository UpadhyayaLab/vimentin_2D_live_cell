% Driver: replot BARCODE per-frame intensity distributions for all four cells
% into a single shared folder. For each cell, produces 3 legend variants
% (frame / kurtosis / none) x 2 xlim variants (auto / fixed) x 3 formats =
% 18 files per cell, plus the CD3+PLL-inset composite. Per-cell parallelism
% via parfor on a 16-worker pool.

clear; close all;

this_dir = fileparts(mfilename('fullpath'));
addpath(this_dir);
addpath(fullfile(this_dir, '..'));

data_root          = 'J:\FF\vim_data\Vimentin_2D_tighter_cropping\Vimentin_2D\BARCODE Analysis for Figures\Individual Video Data Points\';
figures_dir_main   = fullfile(data_root, 'intensity_dist_for_paper_all_together');
figures_dir_extras = fullfile(figures_dir_main, 'extras');
if ~isfolder(figures_dir_main);   mkdir(figures_dir_main);   end
if ~isfolder(figures_dir_extras); mkdir(figures_dir_extras); end

% Colors follow the repo convention from vimentin_2D_live_cells_postprocessing_combined_data.m:
% PLL=r, CD3=b for the activation pair; DMSO=b, Ciliobrevin=m for the dynein pair.
% Fixed x-axis limits per condition pair.
cells(1) = struct('folder', 'CD3 20220719 Cell 9', 'color', 'b', 'xlim_range', [70 350], 'ylim_range', [4e-5 0.5]);
cells(2) = struct('folder', 'PLL 20220623 Cell 2', 'color', 'r', 'xlim_range', [70 350], 'ylim_range', [4e-5 0.5]);
cells(3) = struct('folder', 'DMSO Cell 6',         'color', 'b', 'xlim_range', [70 200], 'ylim_range', [1e-4 0.1]);
cells(4) = struct('folder', 'Ciliobrevin Cell 11', 'color', 'm', 'xlim_range', [70 200], 'ylim_range', [1e-4 0.1]);

legend_modes = {'frame', 'kurtosis', 'none'};

% --- Build task list: each cell x 3 legend modes x 2 xlim variants ---
n_tasks = numel(cells) * numel(legend_modes) * 2;
tasks(n_tasks) = struct('csv_path', '', 'color', '', 'figures_dir', '', ...
                        'legend_mode', '', 'name_prefix', '', 'xlim_range', [], ...
                        'ylim_range', []);
idx = 0;
for k = 1:numel(cells)
    csv_path     = fullfile(data_root, cells(k).folder, 'IntensityDistribution.csv');
    name_prefix  = [strrep(cells(k).folder, ' ', '_'), '_'];
    xlim_options = {[], cells(k).xlim_range};
    for x = 1:numel(xlim_options)
        for m = 1:numel(legend_modes)
            idx = idx + 1;
            tasks(idx).csv_path    = csv_path;
            tasks(idx).color       = cells(k).color;
            tasks(idx).legend_mode = legend_modes{m};
            tasks(idx).name_prefix = name_prefix;
            tasks(idx).xlim_range  = xlim_options{x};
            tasks(idx).ylim_range  = cells(k).ylim_range;
            % Routing: only the fixed-xlim + kurtosis variant stays in the
            % main folder; all other combinations land in extras/.
            if strcmp(legend_modes{m}, 'kurtosis') && ~isempty(xlim_options{x})
                tasks(idx).figures_dir = figures_dir_main;
            else
                tasks(idx).figures_dir = figures_dir_extras;
            end
        end
    end
end

% --- Ensure a 16-worker parallel pool ---
p = gcp('nocreate');
if isempty(p)
    parpool('local', 16);
elseif p.NumWorkers ~= 16
    delete(p);
    parpool('local', 16);
end

% --- Generate plots in parallel ---
parfor t = 1:numel(tasks)
    plot_first_last_intensity_distribution( ...
        tasks(t).csv_path, tasks(t).color, tasks(t).figures_dir, ...
        tasks(t).legend_mode, tasks(t).name_prefix, tasks(t).xlim_range, tasks(t).ylim_range);
end

% --- CD3 main with PLL inset (no legend, no kurtosis); both use PLL/CD3 limits ---
plot_intensity_distribution_with_inset( ...
    fullfile(data_root, 'CD3 20220719 Cell 9', 'IntensityDistribution.csv'), 'b', ...
    fullfile(data_root, 'PLL 20220623 Cell 2', 'IntensityDistribution.csv'), 'r', ...
    figures_dir_main, 'CD3_with_PLL_inset_Intensity_Distributions', [70 350], [4e-5 0.5]);
