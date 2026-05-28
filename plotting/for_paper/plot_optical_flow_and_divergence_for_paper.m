% Replot BARCODE cumulative flow and divergence figures for paper in MATLAB.
% Matches the representative-cell Python figure workflow using OpticalFlow.csv.

clear; close all;

figures_root = 'J:\FF\vim_data\Vimentin_2D_tighter_cropping\Vimentin_2D\BARCODE Analysis for Figures';
data_root = fullfile(figures_root, 'Individual Video Data Points');
review_root = fullfile(data_root, 'Representative Cell MATLAB Review');

base_cfg = struct( ...
    'output_subfolder', 'matlab_for_paper_flow_divergence', ...
    'grid_only_subfolder', 'matlab_for_paper_flow_divergence_grid_only', ...
    'clean_subfolder', 'matlab_for_paper_flow_divergence_clean', ...
    'below_bar_subfolder', 'matlab_for_paper_flow_divergence_below_bar', ...
    'colorbar_proto_subfolder', 'matlab_for_paper_flow_divergence_colorbar_positions', ...
    'paper_single_cbar_subfolder', 'matlab_for_paper_flow_divergence_paper_single_right_colorbar', ...
    'windows', [0 3; 147 150; 297 300], ...
    'flow_downsample', 2, ...
    'um_per_pixel', 0.52, ...
    'flow_scalebar_um_per_s', 0.1, ...
    'divergence_scalebar_um', 5, ...
    'spatial_scalebar_um', 5, ...
    'div_limit_source', '', ...
    'flow_limit_source', '');

representative_cells = { ...
    'DMSO Cell 6', ...
    'CD3 20220719 Cell 9', ...
    'Ciliobrevin Cell 11', ...
    'PLL 20220623 Cell 2'};

cfg = repmat(base_cfg, 1, numel(representative_cells));
for k = 1:numel(representative_cells)
    cfg(k).folder = representative_cells{k};
end
cfg(strcmp({cfg.folder}, 'Ciliobrevin Cell 11')).div_limit_source = 'DMSO Cell 6';
cfg(strcmp({cfg.folder}, 'PLL 20220623 Cell 2')).div_limit_source = 'CD3 20220719 Cell 9';
cfg(strcmp({cfg.folder}, 'Ciliobrevin Cell 11')).flow_limit_source = 'DMSO Cell 6';
cfg(strcmp({cfg.folder}, 'PLL 20220623 Cell 2')).flow_limit_source = 'CD3 20220719 Cell 9';

if ~isfolder(review_root); mkdir(review_root); end
div_limit_lookup = containers.Map('KeyType', 'char', 'ValueType', 'any');
flow_limit_lookup = containers.Map('KeyType', 'char', 'ValueType', 'any');

