% Generate MATLAB-styled MP4s of the BARCODE flow-field and divergence movies,
% faithful in content to the Python originals in
%   ...\BARCODE Flow + Divergence Field Movies\
% but rendered in the same MATLAB house style as the static paper figures
% (plasma colormap, bold um tick labels, eastoutside colorbar).
%
% Faithfulness (verified against the Python movies):
%   - 100 frames, fps = 10 (matches every Python movie).
%   - Flow movie  = INSTANTANEOUS per-window speed (NOT cumulative). The raw
%     per-window displacement magnitude in OpticalFlow.csv is already in um, so
%     "Speed (um s^-1)" needs NO calibration (single factor ~1.0 reproduces the
%     Python vmax for all 4 cells). Color/length limits auto-scale per movie.
%   - Divergence movie = divergence of the CUMULATIVE displacement field per
%     frame (dimensionless). Color limits auto-scale per movie (min/max over all
%     frames), matching the Python per-movie scaling (not the paired limits the
%     static-figure script uses).
%   - Titles "Flow Field t = X min" / "Divergence t = X min", t = frame*0.10 min.
%
% Output: <movies_root>\matlab\<Condition> {Flow,Divergence} Fields.mp4
% Python originals at the top level are NOT touched.
%
% All compute/render helpers below are copied verbatim from
% plot_optical_flow_and_divergence_for_paper.m so the styling matches exactly.

clear; close all;

figures_root = 'J:\FF\vim_data\Vimentin_2D_tighter_cropping\Vimentin_2D\BARCODE Analysis for Figures';
data_root    = fullfile(figures_root, 'Individual Video Data Points');
movies_root  = fullfile(figures_root, 'BARCODE Flow + Divergence Field Movies');
out_dir      = fullfile(movies_root, 'matlab');
if ~isfolder(out_dir); mkdir(out_dir); end

fps             = 10;     % matches every Python original
um_per_pixel    = 0.52;   % grid-cell size for spatial (um) tick labels
flow_downsample = 2;      % matches the static MATLAB flow figures
frame_px        = 700;    % output frame size (square), matches Python ~700px

% Optional smoke test: set env var MOVIE_CELLS to a folder name (e.g.
% 'CD3 20220719 Cell 9') to render just that cell first.
CELLS_OVERRIDE = {};
env_cells = getenv('MOVIE_CELLS');
if ~isempty(env_cells); CELLS_OVERRIDE = {env_cells}; end

% div_scalebar_um: 5 um for CD3/PLL, 3 um for the smaller DMSO/Cilio fields of view
% (matches the paper figures).
cells = struct( ...
    'folder',          {'CD3 20220719 Cell 9','PLL 20220623 Cell 2','DMSO Cell 6','Ciliobrevin Cell 11'}, ...
    'condition',       {'CD3','PLL','DMSO','Ciliobrevin'}, ...
    'div_scalebar_um', {5, 5, 3, 3});
if ~isempty(CELLS_OVERRIDE)
    keep = ismember({cells.folder}, CELLS_OVERRIDE);
    cells = cells(keep);
end

% Optional env var MOVIE_KINDS (e.g. 'divergence' or 'flow') to render only one
% field type; default renders both.
kinds = {'flow', 'divergence'};
env_kinds = getenv('MOVIE_KINDS');
if ~isempty(env_kinds); kinds = strsplit(env_kinds, ','); end
do_flow = any(strcmp(kinds, 'flow'));
do_div  = any(strcmp(kinds, 'divergence'));

