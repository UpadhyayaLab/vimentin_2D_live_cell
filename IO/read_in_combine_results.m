function [FDD, min_nframes] = read_in_combine_results(base_dir_list, save_name)

nconditions = numel(base_dir_list);
FDD = cell(nconditions, 1);
min_nframes = nan;

for i = 1:nconditions
    ndays = numel(base_dir_list{i});
    ncells_current = 0;
    for j = 1:ndays
        fname = [base_dir_list{i}{j}, save_name];
        results_cell{i}{j} = load(fname);
        ncells{i}(j) = results_cell{i}{j}.params.ncells;

        for k = 1:ncells{i}(j)
            FDD{i}{ncells_current+k} = results_cell{i}{j}.FDD{k};
            nframes{i}{ncells_current+k} = numel(results_cell{i}{j}.FDD{k});
            min_nframes = min(min_nframes, nframes{i}{ncells_current+k});
        end 
        ncells_current = ncells_current + ncells{i}(j);

    end
end   

end