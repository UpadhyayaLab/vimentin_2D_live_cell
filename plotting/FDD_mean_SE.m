function [FDD_mean, FDD_SE, FDD_norm_aligned_mean, FDD_norm_aligned_SE] = FDD_mean_SE(FDD, FDD_norm_aligned, min_nframes)

% preallocate
nconditions = numel(FDD);
FDD_matrix_form = cell(nconditions, 1);
FDD_norm_aligned_matrix_form = cell(nconditions, 1);

FDD_mean = cell(nconditions, 1);
FDD_norm_aligned_mean = cell(nconditions, 1);

FDD_SE = cell(nconditions, 1);
FDD_norm_aligned_SE = cell(nconditions, 1);
for i = 1:nconditions
    ncells = numel(FDD{i});
    FDD_matrix_form{i} = zeros(ncells, min_nframes);
    FDD_norm_aligned_matrix_form{i} = zeros(ncells, numel(FDD_norm_aligned{i}{1})); % the "aligned" curves should all have the same length
    for j = 1:ncells
        FDD_matrix_form{i}(j, :) = FDD{i}{j}(1:min_nframes);
        FDD_norm_aligned_matrix_form{i}(j, :) = FDD_norm_aligned{i}{j};
    end    

    FDD_mean{i} = mean(FDD_matrix_form{i}, 1);
    FDD_SD = std(FDD_matrix_form{i}, 1);
    FDD_SE{i} = FDD_SD/sqrt(ncells);

    FDD_norm_aligned_mean{i} = mean(FDD_norm_aligned_matrix_form{i}, 1);
    FDD_norm_aligned_SD = std(FDD_norm_aligned_matrix_form{i}, 1);
    FDD_norm_aligned_SE{i} = FDD_norm_aligned_SD/sqrt(ncells);
end    


end