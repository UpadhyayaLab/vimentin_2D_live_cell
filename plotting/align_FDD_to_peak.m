function FDD_norm_aligned = align_FDD_to_peak(FDD, dt, min_nframes, max_time_to_peak_FDD)

% align relative to peak FDD value
max_time_to_consider = dt*(min_nframes - 1); 
ntimepts = max_time_to_consider/dt + 1;
ntimepts_aligned_to_max_FDD = ntimepts - max_time_to_peak_FDD/dt + 1;

nconditions = numel(FDD);
FDD_norm_aligned = cell(nconditions, 1);
for i = 1:nconditions
    ncells = numel(FDD{i});
    for j = 1:ncells
        [~, idx] = max(FDD{i}{j}(1:max_time_to_peak_FDD/dt));
        FDD_norm_aligned{i}{j} = FDD{i}{j}(idx:idx+ntimepts_aligned_to_max_FDD-1)/FDD{i}{j}(idx);
    end    
end    
end