for c = 1:numel(cells)
    folder    = cells(c).folder;
    condition = cells(c).condition;
    csv_path  = fullfile(data_root, folder, 'OpticalFlow.csv');
    fprintf('=== %s (%s) ===\n', folder, condition);

    [flow_fields, ~] = read_optical_flow_csv(csv_path);
    flow_fields = crop_flow_fields(csv_path, flow_fields);
    cumulative_fields = cumsum(flow_fields, 1);
    nF = min(size(flow_fields, 1), 100);   % 100 windows = 0-3..297-300 = 10 min; drop any extra (e.g. PLL has 101)

    % ---- precompute fields + per-movie limits ----
    flow_speed_max = 0;
    div_stack = cell(nF, 1);
    div_min = inf; div_max = -inf;
    flow_disp = cell(nF, 1);
    for i = 1:nF
        fd = block_average_field(squeeze(flow_fields(i, :, :, :)), flow_downsample);
        flow_disp{i} = fd;
        s = hypot(fd(:, :, 1), fd(:, :, 2));
        flow_speed_max = max(flow_speed_max, max(s(:)));

        dv = compute_divergence_field(squeeze(cumulative_fields(i, :, :, :)), false);
        div_stack{i} = dv;
        div_min = min(div_min, min(dv(:)));
        div_max = max(div_max, max(dv(:)));
    end
    if flow_speed_max == 0; flow_speed_max = 1; end
    div_limits = [div_min div_max];

    % ---- render flow movie ----
    if do_flow
        flow_path = fullfile(out_dir, sprintf('%s Flow Fields.mp4', condition));
        % Upright Unicode mu (U+03BC = char(956)) so the unit reads as an actual
        % micro sign, not TeX \mu's italic math glyph.
        speed_label = ['Speed (' char(956) 'm s^{-1})'];
        render_movie(flow_path, fps, frame_px, nF, 'flow', flow_disp, [0 flow_speed_max], ...
            um_per_pixel * flow_downsample, 'Flow Field', speed_label, []);
        fprintf('  wrote %s\n', flow_path);
    end

    % ---- render divergence movie ----
    if do_div
        div_path = fullfile(out_dir, sprintf('%s Divergence Fields.mp4', condition));
        render_movie(div_path, fps, frame_px, nF, 'divergence', div_stack, div_limits, ...
            um_per_pixel, 'Divergence', 'Divergence', cells(c).div_scalebar_um);
        fprintf('  wrote %s\n', div_path);
    end
end

fprintf('Done. Movies in %s\n', out_dir);

% =====================================================================
% Movie renderer: one reused figure, redraw per frame, capture to MP4.
% =====================================================================
function render_movie(out_path, fps, frame_px, nF, kind, fields, clim_vals, um_per_pixel, title_prefix, cbar_label, scalebar_um)
    vw = VideoWriter(out_path, 'MPEG-4');
    vw.FrameRate = fps;
    vw.Quality = 95;
    open(vw);
    cleanup = onCleanup(@() close(vw)); %#ok<NASGU>

    % Fixed square plot box + explicit colorbar slot so the bar always renders
    % (data grids are square, so a square box needs no axis-equal auto-resize).
    ax_pos = [0.075 0.075 0.70 0.70];
    cb_pos = [0.85 0.135 0.032 0.58];

    fig = figure('Visible', 'off', 'Units', 'pixels', ...
        'Position', [100 100 frame_px frame_px], 'Color', 'white');
    ax = axes(fig, 'Units', 'normalized', 'Position', ax_pos);
    colormap(fig, plasma_colormap(256));

    cb = colorbar(ax, 'Location', 'eastoutside');
    set(cb, 'FontSize', 12, 'FontWeight', 'bold', 'LineWidth', 1, 'Position', cb_pos);
    set(ax, 'CLim', clim_vals);
    if ~isempty(cbar_label)
        cb.Label.String = cbar_label;
        cb.Label.Interpreter = 'tex';   % renders ^{-1}; literal mu stays upright
        cb.Label.FontSize = 14;
        cb.Label.FontWeight = 'bold';
    end

    for i = 1:nF
        cla(ax);
        hold(ax, 'on');   % keep NextPlot='add' so imagesc/patch don't reset the axes (which deletes the colorbar)
        f = fields{i};
        if strcmp(kind, 'flow')
            speed = hypot(f(:, :, 1), f(:, :, 2));
            render_colored_quiver(ax, f, speed, clim_vals(2), clim_vals(2));
            style_flow_axes(ax, size(f, 2), size(f, 1), um_per_pixel, true);
        else
            imagesc(ax, [0 size(f, 2) - 1], [0 size(f, 1) - 1], f);
            set(ax, 'YDir', 'reverse');
            xlim(ax, [0 size(f, 2) - 1]);
            ylim(ax, [0 size(f, 1) - 1]);
            style_divergence_axes(ax, size(f, 2), size(f, 1), um_per_pixel, true);
            add_divergence_scalebar(ax, size(f, 2), size(f, 1), um_per_pixel, scalebar_um);  % per-condition (5 or 3 um)
        end
        axis(ax, 'normal');                 % release axis-equal aspect lock
        set(ax, 'Position', ax_pos);        % force the fixed square box
        set(cb, 'Position', cb_pos);
        set(ax, 'CLim', clim_vals);
        t_min = i * 0.10;
        title(ax, sprintf('%s: t = %.2f min', title_prefix, t_min), ...
            'FontSize', 15, 'FontWeight', 'bold');

        drawnow;
        frame = getframe(fig);
        img = frame.cdata;
        if size(img, 1) ~= frame_px || size(img, 2) ~= frame_px
            img = imresize(img, [frame_px frame_px]);
        end
        writeVideo(vw, img);
    end
    close(fig);