for k = 1:numel(cfg)
    cell_dir = fullfile(data_root, cfg(k).folder);
    csv_path = fullfile(cell_dir, 'OpticalFlow.csv');
    out_dir = fullfile(cell_dir, cfg(k).output_subfolder);
    grid_only_dir = fullfile(cell_dir, cfg(k).grid_only_subfolder);
    clean_dir = fullfile(cell_dir, cfg(k).clean_subfolder);
    below_bar_dir = fullfile(cell_dir, cfg(k).below_bar_subfolder);
    colorbar_proto_dir = fullfile(cell_dir, cfg(k).colorbar_proto_subfolder);
    paper_single_cbar_dir = fullfile(cell_dir, cfg(k).paper_single_cbar_subfolder);
    review_cell_dir = fullfile(review_root, cfg(k).folder);
    review_for_paper_dir = fullfile(review_cell_dir, 'for_paper');
    if ~isfolder(out_dir); mkdir(out_dir); end
    if ~isfolder(grid_only_dir); mkdir(grid_only_dir); end
    if ~isfolder(clean_dir); mkdir(clean_dir); end
    if ~isfolder(below_bar_dir); mkdir(below_bar_dir); end
    if ~isfolder(colorbar_proto_dir); mkdir(colorbar_proto_dir); end
    if ~isfolder(paper_single_cbar_dir); mkdir(paper_single_cbar_dir); end

    [flow_fields, flow_indices] = read_optical_flow_csv(csv_path);
    flow_fields = crop_flow_fields(csv_path, flow_fields);
    cumulative_fields = cumsum(flow_fields, 1);

    div_fields = cell(size(cfg(k).windows, 1), 1);
    div_limits = [0 0];
    self_paper_flow_limits = [0 1];
    render_paper_flow_limits = [];
    if ~isempty(cfg(k).flow_limit_source)
        if ~isKey(flow_limit_lookup, cfg(k).flow_limit_source)
            error('Requested flow limit source not yet available: %s', cfg(k).flow_limit_source);
        end
        render_paper_flow_limits = flow_limit_lookup(cfg(k).flow_limit_source);
    end

    for w = 1:size(cfg(k).windows, 1)
        win = cfg(k).windows(w, :);
        flow_idx = find_flow_window(flow_indices, win);
        displacement = squeeze(cumulative_fields(flow_idx, :, :, :));
        flow_displacement = block_average_field(displacement, cfg(k).flow_downsample);
        assert_square_grid(flow_displacement, sprintf('Flow field [%d %d]', win(1), win(2)));
        speed = hypot(flow_displacement(:, :, 1), flow_displacement(:, :, 2));
        speed_max = max(speed(:));
        if speed_max == 0
            speed_max = 1;
        end

        flow_name = sprintf('Frame %d to %d Cumulative Cropped Flow Field', win(1), win(2));
        flow_stub = fullfile(out_dir, flow_name);
        render_flow_figure(flow_displacement, flow_stub, cfg(k).um_per_pixel, ...
            cfg(k).flow_downsample, cfg(k).flow_scalebar_um_per_s);

        flow_grid_stub = fullfile(grid_only_dir, flow_name);
        render_flow_figure(flow_displacement, flow_grid_stub, cfg(k).um_per_pixel, ...
            cfg(k).flow_downsample, cfg(k).flow_scalebar_um_per_s, ...
            struct('show_colorbar', false, 'export_scalebar_svg', false));

        flow_clean_stub = fullfile(clean_dir, flow_name);
        flow_clean_opts = struct('show_colorbar', false, 'export_scalebar_svg', false, ...
                                 'show_ticks', false);
        if w == size(cfg(k).windows, 1) && ~isempty(render_paper_flow_limits)
            flow_clean_opts.color_speed_max = render_paper_flow_limits(2);
        end
        render_flow_figure(flow_displacement, flow_clean_stub, cfg(k).um_per_pixel, ...
            cfg(k).flow_downsample, cfg(k).flow_scalebar_um_per_s, ...
            flow_clean_opts);

        flow_below_center_stub = fullfile(below_bar_dir, [flow_name, ' Scalebar Below Center']);
        render_flow_figure(flow_displacement, flow_below_center_stub, cfg(k).um_per_pixel, ...
            cfg(k).flow_downsample, cfg(k).flow_scalebar_um_per_s, ...
            struct('show_colorbar', false, 'export_scalebar_svg', false, ...
                   'show_ticks', false, 'add_below_scalebar', true, ...
                   'below_scalebar_um', cfg(k).spatial_scalebar_um, ...
                   'below_scalebar_align', 'center'));

        flow_below_right_stub = fullfile(below_bar_dir, [flow_name, ' Scalebar Below Right']);
        render_flow_figure(flow_displacement, flow_below_right_stub, cfg(k).um_per_pixel, ...
            cfg(k).flow_downsample, cfg(k).flow_scalebar_um_per_s, ...
            struct('show_colorbar', false, 'export_scalebar_svg', false, ...
                   'show_ticks', false, 'add_below_scalebar', true, ...
                   'below_scalebar_um', cfg(k).spatial_scalebar_um, ...
                   'below_scalebar_align', 'right'));

        flow_cbar_below_stub = fullfile(colorbar_proto_dir, [flow_name, ' Colorbar Below']);
        render_flow_figure(flow_displacement, flow_cbar_below_stub, cfg(k).um_per_pixel, ...
            cfg(k).flow_downsample, cfg(k).flow_scalebar_um_per_s, ...
            struct('show_colorbar', true, 'colorbar_location', 'southoutside', ...
                   'export_scalebar_svg', false, 'show_ticks', false));

        flow_cbar_right_stub = fullfile(colorbar_proto_dir, [flow_name, ' Colorbar Right']);
        render_flow_figure(flow_displacement, flow_cbar_right_stub, cfg(k).um_per_pixel, ...
            cfg(k).flow_downsample, cfg(k).flow_scalebar_um_per_s, ...
            struct('show_colorbar', true, 'colorbar_location', 'eastoutside', ...
                   'export_scalebar_svg', false, 'show_ticks', false));

        flow_paper_stub = fullfile(paper_single_cbar_dir, flow_name);
        flow_paper_opts = struct('show_colorbar', w == size(cfg(k).windows, 1), ...
                                 'colorbar_location', 'eastoutside', ...
                                 'reserve_colorbar_space', true, ...
                                 'export_scalebar_svg', false, 'show_ticks', false);
        if w == size(cfg(k).windows, 1) && ~isempty(render_paper_flow_limits)
            flow_paper_opts.color_speed_max = render_paper_flow_limits(2);
        end
        render_flow_figure(flow_displacement, flow_paper_stub, cfg(k).um_per_pixel, ...
            cfg(k).flow_downsample, cfg(k).flow_scalebar_um_per_s, ...
            flow_paper_opts);
        if w == size(cfg(k).windows, 1)
            self_paper_flow_limits = [0 speed_max];
        end

        div_fields{w} = compute_divergence_field(displacement, false);
        assert_square_grid(div_fields{w}, sprintf('Divergence field [%d %d]', win(1), win(2)));
        div_limits(1) = min(div_limits(1), min(div_fields{w}(:)));
        div_limits(2) = max(div_limits(2), max(div_fields{w}(:)));
    end

    div_limit_lookup(cfg(k).folder) = div_limits;
    flow_limit_lookup(cfg(k).folder) = self_paper_flow_limits;
    paper_flow_limits = self_paper_flow_limits;
    if ~isempty(render_paper_flow_limits)
        paper_flow_limits = render_paper_flow_limits;
    end
    render_div_limits = div_limits;
    if ~isempty(cfg(k).div_limit_source)
        if ~isKey(div_limit_lookup, cfg(k).div_limit_source)
            error('Requested divergence limit source not yet available: %s', cfg(k).div_limit_source);
        end
        render_div_limits = div_limit_lookup(cfg(k).div_limit_source);
    end

    for w = 1:size(cfg(k).windows, 1)
        win = cfg(k).windows(w, :);
        div_name = sprintf('Frame %d to %d Divergence Field', win(1), win(2));
        div_stub = fullfile(out_dir, div_name);
        render_divergence_figure(div_fields{w}, render_div_limits, div_stub, cfg(k).um_per_pixel);

        div_grid_stub = fullfile(grid_only_dir, div_name);
        render_divergence_figure(div_fields{w}, render_div_limits, div_grid_stub, cfg(k).um_per_pixel, ...
            struct('show_colorbar', false));

        div_scalebar_stub = fullfile(grid_only_dir, [div_name, ' 5um Scalebar']);
        render_divergence_figure(div_fields{w}, render_div_limits, div_scalebar_stub, cfg(k).um_per_pixel, ...
            struct('show_colorbar', false, 'show_ticks', false, 'add_scalebar', true, ...
                   'scalebar_um', cfg(k).divergence_scalebar_um));

        div_clean_stub = fullfile(clean_dir, div_name);
        render_divergence_figure(div_fields{w}, render_div_limits, div_clean_stub, cfg(k).um_per_pixel, ...
            struct('show_colorbar', false, 'show_ticks', false));

        div_clean_scalebar_stub = fullfile(clean_dir, [div_name, ' Scalebar']);
        render_divergence_figure(div_fields{w}, render_div_limits, div_clean_scalebar_stub, cfg(k).um_per_pixel, ...
            struct('show_colorbar', false, 'show_ticks', false, 'add_scalebar', true, ...
                   'scalebar_um', cfg(k).divergence_scalebar_um));

        div_below_center_stub = fullfile(below_bar_dir, [div_name, ' Scalebar Below Center']);
        render_divergence_figure(div_fields{w}, render_div_limits, div_below_center_stub, cfg(k).um_per_pixel, ...
            struct('show_colorbar', false, 'show_ticks', false, 'add_below_scalebar', true, ...
                   'below_scalebar_um', cfg(k).spatial_scalebar_um, ...
                   'below_scalebar_align', 'center'));

        div_below_right_stub = fullfile(below_bar_dir, [div_name, ' Scalebar Below Right']);
        render_divergence_figure(div_fields{w}, render_div_limits, div_below_right_stub, cfg(k).um_per_pixel, ...
            struct('show_colorbar', false, 'show_ticks', false, 'add_below_scalebar', true, ...
                   'below_scalebar_um', cfg(k).spatial_scalebar_um, ...
                   'below_scalebar_align', 'right'));

        div_cbar_below_stub = fullfile(colorbar_proto_dir, [div_name, ' Colorbar Below']);
        render_divergence_figure(div_fields{w}, render_div_limits, div_cbar_below_stub, cfg(k).um_per_pixel, ...
            struct('show_colorbar', true, 'show_ticks', false, ...
                   'colorbar_location', 'southoutside'));

        div_cbar_right_stub = fullfile(colorbar_proto_dir, [div_name, ' Colorbar Right']);
        render_divergence_figure(div_fields{w}, render_div_limits, div_cbar_right_stub, cfg(k).um_per_pixel, ...
            struct('show_colorbar', true, 'show_ticks', false, ...
                   'colorbar_location', 'eastoutside'));

        div_paper_stub = fullfile(paper_single_cbar_dir, div_name);
        render_divergence_figure(div_fields{w}, render_div_limits, div_paper_stub, cfg(k).um_per_pixel, ...
            struct('show_colorbar', w == size(cfg(k).windows, 1), ...
                   'show_ticks', false, ...
                   'colorbar_location', 'eastoutside', ...
                   'reserve_colorbar_space', true));
    end

    fprintf('Saved MATLAB flow/divergence figures to %s\n', out_dir);
    fprintf('Saved MATLAB grid-only variants to %s\n', grid_only_dir);
    fprintf('Saved MATLAB clean variants to %s\n', clean_dir);
    fprintf('Saved MATLAB below-bar prototypes to %s\n', below_bar_dir);
    fprintf('Saved MATLAB colorbar-position prototypes to %s\n', colorbar_proto_dir);
    fprintf('Saved MATLAB paper single-colorbar variants to %s\n', paper_single_cbar_dir);

    refresh_original_output_copy(cell_dir, fullfile(review_cell_dir, '01_python_originals'));
    refresh_directory_copy(out_dir, fullfile(review_cell_dir, '02_matlab_full'));
    refresh_directory_copy(grid_only_dir, fullfile(review_cell_dir, '03_matlab_grid_only'));
    refresh_directory_copy(clean_dir, fullfile(review_cell_dir, '04_matlab_clean'));
    refresh_directory_copy(below_bar_dir, fullfile(review_cell_dir, '05_matlab_below_bar'));
    refresh_directory_copy(colorbar_proto_dir, fullfile(review_cell_dir, '06_matlab_colorbar_positions'));
    refresh_directory_copy(paper_single_cbar_dir, fullfile(review_cell_dir, '07_matlab_paper_single_right_colorbar'));
    refresh_review_for_paper_subset(review_cell_dir, render_div_limits, paper_flow_limits);
    fprintf('Saved review paper subset to %s\n', review_for_paper_dir);
    fprintf('Copied centralized review outputs to %s\n', review_cell_dir);
