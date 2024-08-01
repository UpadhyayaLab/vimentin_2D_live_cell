function plot_multiple_curves_over_time_multiple_conditions(dt, ydata, colors, x_label, y_label, figures_dir, fname)

fig = figure('Position', [1 1 .7 .85].*get(0, 'Screensize'), 'Visible', 'off'); 
nconditions = numel(ydata);

for i = 1:nconditions
    ncells = numel(ydata{i});
    for j = 1:ncells
        timevec = 0:dt:dt*(numel(ydata{i}{j})-1);
        plot(timevec, ydata{i}{j}, colors{i}, 'LineWidth', 2)
        hold on;
    end
end

set(gca,'linewidth',2,'fontweight','bold','fontsize',28);
xlabel(x_label)
ylabel(y_label)

axis tight

set(fig, 'Visible', 'on');
saveas(gca, [figures_dir, fname], 'fig');
saveas(gca, [figures_dir, fname], 'tif'); close
end