end

% =====================================================================
% Helpers copied verbatim from plot_optical_flow_and_divergence_for_paper.m
% =====================================================================
function [flow_fields, flow_indices] = read_optical_flow_csv(csv_path)
    fid = fopen(csv_path, 'r');
    if fid == -1; error('Could not open %s', csv_path); end
    cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
    x_fields = {}; y_fields = {}; flow_indices = zeros(0, 2);
    x_flag = true; x_field = []; y_field = [];
    while true
        line = fgetl(fid);
        if ~ischar(line); break; end
        line = strtrim(line);
        if isempty(line); continue; end
        if startsWith(line, 'Flow Field')
            if ~isempty(x_field)
                x_fields{end + 1} = x_field; %#ok<AGROW>
                y_fields{end + 1} = y_field; %#ok<AGROW>
                x_field = []; y_field = [];
            end
            token = regexp(line, 'Flow Field \((\d+)\s*-\s*(\d+)\)', 'tokens', 'once');
            if isempty(token); error('Unexpected flow-field header in %s: %s', csv_path, line); end
            flow_indices(end + 1, :) = [str2double(token{1}), str2double(token{2})]; %#ok<AGROW>
            x_flag = true;
        elseif strcmp(line, 'X-Direction'); x_flag = true;
        elseif strcmp(line, 'Y-Direction'); x_flag = false;
        else
            values = textscan(line, '%f', 'Delimiter', ',');
            row = values{1}.';
            if x_flag; x_field = [x_field; row]; else; y_field = [y_field; row]; end %#ok<AGROW>
        end
    end
    if ~isempty(x_field); x_fields{end + 1} = x_field; y_fields{end + 1} = y_field; end
    n_fields = numel(x_fields);
    if n_fields == 0; error('No flow fields were found in %s', csv_path); end
    n_rows = size(x_fields{1}, 1); n_cols = size(x_fields{1}, 2);
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

function out = block_average_field(field, block_size)
    if block_size <= 1; out = field; return; end
    n_rows = floor(size(field, 1) / block_size);
    n_cols = floor(size(field, 2) / block_size);
    field = field(1:n_rows * block_size, 1:n_cols * block_size, :);
    out = zeros(n_rows, n_cols, size(field, 3));
    for row = 1:n_rows
        row_idx = (row - 1) * block_size + (1:block_size);
        for col = 1:n_cols
            col_idx = (col - 1) * block_size + (1:block_size);
            out(row, col, :) = mean(field(row_idx, col_idx, :), [1 2]);
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