end

function [flow_fields, flow_indices] = read_optical_flow_csv(csv_path)
    fid = fopen(csv_path, 'r');
    if fid == -1
        error('Could not open %s', csv_path);
    end
    cleanup = onCleanup(@() fclose(fid));

    x_fields = {};
    y_fields = {};
    flow_indices = zeros(0, 2);
    x_flag = true;
    x_field = [];
    y_field = [];

    while true
        line = fgetl(fid);
        if ~ischar(line)
            break;
        end
        line = strtrim(line);
        if isempty(line)
            continue;
        end

        if startsWith(line, 'Flow Field')
            if ~isempty(x_field)
                x_fields{end + 1} = x_field; %#ok<AGROW>
                y_fields{end + 1} = y_field; %#ok<AGROW>
                x_field = [];
                y_field = [];
            end

            token = regexp(line, 'Flow Field \((\d+)\s*-\s*(\d+)\)', 'tokens', 'once');
            if isempty(token)
                error('Unexpected flow-field header in %s: %s', csv_path, line);
            end
            flow_indices(end + 1, :) = [str2double(token{1}), str2double(token{2})]; %#ok<AGROW>
            x_flag = true;
        elseif strcmp(line, 'X-Direction')
            x_flag = true;
        elseif strcmp(line, 'Y-Direction')
            x_flag = false;
        else
            values = textscan(line, '%f', 'Delimiter', ',');
            row = values{1}.';
            if x_flag
                x_field = [x_field; row]; %#ok<AGROW>
            else
                y_field = [y_field; row]; %#ok<AGROW>
            end
        end
    end

    if ~isempty(x_field)
        x_fields{end + 1} = x_field;
        y_fields{end + 1} = y_field;
    end

    n_fields = numel(x_fields);
    if n_fields == 0
        error('No flow fields were found in %s', csv_path);
    end

    n_rows = size(x_fields{1}, 1);
    n_cols = size(x_fields{1}, 2);
    flow_fields = zeros(n_fields, n_rows, n_cols, 2);
    for i = 1:n_fields
        flow_fields(i, :, :, 1) = x_fields{i};
        flow_fields(i, :, :, 2) = y_fields{i};
    end
