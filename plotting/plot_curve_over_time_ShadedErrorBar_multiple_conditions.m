function plot_curve_over_time_ShadedErrorBar_multiple_conditions(dt, ydata_mean, ydata_SE, colors, x_label, y_label, figures_dir, fname)

fig = figure('Position', [1 1 .7 .85].*get(0, 'Screensize'), 'Visible', 'off'); 
nconditions = numel(ydata_mean);

for i = 1:nconditions
    timevec = 0:dt:dt*(numel(ydata_mean{i})-1);
    h1 = shadedErrorBar(timevec, ydata_mean{i}, ydata_SE{i}, 'lineProps', colors{i});
    h1.mainLine.LineWidth = 2;
    hold on;
end    

set(gca,'linewidth',2,'fontweight','bold','fontsize',28);
xlabel(x_label)
ylabel(y_label)

axis tight

set(fig, 'Visible', 'on');
saveas(gca, [figures_dir, fname], 'fig');
saveas(gca, [figures_dir, fname], 'tif'); close
end