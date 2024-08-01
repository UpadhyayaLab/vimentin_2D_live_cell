clear
close all

%% define where the data live
% base_dir_list{i}{j} should contain data from condition i, experiment j

% non-activated
base_dir_list{1}{1} = 'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220623_mCherry-Vimentin_SinglePlane\Cells_PLL\';
base_dir_list{1}{2} = 'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220719_mCherry-Vimentin_SinglePlane\Cells_PLL\';
base_dir_list{1}{3} = 'H:\FF\Vimentin_Data\20221103_mCherry-Vimentin_EGFP-Centrin-2_live_glass\PLL\cells\time_series\channels\';

% activated
base_dir_list{2}{1} = 'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220609_mCherry-Vimentin_SinglePlane\Cells\';
base_dir_list{2}{2} = 'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220623_mCherry-Vimentin_SinglePlane\Cells_CD3\';
base_dir_list{2}{3} = 'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220719_mCherry-Vimentin_SinglePlane\Cells_CD3\';
base_dir_list{2}{4} = 'H:\FF\Vimentin_Data\20221103_mCherry-Vimentin_EGFP-Centrin-2_live_glass\aCD3\cells\time_series\channels\';
base_dir_list{2}{5} = 'G:\FF\Vimentin_Project_2ndharddrive\20230203_mCherry-Vimentin_EGFP-Centrin-2\For Vimentin Contraction Analysis\No Treatment - aCD3\individual channels\';

%% define where the outputs should be saved
save_dir = 'G:\FF\Vimentin Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\figures\';
save_dir_individual_cells = [save_dir, 'individual_cells\'];

%% set parameters
save_name = 'results_vimentin_FDD.mat'; % as defined in vimentin_2D_live_cell.m
dt = 2; % in seconds. should be consistent for all data under consideration

colors{1} = 'r'; % for plotting
colors{2} = 'b';

condition_names_for_saving_figs{1} = 'PLL';
condition_names_for_saving_figs{2} = 'CD3';

max_time_to_peak_FDD = 180; % in s. the max FDD value within the first max_spread_time will be used for normalization.

%% create directories for saving figures
if ~isfolder(save_dir)
    mkdir(save_dir)
end

if ~isfolder(save_dir_individual_cells)
    mkdir(save_dir_individual_cells)
end

cd(save_dir)

%% read in results and align relative to peak FDD value
[FDD, min_nframes] = read_in_combine_results(base_dir_list, save_name);
FDD_norm_aligned = align_FDD_to_peak(FDD, dt, min_nframes, max_time_to_peak_FDD);

[FDD_mean, FDD_SE, FDD_norm_aligned_mean, FDD_norm_aligned_SE] = FDD_mean_SE(FDD, FDD_norm_aligned, min_nframes);

%% plot results over time on a cell-by-cell basis
cd(save_dir_individual_cells)
for i = 1:numel(base_dir_list)
    parfor j = 1:numel(base_dir_list{i})
        % raw FDD values
        fname = ['FDD_', condition_names_for_saving_figs{i}, '_cell'];
        plot_curve_over_time(dt, FDD{i}{j}, colors{i}, 'Time Since Imaging (s)', 'FDD (μm)', save_dir_individual_cells, fname, j)
    
        % FDD starting from max value
        fname = ['FDD_norm_aligned_', condition_names_for_saving_figs{i}, '_cell'];
        plot_curve_over_time(dt, FDD_norm_aligned{i}{j}, colors{i}, 'Time Since Imaging (s)', 'FDD (Normalized)', save_dir_individual_cells, fname, j)
    end    
end

%% plot curves for all cells together
cd(save_dir)

% raw FDD values
fname = 'FDD_all_cells';
plot_multiple_curves_over_time_multiple_conditions(dt, FDD, colors, 'Time Since Imaging (s)', 'FDD (μm)', save_dir, fname)

% FDD starting from max value
fname = 'FDD_norm_aligned_all_cells';
plot_multiple_curves_over_time_multiple_conditions(dt, FDD_norm_aligned, colors, 'Time (s)', 'FDD (Normalized)', save_dir, fname)

%% plot averaged curves

% raw FDD values
fname = 'FDD_ShadedErrorBar';
plot_curve_over_time_ShadedErrorBar_multiple_conditions(dt, FDD_mean, FDD_SE, colors, 'Time Since Imaging (s)', 'FDD (μm)', save_dir, fname)

% FDD starting from max value
fname = 'FDD_norm_aligned_ShadedErrorBar';
plot_curve_over_time_ShadedErrorBar_multiple_conditions(dt, FDD_norm_aligned_mean, FDD_norm_aligned_SE, colors, 'Time (s)', 'FDD (Normalized)', save_dir, fname)