end

function flow_fields = crop_flow_fields(name, flow_fields)
    if contains(name, 'Ciliobrevin', 'IgnoreCase', true)
        flow_fields = flow_fields(:, 2:end-1, 4:end-4, :);
    elseif contains(name, 'DMSO', 'IgnoreCase', true)
        flow_fields = flow_fields(:, 3:end-1, :, :);
    elseif contains(name, 'CD3', 'IgnoreCase', true)
        flow_fields = flow_fields(:, 6:39, :, :);
    end
end

function idx = find_flow_window(flow_indices, win)
    idx = find(flow_indices(:, 1) == win(1) & flow_indices(:, 2) == win(2), 1, 'first');
    if isempty(idx)
        error('Could not find flow window [%d %d].', win(1), win(2));
    end
end

function out = block_average_field(field, block_size)
    if block_size <= 1
        out = field;
        return;
    end

    n_rows = floor(size(field, 1) / block_size);
    n_cols = floor(size(field, 2) / block_size);
    field = field(1:n_rows * block_size, 1:n_cols * block_size, :);

    out = zeros(n_rows, n_cols, size(field, 3));
    for row = 1:n_rows
        row_idx = (row - 1) * block_size + (1:block_size);
        for col = 1:n_cols
            col_idx = (col - 1) * block_size + (1:block_size);
            block = field(row_idx, col_idx, :);
            out(row, col, :) = mean(block, [1 2]);
        end
    end
end

function div_field = compute_divergence_field(field, normalize_vectors)
    work_field = field * 2;
    if normalize_vectors
        magnitudes = hypot(work_field(:, :, 1), work_field(:, :, 2));
        magnitudes(magnitudes == 0) = 1;
        work_field(:, :, 1) = work_field(:, :, 1) ./ magnitudes;
        work_field(:, :, 2) = work_field(:, :, 2) ./ magnitudes;
    end

    [dfx_dx, ~] = gradient(work_field(:, :, 1), 1);
    [~, dfy_dy] = gradient(work_field(:, :, 2), 1);
    div_field = flipud(dfx_dx + dfy_dy);
end

function render_flow_figure(field, out_stub, um_per_pixel, downsample, scalebar_um_per_s, opts)
    if nargin < 6
        opts = struct();
    end
    opts = set_default_opts(opts, struct('show_colorbar', true, 'export_scalebar_svg', true, ...
        'show_ticks', true, 'colorbar_location', 'eastoutside', ...
        'add_below_scalebar', false, 'below_scalebar_um', 5, ...
        'below_scalebar_align', 'center', 'reserve_colorbar_space', false));
    if ~isfield(opts, 'color_speed_max')
        opts.color_speed_max = [];
    end

    speed = hypot(field(:, :, 1), field(:, :, 2));
    geom_speed_max = max(speed(:));
    if geom_speed_max == 0
        geom_speed_max = 1;
    end
    color_speed_max = geom_speed_max;
    if ~isempty(opts.color_speed_max)
        color_speed_max = opts.color_speed_max;
    end
    if color_speed_max == 0
        color_speed_max = 1;
    end

    fig = figure('Visible', 'off', 'Units', 'inches', 'Position', [1 1 7 7], 'Color', 'white');
    ax = axes(fig);
    hold(ax, 'on');
    render_colored_quiver(ax, field, speed, geom_speed_max, color_speed_max);
    style_flow_axes(ax, size(field, 2), size(field, 1), um_per_pixel * downsample, opts.show_ticks);
    apply_square_layout(ax, opts.show_ticks, opts.add_below_scalebar, opts.show_colorbar, ...
        opts.colorbar_location, opts.reserve_colorbar_space);
    colormap(fig, plasma_colormap(256));
    clim(ax, [0 color_speed_max]);
    if opts.show_colorbar
        cb = colorbar(ax, 'Location', opts.colorbar_location);
        style_colorbar(cb);
        apply_colorbar_layout(ax, cb, opts.show_ticks, opts.add_below_scalebar, ...
            opts.colorbar_location, opts.reserve_colorbar_space);
    end
    apply_repo_tight_whitespace(ax);
    export_figure_set(fig, out_stub);

    if opts.export_scalebar_svg
        fig_scalebar = figure('Visible', 'off', 'Units', 'inches', 'Position', [1 1 7 7], 'Color', 'white');
        ax_scalebar = axes(fig_scalebar);
        hold(ax_scalebar, 'on');
        render_colored_quiver(ax_scalebar, field, speed, geom_speed_max, color_speed_max);
        style_flow_axes(ax_scalebar, size(field, 2), size(field, 1), um_per_pixel * downsample, opts.show_ticks);
        apply_square_layout(ax_scalebar, opts.show_ticks, opts.add_below_scalebar, opts.show_colorbar, ...
            opts.colorbar_location, opts.reserve_colorbar_space);
        colormap(fig_scalebar, plasma_colormap(256));
        clim(ax_scalebar, [0 color_speed_max]);
        if opts.show_colorbar
            cb_scalebar = colorbar(ax_scalebar, 'Location', opts.colorbar_location);
            style_colorbar(cb_scalebar);
            apply_colorbar_layout(ax_scalebar, cb_scalebar, opts.show_ticks, opts.add_below_scalebar, ...
                opts.colorbar_location, opts.reserve_colorbar_space);
        end
        apply_repo_tight_whitespace(ax_scalebar);

        annotation(fig_scalebar, 'arrow', [0.43 0.57], [0.93 0.93], ...
            'LineWidth', 1.5, 'HeadLength', 8, 'HeadWidth', 8);
        annotation(fig_scalebar, 'textbox', [0.58 0.905 0.18 0.05], ...
            'String', sprintf('%.1f \\mum/s', scalebar_um_per_s), ...
            'LineStyle', 'none', 'FontSize', 12, 'FontWeight', 'bold', ...
            'VerticalAlignment', 'middle');
        print(fig_scalebar, sprintf('%s_scalebar.svg', out_stub), '-dsvg');
        close(fig_scalebar);
    end

    if opts.add_below_scalebar
        add_horizontal_scalebar_below(fig, ax, size(field, 2), um_per_pixel * downsample, ...
            opts.below_scalebar_um, opts.below_scalebar_align);
        export_figure_set(fig, out_stub);
    end

    close(fig);
