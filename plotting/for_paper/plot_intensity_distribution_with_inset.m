function plot_intensity_distribution_with_inset(main_csv, main_color, inset_csv, inset_color, figures_dir, fname, main_xlim)
% Plot a main IntensityDistribution (Frame 0 + last frame) on the full 6x6
% paper-figure layout, then overlay a smaller axes in the upper-right showing
% the same two-frame style for a second IntensityDistribution.csv. No legend,
% no kurtosis annotations on either axes.
%
%   main_csv     - path to the main IntensityDistribution.csv
%   main_color   - color spec for the main Frame 0 marker (e.g. 'b','r' or RGB)
%   inset_csv    - path to the inset IntensityDistribution.csv
%   inset_color  - color spec for the inset Frame 0 marker
%   figures_dir  - output folder; created if missing
%   fname        - output filename stub (no extension); saved as .fig/.tif/.png
%   main_xlim    - (optional) 2-element [xmin xmax] for the main axes x-limits

    if nargin < 7 || isempty(main_xlim)
        main_xlim = [];
    end

    main_frames  = read_intensity_distribution_csv(main_csv);
    inset_frames = read_intensity_distribution_csv(inset_csv);

    main_first  = main_frames(1);
    main_last   = main_frames(end);
    inset_first = inset_frames(1);
    inset_last  = inset_frames(end);

    main_base   = color_to_rgb(main_color);
    main_light  = main_base + (1 - main_base) * 0.45;
    inset_base  = color_to_rgb(inset_color);
    inset_light = inset_base + (1 - inset_base) * 0.45;

    fig = figure('Units', 'inches', 'Position', [2 2 6 6], 'Color', 'white');

    % --- Main axes ---
    main_ax = axes('Parent', fig);
    semilogy(main_ax, main_first.bins, main_first.pdf, 'LineStyle', 'none', ...
             'Marker', 'x', 'Color', main_base, 'MarkerSize', 10, 'LineWidth', 2);
    hold(main_ax, 'on');
    semilogy(main_ax, main_last.bins, main_last.pdf, 'LineStyle', 'none', ...
             'Marker', 'o', 'Color', main_light, 'MarkerSize', 10, 'LineWidth', 2);

    set(main_ax, 'linewidth', 2, 'fontweight', 'bold', 'fontsize', 26);
    xlabel(main_ax, 'Pixel Intensity Value I');
    ylabel(main_ax, 'Probability P(I)');
    axis(main_ax, 'tight');
    if ~isempty(main_xlim)
        xlim(main_ax, main_xlim);
    end
    add_y_headroom(main_ax, 1.5);

    drawnow;
    main_ax.LooseInset = main_ax.TightInset + [0.01 0.03 0.01 0.01];

    % --- Inset axes (upper-right, slightly higher/righter than before) ---
    inset_ax = axes('Parent', fig, 'Position', [0.62, 0.62, 0.34, 0.34], ...
                    'Color', 'white');
    semilogy(inset_ax, inset_first.bins, inset_first.pdf, 'LineStyle', 'none', ...
             'Marker', 'x', 'Color', inset_base, 'MarkerSize', 6, 'LineWidth', 1.5);
    hold(inset_ax, 'on');
    semilogy(inset_ax, inset_last.bins, inset_last.pdf, 'LineStyle', 'none', ...
             'Marker', 'o', 'Color', inset_light, 'MarkerSize', 6, 'LineWidth', 1.5);

    set(inset_ax, 'linewidth', 1.5, 'fontweight', 'bold', 'fontsize', 12, 'Box', 'on');
    ylabel(inset_ax, 'P(I)', 'FontSize', 12, 'FontWeight', 'bold');
    axis(inset_ax, 'tight');
    add_y_headroom(inset_ax, 1.5);

    % --- Save ---
    if ~isfolder(figures_dir); mkdir(figures_dir); end
    out_stub = fullfile(figures_dir, fname);
    set(fig, 'PaperPositionMode', 'auto');
    saveas(fig, out_stub, 'fig');
    saveas(fig, out_stub, 'tif');
    print(fig, out_stub, '-dpng', '-r150');
    close(fig);
end

function add_y_headroom(ax, factor)
% Multiply the upper y-limit by `factor` so the top markers don't sit at the
% frame edge. Lower limit unchanged.
    yl = ylim(ax);
    ylim(ax, [yl(1), yl(2)*factor]);
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
