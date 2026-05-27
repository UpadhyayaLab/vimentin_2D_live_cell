function plot_first_last_intensity_distribution(csv_path, color, figures_dir, legend_mode, name_prefix, xlim_range)
% Plot Frame 0 and final-frame intensity distributions overlaid on semilogy.
% Layout matches the paper-figure convention in this repo (6x6 in white-bg
% square; tight whitespace via LooseInset; .fig + .tif + .png @ 150 dpi).
%
%   csv_path     - path to an IntensityDistribution.csv
%   color        - color spec for the Frame 0 marker, e.g. 'r','b','m' or [r g b]
%   figures_dir  - output folder; created if missing
%   legend_mode  - 'frame'    -> legend reads "Frame 0" / "Frame N"
%                  'kurtosis' -> legend includes computed kurtosis values
%                  'none'     -> no legend; filename suffix _no_legend
%   name_prefix  - (optional) string prepended to the output filename so multiple
%                  cells can write to the same figures_dir without colliding.
%                  Defaults to '' (preserves the original single-cell filename).
%   xlim_range   - (optional) 2-element [xmin xmax] for fixed x-axis limits.
%                  When provided, the filename gains a _fixed_xlim suffix.
%                  Defaults to [] (auto-tight via axis tight).

    if nargin < 5 || isempty(name_prefix)
        name_prefix = '';
    end
    if nargin < 6 || isempty(xlim_range)
        xlim_range = [];
    end

    frames = read_intensity_distribution_csv(csv_path);
    first  = frames(1);
    last   = frames(end);

    base_rgb  = color_to_rgb(color);
    light_rgb = base_rgb + (1 - base_rgb) * 0.45;

    fig = figure('Units', 'inches', 'Position', [2 2 6 6], 'Color', 'white');

    semilogy(first.bins, first.pdf, 'LineStyle', 'none', 'Marker', 'x', ...
             'Color', base_rgb, 'MarkerSize', 10, 'LineWidth', 2);
    hold on;
    semilogy(last.bins, last.pdf, 'LineStyle', 'none', 'Marker', 'o', ...
             'Color', light_rgb, 'MarkerSize', 10, 'LineWidth', 2);

    set(gca, 'linewidth', 2, 'fontweight', 'bold', 'fontsize', 26);
    xlabel('Pixel Intensity Value I')
    ylabel('Probability P(I)')

    switch legend_mode
        case 'kurtosis'
            k1 = pdf_kurtosis(first.bins, first.pdf);
            k2 = pdf_kurtosis(last.bins,  last.pdf);
            legend({sprintf('Frame %d Kurtosis = %.2f', first.frame_number, k1), ...
                    sprintf('Frame %d Kurtosis = %.2f', last.frame_number,  k2)}, ...
                   'Location', 'northeast', 'FontSize', 14);
            suffix = '_with_kurtosis';
        case 'frame'
            legend({sprintf('Frame %d', first.frame_number), ...
                    sprintf('Frame %d', last.frame_number)}, ...
                   'Location', 'northeast', 'FontSize', 18);
            suffix = '';
        case 'none'
            suffix = '_no_legend';
        otherwise
            error('Unknown legend_mode: %s (expected ''frame'', ''kurtosis'', or ''none'')', legend_mode);
    end

    axis tight
    if ~isempty(xlim_range)
        xlim(xlim_range);
        suffix = [suffix, '_fixed_xlim'];
    end
    % Add a touch of headroom so top markers don't sit at the frame edge.
    yl = ylim;
    ylim([yl(1), yl(2)*1.5]);

    drawnow;
    ax = gca;
    ax.LooseInset = ax.TightInset + [0.01 0.03 0.01 0.01];

    if ~isfolder(figures_dir); mkdir(figures_dir); end
    fname = sprintf('%sFrame_0_and_%d_Intensity_Distributions%s', name_prefix, last.frame_number, suffix);
    out_stub = fullfile(figures_dir, fname);

    set(fig, 'PaperPositionMode', 'auto');
    saveas(gca, out_stub, 'fig');
    saveas(gca, out_stub, 'tif');
    print(fig, out_stub, '-dpng', '-r150');
    close(fig);
end

function k = pdf_kurtosis(bins, pdf)
% Excess kurtosis (Fisher's definition: m4/m2^2 - 3) of a discrete
% distribution given bin centers and P(I) values summing to ~1. Matches
% scipy.stats.kurtosis defaults used by the Python BARCODE pipeline.
    mu = sum(bins .* pdf);
    m2 = sum((bins - mu).^2 .* pdf);
    m4 = sum((bins - mu).^4 .* pdf);
    k  = m4 / m2^2 - 3;
end

function rgb = color_to_rgb(c)
    if isnumeric(c)
        rgb = c;
        return;
    end
    switch char(c)
        case 'r', rgb = [1 0 0];
        case 'g', rgb = [0 1 0];
        case 'b', rgb = [0 0 1];
        case 'c', rgb = [0 1 1];
        case 'm', rgb = [1 0 1];
        case 'y', rgb = [1 1 0];
        case 'k', rgb = [0 0 0];
        case 'w', rgb = [1 1 1];
        otherwise, error('Unknown color spec: %s', c);
    end
end
