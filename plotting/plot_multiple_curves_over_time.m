function plot_multiple_curves_over_time(dt, ydata, color, x_label, y_label, figures_dir, fname)

fig = figure('Position', [1 1 .7 .85].*get(0, 'Screensize'), 'Visible', 'off'); 
ncells = numel(ydata);

for i = 1:ncells
    timevec = 0:dt:dt*(numel(ydata{i})-1);
    plot(timevec, ydata{i}, color, 'LineWidth', 2)
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