end

function render_divergence_figure(div_field, div_limits, out_stub, um_per_pixel, opts)
    if nargin < 5
        opts = struct();
    end
    opts = set_default_opts(opts, struct('show_colorbar', true, 'add_scalebar', false, ...
        'scalebar_um', 5, 'show_ticks', true, 'add_below_scalebar', false, ...
        'below_scalebar_um', 5, 'below_scalebar_align', 'center', ...
        'colorbar_location', 'eastoutside', 'reserve_colorbar_space', false));

    fig = figure('Visible', 'off', 'Units', 'inches', 'Position', [1 1 7 7], 'Color', 'white');
    ax = axes(fig);
    imagesc(ax, [0 size(div_field, 2) - 1], [0 size(div_field, 1) - 1], div_field);
    set(ax, 'YDir', 'reverse');
    axis(ax, 'equal');
    xlim(ax, [0 size(div_field, 2) - 1]);
    ylim(ax, [0 size(div_field, 1) - 1]);
    style_divergence_axes(ax, size(div_field, 2), size(div_field, 1), um_per_pixel, opts.show_ticks);
    apply_square_layout(ax, opts.show_ticks, opts.add_below_scalebar, opts.show_colorbar, ...
        opts.colorbar_location, opts.reserve_colorbar_space);
    colormap(fig, plasma_colormap(256));
    clim(ax, div_limits);
    if opts.show_colorbar
        cb = colorbar(ax, 'Location', opts.colorbar_location);
        style_colorbar(cb);
        apply_colorbar_layout(ax, cb, opts.show_ticks, opts.add_below_scalebar, ...
            opts.colorbar_location, opts.reserve_colorbar_space);
    end
    apply_repo_tight_whitespace(ax);

    if opts.add_scalebar
        add_divergence_scalebar(ax, size(div_field, 2), size(div_field, 1), um_per_pixel, opts.scalebar_um);
    end

    if opts.add_below_scalebar
        add_horizontal_scalebar_below(fig, ax, size(div_field, 2), um_per_pixel, ...
            opts.below_scalebar_um, opts.below_scalebar_align);
    end

    export_figure_set(fig, out_stub);
    close(fig);
end

function render_colored_quiver(ax, field, speed, geom_speed_max, color_speed_max)
    cmap = plasma_colormap(256);
    [x_grid, y_grid] = meshgrid(0:size(field, 2) - 1, 0:size(field, 1) - 1);
    n_cols = size(field, 2);
    n_rows = size(field, 1);
    n_arrows = numel(speed);
    sn = min(max(sqrt(n_arrows), 8), 25);
    width = 0.06 / sn;
    scale = geom_speed_max * 6;
    if scale == 0
        scale = 1;
    end
    if nargin < 5 || isempty(color_speed_max)
        color_speed_max = geom_speed_max;
    end
    if color_speed_max == 0
        color_speed_max = 1;
    end

    length_units = speed ./ (scale * width);
    [poly_x, poly_y] = matplotlib_h_arrows(length_units(:));
    theta = atan2(field(:, :, 2), field(:, :, 1));
    theta = theta(:);
    x_grid = x_grid(:);
    y_grid = y_grid(:);
    speed_vec = speed(:);

    for i = 1:n_arrows
        mag = speed_vec(i);
        if ~isfinite(mag)
            continue;
        end

        color_idx = 1 + round((size(cmap, 1) - 1) * min(max(mag / color_speed_max, 0), 1));
        color_idx = min(max(color_idx, 1), size(cmap, 1));

        verts = (poly_x(i, :) + 1i * poly_y(i, :)) .* exp(1i * theta(i)) * width * n_cols;
        patch(ax, x_grid(i) + real(verts), y_grid(i) + imag(verts), cmap(color_idx, :), ...
            'EdgeColor', 'none');
    end
end

function [X, Y] = matplotlib_h_arrows(length)
    headwidth = 3;
    headlength = 5;
    headaxislength = 4.5;
    minshaft = 1;
    minlength = 1;

    length = length(:);
    n = numel(length);
    minsh = minshaft * headlength;
    length = min(max(length, 0), 2^16);

    x = [zeros(n, 1), length - headaxislength, length - headlength, length];
    y = 0.5 * repmat([1 1 headwidth 0], n, 1);

    x0 = [zeros(n, 1), repmat(minsh - headaxislength, n, 1), ...
        repmat(minsh - headlength, n, 1), repmat(minsh, n, 1)];
    y0 = 0.5 * repmat([1 1 headwidth 0], n, 1);

    ii = [1 2 3 4 3 2 1 1];
    X = x(:, ii);
    Y = y(:, ii);
    Y(:, 4:7) = -Y(:, 4:7);

    X0 = x0(:, ii);
    Y0 = y0(:, ii);
    Y0(:, 4:7) = -Y0(:, 4:7);

    if minsh ~= 0
        shrink = length / minsh;
    else
        shrink = zeros(size(length));
    end
    X0 = X0 .* shrink;
    Y0 = Y0 .* shrink;

    short_mask = length < minsh;
    X(short_mask, :) = X0(short_mask, :);
    Y(short_mask, :) = Y0(short_mask, :);

    too_short = length < minlength;
    if any(too_short)
        th = (0:7) * (pi / 3);
        x1 = cos(th) * minlength * 0.5;
        y1 = sin(th) * minlength * 0.5;
        X(too_short, :) = repmat(x1, nnz(too_short), 1);
        Y(too_short, :) = repmat(y1, nnz(too_short), 1);
    end
