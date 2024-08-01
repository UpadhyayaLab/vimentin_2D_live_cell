function vimentin_2D_live_cell(base_dir, params, cell_number)

% move to the base directory
cd(base_dir)

%% Create folders in which intermediate steps and figures will be saved
progress_dir = fullfile(base_dir, 'vimentin_FDD_prog\');
if ~isfolder(progress_dir)
    mkdir(progress_dir);
end

vim_MIP_masks_dir = fullfile(progress_dir, 'vim_MIP_masks\');
if ~isfolder(vim_MIP_masks_dir)
    mkdir(vim_MIP_masks_dir)
end

vim_COF_dir = fullfile(progress_dir, 'vim_COF\');
if ~isfolder(vim_COF_dir)
    mkdir(vim_COF_dir)
end

figures_dir = fullfile(base_dir, 'vimentin_FDD_figures\');
if ~isfolder(figures_dir)
    mkdir(figures_dir);
end


%% loop through all cells

ncells = numel(cell_number);

% initialize variables to save
FDD = cell(ncells, 1);
FDD_norm_first_val = cell(ncells, 1);
FDD_norm_max_val = cell(ncells, 1);
FDD_norm_max_val_first_3min = cell(ncells, 1);
for i = 1:ncells
    % read in data
     [I_vim, nframes] = read_image_subtract_bg(base_dir, params.prefix, cell_number(i), params.subtract_bg);

     % segment vimentin X-Y MIP. The main point of this is to avoid considering nearby cells in the FDD calculation.
     MIP_mask = segment_vim_MIP(I_vim, params.save_vim_MIP_masks, vim_MIP_masks_dir, cell_number(i));

     FDD_this_cell = nan(1, nframes);
     parfor j = 1:nframes
         [~, FDD_this_cell(j)] = COF_2D(I_vim(:, :, j), MIP_mask, params.gauss_sigma, params.noise_thresh, params.psize, params.save_vim_COF_plots, vim_COF_dir, cell_number(i), j);
     end    

     FDD{i} = FDD_this_cell;
     FDD_norm_first_val{i} = FDD_this_cell/FDD_this_cell(1);
     FDD_norm_max_val{i} = FDD_this_cell/max(FDD_this_cell);

     % normalize by max value over first 3 min
     last_frame_to_consider = floor(180/params.dt);
     FDD_max_first_3min = max(FDD_this_cell(1:last_frame_to_consider));
     FDD_norm_max_val_first_3min{i} = FDD_this_cell/FDD_max_first_3min;
     fprintf('Finished cell %i\n', cell_number(i))
end    

%% record and save results
results.params = params;
results.params.ncells = ncells;
results.params.cell_number = cell_number;

results.FDD = FDD;
results.FDD_norm_first_val = FDD_norm_first_val;
results.FDD_norm_max_val = FDD_norm_max_val;
results.FDD_norm_max_val_first_3min = FDD_norm_max_val_first_3min;

% create a datetime object representing the current date and time
current_date_time = datetime('now');

% store the datetime object in a struct
results.datetime = current_date_time;

% save results
save('results_vimentin_FDD.mat', '-struct', 'results')

%% plot results over time on a cell-by-cell basis
cd(figures_dir)

parfor i = 1:ncells
    plot_curve_over_time(params.dt, FDD{i}, params.color, 'Time Since Imaging (s)', 'FDD (μm)', figures_dir, 'FDD_cell_', cell_number(i))
    plot_curve_over_time(params.dt, FDD_norm_first_val{i}, params.color, 'Time Since Imaging (s)', 'FDD, Norm to First Value', figures_dir, 'FDD_norm_first_val_cell_', cell_number(i))
    plot_curve_over_time(params.dt, FDD_norm_max_val{i}, params.color, 'Time Since Imaging (s)', 'FDD, Norm to Max Value', figures_dir, 'FDD_norm_max_val_cell_', cell_number(i))
end

%% plot curves for all cells together
plot_multiple_curves_over_time(params.dt, FDD, params.color, 'Time Since Imaging (s)', 'FDD (μm)', figures_dir, 'FDD_all_cells_')
plot_multiple_curves_over_time(params.dt, FDD_norm_first_val, params.color, 'Time Since Imaging (s)', 'FDD, Norm to First Value', figures_dir, 'FDD_norm_first_val_cell_all_cells_')
plot_multiple_curves_over_time(params.dt, FDD_norm_max_val, params.color, 'Time Since Imaging (s)', 'FDD, Norm to Max Value', figures_dir, 'FDD_norm_max_val_all_cells_')

disp(['Finished folder ', base_dir])
end

function [I, nframes] = read_image_subtract_bg(base_dir, prefix, cell_number, subtract_BG)
    fname = [base_dir, prefix, num2str(cell_number), '.tif'];
    I = double(ReadTifStack(fname));  

    nframes = size(I, 3);

    if subtract_BG
        I = subtract_bg(I);
    end  
end