function plot_curve_over_time_ShadedErrorBar_multiple_conditions(dt, ydata_mean, ydata_SE, colors, x_label, y_label, figures_dir, fname, options)
% Optional 9th arg `options` (struct) supports:
%   options.xlim   - 2-element vector overriding the tight x-limits
%   options.xticks - vector of tick locations for the x-axis
if nargin < 9 || isempty(options)
    options = struct();
end

% Square 6x6 in white-bg layout — borrowed from TCell-3D-Morphodynamics
% (plot_mean_with_error_over_time.m) for consistent paper-figure sizing.
fig = figure('Units', 'inches', 'Position', [2 2 6 6], 'Color', 'white', 'Visible', 'off');
nconditions = numel(ydata_mean);

for i = 1:nconditions
    timevec = 0:dt:dt*(numel(ydata_mean{i})-1);
    h1 = shadedErrorBar(timevec, ydata_mean{i}, ydata_SE{i}, 'lineProps', colors{i});
    h1.mainLine.LineWidth = 2;
    hold on;
end    

set(gca,'linewidth',2,'fontweight','bold','fontsize',26);
box on;
xlabel(x_label)
ylh = ylabel(y_label);

axis tight

if isfield(options, 'xlim') && ~isempty(options.xlim)
    xlim(options.xlim);
end
if isfield(options, 'xticks') && ~isempty(options.xticks)
    xticks(options.xticks);
end

% Tighten axes within the 6x6 figure — borrowed from
% TCell-3D-Morphodynamics histogram_plotting_PDF.m. The figure size stays
% 6x6 in so PNG/TIF output is consistently 900x900 px at 150 dpi.
drawnow;
ax = gca;
ax.LooseInset = ax.TightInset + [0.01 0.03 0.01 0.01];

% Optional vertical nudge for the y-label (normalized axes coords).
% Useful when a tall y-label (e.g. with a superscript) crowds the top of the frame.
if isfield(options, 'ylabel_y_offset') && ~isempty(options.ylabel_y_offset) && options.ylabel_y_offset ~= 0
    ylh.Units = 'normalized';
    ylh.Position(2) = ylh.Position(2) + options.ylabel_y_offset;
end

set(fig, 'Visible', 'on');
set(fig, 'PaperPositionMode', 'auto');  % print honors on-screen figure size
saveas(gca, [figures_dir, fname], 'fig');
saveas(gca, [figures_dir, fname], 'tif');
print(fig, [figures_dir, fname], '-dpng', '-r150');
close
end