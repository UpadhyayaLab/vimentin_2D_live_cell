function plot_curve_over_time(dt, ydata, color, x_label, y_label, figures_dir, fname, cellnum)

timevec = 0:dt:dt*(numel(ydata)-1);

fig = figure('Position', [1 1 0.7 .85].*get(0, 'Screensize'), 'Visible', 'off'); 
plot(timevec, ydata, 'Color', color, 'LineWidth', 2); hold on;
set(gca,'linewidth',2,'fontweight','bold','fontsize',28);
xlabel(x_label)
ylabel(y_label)
xlim([0 max(timevec(:))])
axis tight

% set(fig, 'Visible', 'on');
% saveas(gca, [figures_dir, fname, num2str(cellnum)], 'fig');
% saveas(gca, [figures_dir, fname, num2str(cellnum)], 'tif'); 
saveas(gca, [figures_dir, fname, num2str(cellnum)], 'jpg'); close
end