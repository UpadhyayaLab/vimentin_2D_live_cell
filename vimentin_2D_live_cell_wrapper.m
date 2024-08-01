clear; close all; 

%% define where the data live and the cell numbers you wish to analyze
% edit the following script to indicate where the data live and which cells you wish to analyze!
run("vimentin_2D_live_cell_dir_filenames.m")

% ensures that each directory path in the input cell array ends with the appropriate file separator for the current operating system.
base_dirs = ensure_path_separator(base_dirs);

%% define formatting of filenames and other parameters
params.subtract_bg = 1;
params.dt = 2; % time between frames (in s)
% params.nframes = 286; % could also be determined from the data, but there may be complications if not all movies are the same length
params.psize = .065; % in μm
params.save_vim_MIP_masks = 1;
params.save_vim_COF_plots = 0; % setting this to 1 greatly increases the computational time
params.color = 'b';

params.gauss_sigma = 2; % to smooth images and reduce contributions due to noise
params.noise_thresh = 5; % to reduce contributions due to noise. It's important not to set this threshold too low!

%% run the main script
for i = 1:numel(base_dirs)
    vimentin_2D_live_cell(base_dirs{i}, params, cell_number{i});
end
