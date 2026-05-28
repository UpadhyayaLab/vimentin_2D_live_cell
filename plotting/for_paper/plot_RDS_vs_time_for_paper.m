% Replot RDS-vs-time CSVs (Kurtosis, Norm Divergence) for paper figures using
% the repo's shaded-error-bar plotting function.

clear; close all;

% Make the parent plotting/ folder visible so we can call the shared function.
this_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(this_dir, '..'));

data_dir = 'J:\FF\vim_data\Vimentin_2D_tighter_cropping\Vimentin_2D\BARCODE Analysis for Figures\RDS vs Time Plot Data\';
figures_dir = [data_dir, 'MATLAB_plotting\'];
if ~isfolder(figures_dir); mkdir(figures_dir); end

% --- Config: one entry per CSV ---
% control_cols / treatment_cols are [mean_col, sem_col] indices in the table.
% ylabel_y_offset nudges the y-label down (negative) in normalized axes coords.
% Used for the taller "Reduced Divergence (μm^{-1})" label whose superscript
% would otherwise crowd the top of the frame.
cfg(1) = struct( ...
    'csv',              'Activated vs Non-Activated Cells Kurtosis All Cells.csv', ...
    'control_cols',     [5 6], ...   % PLL mean, PLL SEM
    'treatment_cols',   [2 3], ...   % CD3 mean, CD3 SEM
    'colors',           {{'r','b'}}, ...
    'ylabel',           'Kurtosis', ...
    'ylabel_y_offset',  0);
cfg(2) = struct( ...
    'csv',              'Activated vs Non-Activated Cells Norm Divergence All Cells.csv', ...
    'control_cols',     [5 6], ...
    'treatment_cols',   [2 3], ...
    'colors',           {{'r','b'}}, ...
    'ylabel',           'Reduced Divergence (μm^{-1})', ...
    'ylabel_y_offset',  -0.05);
cfg(3) = struct( ...
    'csv',              'Dynein Inhibition Cells Kurtosis All Cells.csv', ...
    'control_cols',     [4 5], ...   % DMSO mean, DMSO SEM (no cell-count cols in this file)
    'treatment_cols',   [2 3], ...   % Ciliobrevin
    'colors',           {{'b','m'}}, ...
    'ylabel',           'Kurtosis', ...
    'ylabel_y_offset',  0);
cfg(4) = struct( ...
    'csv',              'Dynein Inhibition Cells Norm Divergence All Cells.csv', ...
    'control_cols',     [5 6], ...   % DMSO
    'treatment_cols',   [2 3], ...   % Ciliobrevin
    'colors',           {{'b','m'}}, ...
    'ylabel',           'Reduced Divergence (μm^{-1})', ...
    'ylabel_y_offset',  -0.05);

for k = 1:numel(cfg)
    T = readtable([data_dir, cfg(k).csv], 'VariableNamingRule', 'preserve');
    time = T{:,1};
    dt = time(2) - time(1);

    ctrl_mean  = trim_trailing_nan(T{:, cfg(k).control_cols(1)});
    ctrl_se    = trim_trailing_nan(T{:, cfg(k).control_cols(2)});
    treat_mean = trim_trailing_nan(T{:, cfg(k).treatment_cols(1)});
    treat_se   = trim_trailing_nan(T{:, cfg(k).treatment_cols(2)});

    % Truncate every series to the shortest one so all conditions span the
    % same time range (avoids an asymmetric tail past the shorter condition).
    n_min = min([numel(ctrl_mean), numel(ctrl_se), numel(treat_mean), numel(treat_se)]);
    ctrl_mean  = ctrl_mean(1:n_min);
    ctrl_se    = ctrl_se(1:n_min);
    treat_mean = treat_mean(1:n_min);
    treat_se   = treat_se(1:n_min);

    ydata_mean = {ctrl_mean(:)',  treat_mean(:)'};
    ydata_SE   = {ctrl_se(:)',    treat_se(:)'};

    [~, base, ~] = fileparts(cfg(k).csv);
    fname = strrep(base, ' ', '_');

    % Minutes version: x/60, plot to 10 min, ticks at 0/5/10
    opts_min = struct('xlim', [0 10], 'xticks', [0 5 10], ...
                      'ylabel_y_offset', cfg(k).ylabel_y_offset);
    plot_curve_over_time_ShadedErrorBar_multiple_conditions( ...
        dt/60, ydata_mean, ydata_SE, cfg(k).colors, ...
        'Time (min)', cfg(k).ylabel, figures_dir, fname, opts_min);
end

function y = trim_trailing_nan(y)
    last = find(~isnan(y), 1, 'last');
    y = y(1:last);
end
