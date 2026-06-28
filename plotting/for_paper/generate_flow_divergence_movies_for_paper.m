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

% div_scalebar_um: 5 um for CD3/PLL, 3 um for the smaller DMSO/Cilio fields of view.
% div_src: which cell's divergence colour limits to ADOPT, so the movie colorbars
% match the for_paper figures exactly (the static script pairs control -> activated
% via div_limit_source). CD3 & PLL use CD3's limits; DMSO & Cilio use DMSO's.
cells = struct( ...
    'folder',          {'CD3 20220719 Cell 9','PLL 20220623 Cell 2','DMSO Cell 6','Ciliobrevin Cell 11'}, ...
    'condition',       {'CD3','PLL','DMSO','Ciliobrevin'}, ...
    'div_scalebar_um', {5, 5, 3, 3}, ...
    'div_src',         {'CD3','CD3','DMSO','DMSO'});
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

% Optional env var MOVIE_NAME_FILTER: only (re)render movies whose output path
% contains this substring (for targeted single-movie re-renders).
name_filter = getenv('MOVIE_NAME_FILTER');
want = @(p) isempty(name_filter) || contains(p, name_filter);

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

    % Divergence colour limits over the SAME 3 windows the for_paper figures use
    % (0-3, 147-150, 297-300 -> frames 1, 50, 100), so the movie colorbar matches.
    win_idx = [1 50 100]; win_idx = win_idx(win_idx <= nF);
    dmin3 = inf; dmax3 = -inf;
    for w = win_idx
        dmin3 = min(dmin3, min(div_stack{w}(:)));
        dmax3 = max(dmax3, max(div_stack{w}(:)));
    end

    % stash for the paired-limit divergence + combined movies rendered after this loop
    store(c).condition       = condition; %#ok<AGROW>
    store(c).flow_disp       = flow_disp;
    store(c).div_stack       = div_stack;
    store(c).flow_speed_max  = flow_speed_max;
    store(c).div_lim3        = [dmin3 dmax3];
    store(c).div_scalebar_um = cells(c).div_scalebar_um;
    store(c).div_src         = cells(c).div_src;
    store(c).nF              = nF;

    % ---- render flow movie (instantaneous speed, per-cell auto-scale) ----
    flow_path = fullfile(out_dir, sprintf('%s Flow Fields.mp4', condition));
    if do_flow && want(flow_path)
        % Upright Unicode mu (U+03BC = char(956)) so the unit reads as an actual
        % micro sign, not TeX \mu's italic math glyph.
        speed_label = ['Speed (' char(956) 'm s^{-1})'];
        render_movie(flow_path, fps, frame_px, nF, 'flow', flow_disp, [0 flow_speed_max], ...
            um_per_pixel * flow_downsample, 'Flow Field', speed_label, []);
        fprintf('  wrote %s\n', flow_path);
    end
end

% ---- render individual divergence movies with PAIRED limits (match figures) ----
if do_div
    for c = 1:numel(store)
        isrc = find(strcmp({store.condition}, store(c).div_src), 1);
        dl = store(isrc).div_lim3;   % adopt the activated cell's limits
        div_path = fullfile(out_dir, sprintf('%s Divergence Fields.mp4', store(c).condition));
        if ~want(div_path); continue; end
        render_movie(div_path, fps, frame_px, store(c).nF, 'divergence', store(c).div_stack, dl, ...
            um_per_pixel, 'Divergence of Cumulative Displacement Field', 'Divergence', store(c).div_scalebar_um);
        fprintf('  wrote %s\n', div_path);
    end
end