end

function style_flow_axes(ax, n_cols, n_rows, um_per_pixel, show_ticks)
    axis(ax, 'equal');
    xlim(ax, [-0.5  n_cols - 0.5]);
    ylim(ax, [-0.5  n_rows - 0.5]);
    set(ax, 'LineWidth', 2, 'FontSize', 12, 'FontWeight', 'bold', ...
        'Box', 'on', 'XAxisLocation', 'top', 'YAxisLocation', 'right');
    if show_ticks
        if min(n_cols, n_rows) <= 12
            tick_step = 2;
        else
            tick_step = 4;
        end
        ticks = 0:tick_step:(min(n_cols, n_rows) - 1);
        set(ax, 'XTick', ticks, 'YTick', ticks);
        ax.XTickLabel = arrayfun(@(x) sprintf('%.3g', x * um_per_pixel), ticks, 'UniformOutput', false);
        ax.YTickLabel = arrayfun(@(y) sprintf('%.3g', y * um_per_pixel), ticks, 'UniformOutput', false);
    else
        set(ax, 'XTick', [], 'YTick', []);
    end
end

function add_divergence_scalebar(ax, n_cols, n_rows, um_per_pixel, scalebar_um)
    bar_len_px = scalebar_um / um_per_pixel;
    bar_height = 0.72;
    x_margin = 1.2;
    y_margin = 1.75;
    x_start = n_cols - x_margin - bar_len_px;
    y_bar = n_rows - y_margin - bar_height;

    rectangle(ax, 'Position', [x_start, y_bar, bar_len_px, bar_height], ...
        'FaceColor', 'k', 'EdgeColor', 'k', 'LineWidth', 0.8, 'Clipping', 'on');
end

function style_divergence_axes(ax, n_cols, n_rows, um_per_pixel, show_ticks)
    set(ax, 'LineWidth', 1, 'FontSize', 12, 'FontWeight', 'bold', ...
        'Box', 'on', 'XAxisLocation', 'top', 'YAxisLocation', 'right');
    if show_ticks
        ticks = 0:2.5:(min(n_rows, n_cols) - 2);
        set(ax, 'XTick', ticks, 'YTick', ticks);
        ax.XTickLabel = arrayfun(@(x) sprintf('%.3g', x * um_per_pixel), ticks, 'UniformOutput', false);
        ax.YTickLabel = arrayfun(@(y) sprintf('%.3g', y * um_per_pixel), ticks, 'UniformOutput', false);
    else
        set(ax, 'XTick', [], 'YTick', []);
    end
end

function style_colorbar(cb, opts)
    if nargin < 2
        opts = struct();
    end
    opts = set_default_opts(opts, struct('font_size', 12, 'ticks', [], 'axis_location', ''));
    set(cb, 'FontSize', opts.font_size, 'FontWeight', 'bold', 'LineWidth', 1);
    if ~isempty(opts.ticks)
        cb.Ticks = opts.ticks;
    end
    if ~isempty(opts.axis_location)
        cb.AxisLocation = opts.axis_location;
    end
end

function apply_square_layout(ax, show_ticks, add_below_scalebar, show_colorbar, colorbar_location, reserve_colorbar_space)
    layout = compute_square_layout(show_ticks, add_below_scalebar, show_colorbar, colorbar_location, reserve_colorbar_space);
    set(ax, 'Position', layout.ax_pos);
end

function apply_colorbar_layout(ax, cb, show_ticks, add_below_scalebar, colorbar_location, reserve_colorbar_space)
    layout = compute_square_layout(show_ticks, add_below_scalebar, true, colorbar_location, reserve_colorbar_space);
    set(ax, 'Position', layout.ax_pos);
    if ~isempty(layout.cb_pos)
        set(cb, 'Position', layout.cb_pos);
    end
end

function layout = compute_square_layout(show_ticks, add_below_scalebar, show_colorbar, colorbar_location, reserve_colorbar_space)
    if show_ticks
        left_margin = 0.05;
        bottom_margin = 0.05;
        top_margin = 0.11;
        right_margin = 0.13;
    else
        left_margin = 0.03;
        bottom_margin = 0.03;
        top_margin = 0.03;
        right_margin = 0.03;
    end

    if add_below_scalebar
        bottom_margin = max(bottom_margin, 0.13);
    end

    layout.cb_pos = [];
    use_colorbar_layout = show_colorbar || reserve_colorbar_space;

    if use_colorbar_layout && strcmpi(colorbar_location, 'southoutside')
        cb_height = 0.035;
        cb_gap = 0.02;
        outer_bottom = max(bottom_margin, 0.08);
        avail_width = 1 - left_margin - right_margin;
        avail_height = 1 - top_margin - outer_bottom - cb_gap - cb_height;
        side = min(avail_width, avail_height);
        x0 = left_margin + (avail_width - side) / 2;
        y0 = outer_bottom + cb_gap + cb_height;
        layout.ax_pos = [x0 y0 side side];
        if show_colorbar
            layout.cb_pos = [x0 outer_bottom side cb_height];
        end
    elseif use_colorbar_layout && strcmpi(colorbar_location, 'eastoutside')
        cb_width = 0.032;
        cb_gap = 0.02;
        outer_right = max(right_margin, 0.08);
        avail_width = 1 - left_margin - outer_right - cb_gap - cb_width;
        avail_height = 1 - top_margin - bottom_margin;
        side = min(avail_width, avail_height);
        x0 = left_margin;
        y0 = bottom_margin + (avail_height - side) / 2;
        layout.ax_pos = [x0 y0 side side];
        if show_colorbar
            layout.cb_pos = [x0 + side + cb_gap y0 cb_width side];
        end
    else
        avail_width = 1 - left_margin - right_margin;
        avail_height = 1 - top_margin - bottom_margin;
        side = min(avail_width, avail_height);
        x0 = left_margin + (avail_width - side) / 2;
        y0 = bottom_margin + (avail_height - side) / 2;
        layout.ax_pos = [x0 y0 side side];
    end