function render_colored_quiver(ax, field, speed, geom_speed_max, color_speed_max)
    cmap = plasma_colormap(256);
    [x_grid, y_grid] = meshgrid(0:size(field, 2) - 1, 0:size(field, 1) - 1);
    n_cols = size(field, 2);
    n_arrows = numel(speed);
    sn = min(max(sqrt(n_arrows), 8), 25);
    width = 0.06 / sn;
    scale = geom_speed_max * 6;
    if scale == 0; scale = 1; end
    if nargin < 5 || isempty(color_speed_max); color_speed_max = geom_speed_max; end
    if color_speed_max == 0; color_speed_max = 1; end

    length_units = speed ./ (scale * width);
    [poly_x, poly_y] = matplotlib_h_arrows(length_units(:));
    theta = atan2(field(:, :, 2), field(:, :, 1));
    theta = theta(:);
    x_grid = x_grid(:); y_grid = y_grid(:);
    speed_vec = speed(:);

    for i = 1:n_arrows
        mag = speed_vec(i);
        if ~isfinite(mag); continue; end
        color_idx = 1 + round((size(cmap, 1) - 1) * min(max(mag / color_speed_max, 0), 1));
        color_idx = min(max(color_idx, 1), size(cmap, 1));
        verts = (poly_x(i, :) + 1i * poly_y(i, :)) .* exp(1i * theta(i)) * width * n_cols;
        patch(ax, x_grid(i) + real(verts), y_grid(i) + imag(verts), cmap(color_idx, :), ...
            'EdgeColor', 'none');
    end
end

function [X, Y] = matplotlib_h_arrows(length)
    headwidth = 3; headlength = 5; headaxislength = 4.5; minshaft = 1; minlength = 1;
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
    X = x(:, ii); Y = y(:, ii); Y(:, 4:7) = -Y(:, 4:7);
    X0 = x0(:, ii); Y0 = y0(:, ii); Y0(:, 4:7) = -Y0(:, 4:7);
    if minsh ~= 0; shrink = length / minsh; else; shrink = zeros(size(length)); end
    X0 = X0 .* shrink; Y0 = Y0 .* shrink;
    short_mask = length < minsh;
    X(short_mask, :) = X0(short_mask, :);
    Y(short_mask, :) = Y0(short_mask, :);
    too_short = length < minlength;
    if any(too_short)
        th = (0:7) * (pi / 3);
        x1 = cos(th) * minlength * 0.5; y1 = sin(th) * minlength * 0.5;
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
        if min(n_cols, n_rows) <= 12; tick_step = 2; else; tick_step = 4; end
        ticks = 0:tick_step:(min(n_cols, n_rows) - 1);
        set(ax, 'XTick', ticks, 'YTick', ticks);
        ax.XTickLabel = arrayfun(@(x) sprintf('%.3g', x * um_per_pixel), ticks, 'UniformOutput', false);
        ax.YTickLabel = arrayfun(@(y) sprintf('%.3g', y * um_per_pixel), ticks, 'UniformOutput', false);
    else
        set(ax, 'XTick', [], 'YTick', []);
    end
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

function add_divergence_scalebar(ax, n_cols, n_rows, um_per_pixel, scalebar_um)
    bar_len_px = scalebar_um / um_per_pixel;
    bar_height = 0.72;
    x_margin = 2.5;   % cells of gap from the right edge (was 1.2 - moved further in)
    y_margin = 1.75;
    x_start = n_cols - x_margin - bar_len_px;
    y_bar = n_rows - y_margin - bar_height;

    rectangle(ax, 'Position', [x_start, y_bar, bar_len_px, bar_height], ...
        'FaceColor', 'k', 'EdgeColor', 'k', 'LineWidth', 0.8, 'Clipping', 'on');
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