% ===== combined activated/control pair movies (side-by-side, shared colorbar) =====
% Only run when both members of a pair were processed (skips single-cell smoke tests).
combined_dir = fullfile(out_dir, 'combined');
if ~isfolder(combined_dir); mkdir(combined_dir); end
% left|right orderings: activated-left, control-left (e.g. PLL before CD3), etc.
pairs = struct('left', {'CD3', 'DMSO', 'PLL'}, 'right', {'PLL', 'Ciliobrevin', 'CD3'});
for p = 1:numel(pairs)
    ia = find(strcmp({store.condition}, pairs(p).left), 1);
    ib = find(strcmp({store.condition}, pairs(p).right), 1);
    if isempty(ia) || isempty(ib); continue; end
    A = store(ia); B = store(ib);
    % divergence colour limits ALWAYS come from the activated cell (A.div_src),
    % independent of which panel is on the left, so the scale matches the figures.
    isrc = find(strcmp({store.condition}, A.div_src), 1);
    dlim = store(isrc).div_lim3;
    nFp = min(A.nF, B.nF);
    for loc = {'Right', 'Below'}
        cbl = loc{1};
        outp = fullfile(combined_dir, sprintf('%s vs %s Flow Fields Colorbar %s.mp4', A.condition, B.condition, cbl));
        if do_flow && want(outp)
            fmax = max(A.flow_speed_max, B.flow_speed_max);
            speed_label = ['Speed (' char(956) 'm s^{-1})'];
            render_pair_movie(outp, fps, 'flow', A.flow_disp, B.flow_disp, [0 fmax], ...
                um_per_pixel * flow_downsample, 'Flow Field', speed_label, [], [], ...
                A.condition, B.condition, cbl, nFp);
            fprintf('  wrote %s\n', outp);
        end
        outp = fullfile(combined_dir, sprintf('%s vs %s Divergence Fields Colorbar %s.mp4', A.condition, B.condition, cbl));
        if do_div && want(outp)
            dl = dlim;   % activated cell's limits = the for_paper figure scale
            render_pair_movie(outp, fps, 'divergence', A.div_stack, B.div_stack, dl, ...
                um_per_pixel, 'Divergence of Cumulative Displacement Field', 'Divergence', A.div_scalebar_um, B.div_scalebar_um, ...
                A.condition, B.condition, cbl, nFp);
            fprintf('  wrote %s\n', outp);
        end
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
    cb_pos = [0.79 0.135 0.032 0.58];   % close to the panel's right edge (0.775)

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

    crop_box = [];   % computed once from frame 1, reused so all frames match size
    for i = 1:nF
        cla(ax);
        hold(ax, 'on');   % keep NextPlot='add' so imagesc/patch don't reset the axes (which deletes the colorbar)
        f = fields{i};
        if strcmp(kind, 'flow')
            speed = hypot(f(:, :, 1), f(:, :, 2));
            render_colored_quiver(ax, f, speed, clim_vals(2), clim_vals(2));
            style_flow_axes(ax, size(f, 2), size(f, 1), um_per_pixel, false);
        else
            imagesc(ax, [0 size(f, 2) - 1], [0 size(f, 1) - 1], f);
            set(ax, 'YDir', 'reverse');
            xlim(ax, [0 size(f, 2) - 1]);
            ylim(ax, [0 size(f, 1) - 1]);
            style_divergence_axes(ax, size(f, 2), size(f, 1), um_per_pixel, false);
            add_divergence_scalebar(ax, size(f, 2), size(f, 1), um_per_pixel, scalebar_um);  % per-condition (5 or 3 um)
        end
        axis(ax, 'normal');                 % release axis-equal aspect lock
        set(ax, 'Position', ax_pos);        % force the fixed square box
        set(cb, 'Position', cb_pos);
        set(ax, 'CLim', clim_vals);
        th = title(ax, sprintf('%s: t = %s', title_prefix, fmt_time(i)), ...
            'FontSize', 14, 'FontWeight', 'bold');
        th.Units = 'normalized'; th.Position(2) = 1.015;   % snug to the axes top

        drawnow;
        frame = getframe(fig);
        img = frame.cdata;
        if isempty(crop_box); crop_box = compute_content_box(img, 8); end
        img = img(crop_box(1):crop_box(2), crop_box(3):crop_box(4), :);
        writeVideo(vw, img);
    end
    close(fig);
end

% mm:ss time stamp for movie frame i (i*0.10 min = i*6 s).
function s = fmt_time(i)
    sec = round(i * 6);
    s = sprintf('%d:%02d', floor(sec / 60), mod(sec, 60));
end

% Tight bounding box of non-white content (+pad), forced to even width/height
% (H.264 needs even dims). Computed once from a frame and reused for all frames.
function box = compute_content_box(img, pad)
    mask = min(img, [], 3) < 250;
    rows = find(any(mask, 2)); cols = find(any(mask, 1));
    if isempty(rows) || isempty(cols); box = [1 size(img,1) 1 size(img,2)]; return; end
    r0 = max(min(rows) - pad, 1); r1 = min(max(rows) + pad, size(img, 1));
    c0 = max(min(cols) - pad, 1); c1 = min(max(cols) + pad, size(img, 2));
    if mod(r1 - r0 + 1, 2) == 1; if r1 < size(img,1); r1 = r1 + 1; else; r0 = r0 - 1; end; end
    if mod(c1 - c0 + 1, 2) == 1; if c1 < size(img,2); c1 = c1 + 1; else; c0 = c0 - 1; end; end
    box = [r0 r1 c0 c1];
end