end

function apply_repo_tight_whitespace(ax)
    drawnow;
    ax.LooseInset = ax.TightInset + [0.01 0.03 0.01 0.01];
end

function add_horizontal_scalebar_below(fig, ax, n_cols, um_per_pixel, scalebar_um, align_mode)
    ax_pos = get(ax, 'Position');
    data_width_um = (n_cols - 1) * um_per_pixel;
    bar_frac = min(scalebar_um / data_width_um, 0.95);
    bar_width = ax_pos(3) * bar_frac;
    y = ax_pos(2) - 0.07;

    switch lower(align_mode)
        case 'right'
            x1 = ax_pos(1) + ax_pos(3) - 0.01;
            x0 = x1 - bar_width;
        otherwise
            x0 = ax_pos(1) + (ax_pos(3) - bar_width) / 2;
            x1 = x0 + bar_width;
    end

    annotation(fig, 'line', [x0 x1], [y y], 'Color', 'k', 'LineWidth', 3);
end

function assert_square_grid(field, field_name)
    if size(field, 1) ~= size(field, 2)
        error('%s is not square: [%d x %d].', field_name, size(field, 1), size(field, 2));
    end
end

function opts = set_default_opts(opts, defaults)
    names = fieldnames(defaults);
    for i = 1:numel(names)
        if ~isfield(opts, names{i})
            opts.(names{i}) = defaults.(names{i});
        end
    end
end

function export_figure_set(fig, out_stub)
    set(fig, 'PaperPositionMode', 'auto');
    print(fig, sprintf('%s.png', out_stub), '-dpng', '-r100');
    print(fig, sprintf('%s.pdf', out_stub), '-dpdf', '-painters');
    print(fig, sprintf('%s.svg', out_stub), '-dsvg');
end

function refresh_original_output_copy(src_dir, dst_dir)
    ensure_clean_dir(dst_dir);
    files = dir(fullfile(src_dir, 'Frame *'));
    for i = 1:numel(files)
        if files(i).isdir
            continue;
        end

        name = files(i).name;
        if contains(name, 'Cumulative Cropped Flow Field') || contains(name, 'Divergence Field')
            copyfile(fullfile(src_dir, name), fullfile(dst_dir, name));
        end
    end
end

function refresh_directory_copy(src_dir, dst_dir)
    if isfolder(dst_dir)
        rmdir(dst_dir, 's');
    end
    [ok, msg] = copyfile(src_dir, dst_dir);
    if ~ok
        error('Could not copy %s to %s: %s', src_dir, dst_dir, msg);
    end
end

function ensure_clean_dir(dir_path)
    if isfolder(dir_path)
        rmdir(dir_path, 's');
    end
    mkdir(dir_path);
end

function refresh_review_for_paper_subset(review_cell_dir, div_limits, flow_limits)
    for_paper_dir = fullfile(review_cell_dir, 'for_paper');
    clean_dir = fullfile(review_cell_dir, '04_matlab_clean');
    ensure_clean_dir(for_paper_dir);

    copy_variant_with_optional_rename(clean_dir, for_paper_dir, ...
        'Frame 0 to 3 Divergence Field Scalebar', ...
        'Frame 0 to 3 Divergence Field');
    copy_variant_with_optional_rename(clean_dir, for_paper_dir, ...
        'Frame 147 to 150 Divergence Field');
    copy_variant_with_optional_rename(clean_dir, for_paper_dir, ...
        'Frame 297 to 300 Divergence Field');
    copy_variant_with_optional_rename(clean_dir, for_paper_dir, ...
        'Frame 297 to 300 Cumulative Cropped Flow Field');
    crop_for_paper_field_pngs(for_paper_dir);
    div_vertical_opts = struct();
    if contains(review_cell_dir, 'DMSO Cell 6', 'IgnoreCase', true)
        div_ticks = ceil(div_limits(1) / 0.1) * 0.1 : 0.1 : floor(div_limits(2) / 0.1) * 0.1;
        if isempty(div_ticks)
            div_ticks = 0;
        end
        div_vertical_opts = struct('font_size', 18, 'ticks', div_ticks, 'axis_location', 'in');
    end
    export_standalone_colorbar_figure(div_limits, ...
        fullfile(for_paper_dir, 'Divergence Colorbar'), 'vertical', div_vertical_opts);
    export_standalone_colorbar_figure(div_limits, ...
        fullfile(for_paper_dir, 'Divergence Colorbar Horizontal'), 'horizontal');
    export_standalone_colorbar_figure(flow_limits, ...
        fullfile(for_paper_dir, 'Cumulative Cropped Flow Field Colorbar'), 'vertical');
    flow_horizontal_ticks = 0:0.2:(floor(flow_limits(2) / 0.2) * 0.2);
    if isempty(flow_horizontal_ticks)
        flow_horizontal_ticks = 0;
    end
    export_standalone_colorbar_figure(flow_limits, ...
        fullfile(for_paper_dir, 'Cumulative Cropped Flow Field Colorbar Horizontal'), 'horizontal', ...
        struct('font_size', 24, 'ticks', flow_horizontal_ticks));
end

function copy_variant_with_optional_rename(src_dir, dst_dir, src_stub, dst_stub)
    if nargin < 4
        dst_stub = src_stub;
    end

    exts = {'.png', '.pdf', '.svg'};
    for i = 1:numel(exts)
        src_path = fullfile(src_dir, [src_stub, exts{i}]);
        dst_path = fullfile(dst_dir, [dst_stub, exts{i}]);
        if ~isfile(src_path)
            error('Required file missing for for_paper subset: %s', src_path);
        end
        copyfile(src_path, dst_path);
    end
end