% =====================================================================
% Combined pair renderer: two square panels side by side, ONE shared colorbar
% (Right = vertical to the right; Below = horizontal centered underneath).
% =====================================================================
function render_pair_movie(out_path, fps, kind, fieldsA, fieldsB, clim_vals, um_per_pixel, ...
        time_prefix, cbar_label, sb_A, sb_B, labelA, labelB, cbar_loc, nF)
    if strcmpi(cbar_loc, 'Right')
        fig_w = 1300; fig_h = 620; ph = 0.72; y0 = 0.10;
    else
        fig_w = 1240; fig_h = 720; ph = 0.60; y0 = 0.22;
    end
    pw = ph * fig_h / fig_w;   % keep panels square in pixels
    gap = 0.03;
    if strcmpi(cbar_loc, 'Right')
        x0a = 0.04; x0b = x0a + pw + gap;
        posA = [x0a y0 pw ph]; posB = [x0b y0 pw ph];
        cb_pos = [x0b + pw + 0.010, y0 + 0.06, 0.016, ph - 0.12];   % snug to panel B
        cb_location = 'eastoutside';
    else
        total = 2 * pw + gap;
        x0a = (1 - total) / 2; x0b = x0a + pw + gap;
        posA = [x0a y0 pw ph]; posB = [x0b y0 pw ph];
        cb_pos = [x0a + total * 0.20, y0 - 0.065, total * 0.60, 0.028];   % just below the panels
        cb_location = 'southoutside';
    end

    vw = VideoWriter(out_path, 'MPEG-4'); vw.FrameRate = fps; vw.Quality = 95; open(vw);
    cleanup = onCleanup(@() close(vw)); %#ok<NASGU>

    fig = figure('Visible', 'off', 'Units', 'pixels', 'Position', [80 80 fig_w fig_h], 'Color', 'white');
    colormap(fig, plasma_colormap(256));
    axA = axes(fig, 'Units', 'normalized', 'Position', posA);
    axB = axes(fig, 'Units', 'normalized', 'Position', posB);
    set(axA, 'CLim', clim_vals); set(axB, 'CLim', clim_vals);

    cb = colorbar(axB, 'Location', cb_location);
    set(cb, 'FontSize', 13, 'FontWeight', 'bold', 'LineWidth', 1, 'Position', cb_pos);
    if ~isempty(cbar_label)
        cb.Label.String = cbar_label; cb.Label.Interpreter = 'tex';
        cb.Label.FontSize = 15; cb.Label.FontWeight = 'bold';
    end

    % static per-panel condition labels (above each panel)
    annotation(fig, 'textbox', [posA(1) posA(2)+posA(4)+0.005 posA(3) 0.05], 'String', labelA, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'LineStyle', 'none', ...
        'FontSize', 16, 'FontWeight', 'bold');
    annotation(fig, 'textbox', [posB(1) posB(2)+posB(4)+0.005 posB(3) 0.05], 'String', labelB, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'LineStyle', 'none', ...
        'FontSize', 16, 'FontWeight', 'bold');
    % shared time title (updated per frame), centered on the PANELS (ignore the
    % colorbar) and just above the per-panel labels
    title_y = posA(2) + posA(4) + 0.055;
    timeAnn = annotation(fig, 'textbox', [posA(1) title_y (posB(1)+posB(3)-posA(1)) 0.05], 'String', '', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'LineStyle', 'none', ...
        'FontSize', 17, 'FontWeight', 'bold');

    crop_box = [];   % computed once from frame 1, reused so all frames match size
    for i = 1:nF
        draw_field_panel(axA, kind, fieldsA{i}, clim_vals, um_per_pixel, sb_A, posA);
        draw_field_panel(axB, kind, fieldsB{i}, clim_vals, um_per_pixel, sb_B, posB);
        set(cb, 'Position', cb_pos);
        timeAnn.String = sprintf('%s: t = %s', time_prefix, fmt_time(i));
        drawnow;
        fr = getframe(fig); img = fr.cdata;
        if isempty(crop_box); crop_box = compute_content_box(img, 8); end
        img = img(crop_box(1):crop_box(2), crop_box(3):crop_box(4), :);
        writeVideo(vw, img);
    end
    close(fig);
end

% Draw one clean field panel (no axis numbers) into ax at ax_pos.
function draw_field_panel(ax, kind, f, clim_vals, um_per_pixel, scalebar_um, ax_pos)
    cla(ax); hold(ax, 'on');   % hold keeps NextPlot='add' so the colorbar survives
    if strcmp(kind, 'flow')
        speed = hypot(f(:, :, 1), f(:, :, 2));
        render_colored_quiver(ax, f, speed, clim_vals(2), clim_vals(2));
        style_flow_axes(ax, size(f, 2), size(f, 1), um_per_pixel, false);
    else
        imagesc(ax, [0 size(f, 2) - 1], [0 size(f, 1) - 1], f);
        set(ax, 'YDir', 'reverse');
        xlim(ax, [0 size(f, 2) - 1]); ylim(ax, [0 size(f, 1) - 1]);
        style_divergence_axes(ax, size(f, 2), size(f, 1), um_per_pixel, false);
        if ~isempty(scalebar_um)
            add_divergence_scalebar(ax, size(f, 2), size(f, 1), um_per_pixel, scalebar_um);
        end
    end
    axis(ax, 'normal');
    set(ax, 'Position', ax_pos);
    set(ax, 'CLim', clim_vals);
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