function extract_right_colorbar_png(src_png, dst_png)
    if ~isfile(src_png)
        error('Required colorbar source missing: %s', src_png);
    end

    img = imread(src_png);
    n_cols = size(img, 2);
    x0 = 610;
    if n_cols < x0
        error('Colorbar source is narrower than expected: %s', src_png);
    end
    cropped = img(:, x0:end, :);
    cropped = tight_crop_rgb_image(cropped, 250, 2);
    imwrite(cropped, dst_png);
end

function crop_for_paper_field_pngs(for_paper_dir)
    files = dir(fullfile(for_paper_dir, 'Frame *.png'));
    row_idx = 21:680;
    col_idx = 21:680;

    for i = 1:numel(files)
        file_path = fullfile(files(i).folder, files(i).name);
        img = imread(file_path);
        if size(img, 1) < row_idx(end) || size(img, 2) < col_idx(end)
            error('Field PNG is smaller than expected for tight crop: %s', file_path);
        end
        img = img(row_idx, col_idx, :);
        imwrite(img, file_path);
    end
end

function export_colorbar_companions_from_png(png_path)
    if ~isfile(png_path)
        error('Missing standalone colorbar PNG: %s', png_path);
    end

    [folder, base, ~] = fileparts(png_path);
    out_stub = fullfile(folder, base);
    img = read_image_as_rgb_uint8(png_path);
    fig = figure('Visible', 'off', 'Units', 'pixels', ...
        'Position', [100 100 size(img, 2) size(img, 1)], 'Color', 'white');
    ax = axes(fig, 'Units', 'normalized', 'Position', [0 0 1 1]);
    image(ax, img);
    axis(ax, 'image');
    axis(ax, 'off');
    savefig(fig, [out_stub, '.fig']);
    saveas(fig, out_stub, 'tif');
    close(fig);
    copyfile([out_stub, '.tif'], [out_stub, '.tiff']);
end

function export_standalone_colorbar_figure(clim_vals, out_stub, orientation, opts)
    if nargin < 4
        opts = struct();
    end
    opts = set_default_opts(opts, struct('font_size', 12, 'ticks', [], 'axis_location', ''));

    if strcmpi(orientation, 'horizontal')
        fig_height = max(110, round(5 * opts.font_size + 30));
        fig = figure('Visible', 'off', 'Units', 'pixels', ...
            'Position', [100 100 620 fig_height], 'Color', 'white');
        ax = axes(fig, 'Units', 'normalized', 'Position', [0 0 1 1]);
        h_img = imagesc(ax, [0 1; 0 1]);
        set(h_img, 'Visible', 'off');
        axis(ax, 'off');
        colormap(fig, plasma_colormap(256));
        clim(ax, clim_vals);
        cb = colorbar(ax, 'Location', 'southoutside');
        cb.AxisLocation = 'in';
        cb.Position = [0.06 0.42 0.88 0.2];
    else
        fig_width = max(92, round(4.5 * opts.font_size + 40));
        fig = figure('Visible', 'off', 'Units', 'pixels', ...
            'Position', [100 100 fig_width 620], 'Color', 'white');
        ax = axes(fig, 'Units', 'normalized', 'Position', [0 0 1 1]);
        h_img = imagesc(ax, [0 1; 0 1]);
        set(h_img, 'Visible', 'off');
        axis(ax, 'off');
        colormap(fig, plasma_colormap(256));
        clim(ax, clim_vals);
        cb = colorbar(ax, 'Location', 'eastoutside');
        cb.Position = [0.10 0.03 0.20 0.94];
    end

    style_colorbar(cb, opts);
    set(fig, 'PaperPositionMode', 'auto');
    print(fig, out_stub, '-dpng', '-r200');
    close(fig);
    png_path = [out_stub, '.png'];
    img = read_image_as_rgb_uint8(png_path);
    img = tight_crop_rgb_image(img, 250, 2);
    imwrite(img, png_path);
    export_colorbar_companions_from_png(png_path);
end

function img = read_image_as_rgb_uint8(img_path)
    [raw, map, alpha] = imread(img_path);
    if ~isempty(map)
        img = im2uint8(ind2rgb(raw, map));
    else
        img = raw;
    end

    if ~isempty(alpha)
        alpha = im2double(alpha);
        img = im2double(img);
        img = img .* alpha + (1 - alpha);
        img = im2uint8(img);
    end
end

function cropped = tight_crop_rgb_image(img, white_threshold, padding)
    if nargin < 2
        white_threshold = 250;
    end
    if nargin < 3
        padding = 0;
    end

    if ndims(img) == 2
        mask = img < white_threshold;
    else
        mask = any(img < white_threshold, 3);
    end

    [rows, cols] = find(mask);
    if isempty(rows) || isempty(cols)
        cropped = img;
        return;
    end

    row0 = max(min(rows) - padding, 1);
    row1 = min(max(rows) + padding, size(img, 1));
    col0 = max(min(cols) - padding, 1);
    col1 = min(max(cols) + padding, size(img, 2));
    cropped = img(row0:row1, col0:col1, :);
end

function cmap = plasma_colormap(n)
    anchor = [ ...
        0.050383 0.029803 0.527975
        0.132381 0.022258 0.563250
        0.214350 0.017706 0.599239
        0.290894 0.020739 0.636337
        0.362553 0.003243 0.649245
        0.430983 0.014431 0.659744
        0.496615 0.023544 0.657631
        0.557243 0.047331 0.643443
        0.620919 0.098934 0.614257
        0.683758 0.156278 0.571660
        0.741388 0.214381 0.524216
        0.794549 0.275770 0.473117
        0.840155 0.333580 0.427455
        0.881443 0.392529 0.383229
        0.915471 0.448807 0.342890
        0.944844 0.507658 0.302433
        0.968526 0.569700 0.261721
        0.984199 0.629718 0.224595
        0.993814 0.704741 0.183043
        0.996898 0.778697 0.152855
        0.993033 0.853266 0.143925
        0.980556 0.921749 0.174744];

    x = linspace(0, 1, size(anchor, 1));
    xi = linspace(0, 1, n);
    cmap = interp1(x, anchor, xi, 'linear');
end
