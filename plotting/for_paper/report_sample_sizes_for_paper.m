% Report sample sizes (N per condition) for the BARCODE RDS-vs-time paper
% figures. Two data sources:
%   1. RDS-vs-time summary CSVs in "RDS vs Time Plot Data/" — header N at row 1
%      of the "Number of <condition> Cells" columns (when present).
%   2. Per-cell CSVs in "Violin Plot Data/" — count unique entries in the
%      "Cell Number" column to get ground-truth N.
%
% Cross-checks the two sources, recovers the missing Dynein Kurtosis N's from
% the violin data, and prints which cells differ between Kurtosis and
% Norm-Divergence cohorts for the same condition.

clear;

barcode_dir = 'J:\FF\vim_data\Vimentin_2D_tighter_cropping\Vimentin_2D\BARCODE Analysis for Figures\';
rds_dir     = fullfile(barcode_dir, 'RDS vs Time Plot Data');
violin_dir  = fullfile(barcode_dir, 'Violin Plot Data');

rds_csvs = { ...
    'Activated vs Non-Activated Cells Kurtosis All Cells.csv', ...
    'Activated vs Non-Activated Cells Norm Divergence All Cells.csv', ...
    'Dynein Inhibition Cells Kurtosis All Cells.csv', ...
    'Dynein Inhibition Cells Norm Divergence All Cells.csv'};

violin_csvs = { ...
    'CD3 Kurtosis.csv',         'CD3 Norm Divergence.csv', ...
    'PLL Kurtosis.csv',         'PLL Norm Divergence.csv', ...
    'DMSO Kurtosis.csv',        'DMSO Norm Divergence.csv', ...
    'Ciliobrevin Kurtosis.csv', 'Ciliobrevin Norm Divergence.csv'};

% =========================================================================
% Section 1: RDS-vs-time summary CSVs (header N's)
% =========================================================================
fprintf('\n=== 1. Sample sizes from RDS-vs-time summary CSVs ===\n\n');

% rds_n.<Condition>.<Metric> = N at row 1 (or NaN if missing)
rds_n = struct();

for k = 1:numel(rds_csvs)
    csv_path = fullfile(rds_dir, rds_csvs{k});
    T = readtable(csv_path, 'VariableNamingRule', 'preserve');
    var_names = T.Properties.VariableNames;
    n_cols = find(contains(var_names, 'Number of') & contains(var_names, 'Cells'));

    metric = parse_metric(rds_csvs{k});

    fprintf('-- %s  [metric: %s]\n', rds_csvs{k}, metric);
    if isempty(n_cols)
        fprintf('   No "Number of ... Cells" columns in this CSV.\n');
        fprintf('   (Will recover N from the per-cell Violin CSVs below.)\n\n');
        continue;
    end

    for c = 1:numel(n_cols)
        col_name = var_names{n_cols(c)};
        cond     = regexprep(col_name, '^Number of\s+', '');
        cond     = regexprep(cond, '\s+Cells$', '');
        N        = T{1, n_cols(c)};
        fprintf('   %s: n = %d\n', cond, N);
        rds_n.(safe_field(cond)).(safe_field(metric)) = N;
    end
    fprintf('\n');
end

% =========================================================================
% Section 2: per-cell ground truth from Violin Plot Data
% =========================================================================
fprintf('=== 2. Per-cell ground truth (Violin Plot Data) ===\n\n');

% violin_n.<Condition>.<Metric>      = unique cell count
% violin_cells.<Condition>.<Metric>  = cell-array of cell IDs ("date id")
violin_n     = struct();
violin_cells = struct();

for k = 1:numel(violin_csvs)
    T = readtable(fullfile(violin_dir, violin_csvs{k}), 'VariableNamingRule', 'preserve');
    cells = unique(T.('Cell Number'));
    [cond, metric] = parse_violin_name(violin_csvs{k});

    violin_n.(safe_field(cond)).(safe_field(metric))     = numel(cells);
    violin_cells.(safe_field(cond)).(safe_field(metric)) = cells;

    fprintf('   %-32s n = %2d unique cells   [%s, %s]\n', ...
        violin_csvs{k}, numel(cells), cond, metric);
end
fprintf('\n');

% =========================================================================
% Section 3: cross-check RDS summary vs. per-cell ground truth
% =========================================================================
fprintf('=== 3. Cross-check (RDS summary vs Violin per-cell) ===\n\n');

any_mismatch = false;
conds = {'CD3', 'PLL', 'DMSO', 'Ciliobrevin'};
metrics = {'Kurtosis', 'Norm Divergence'};

for ci = 1:numel(conds)
    for mi = 1:numel(metrics)
        cond_f = safe_field(conds{ci});
        met_f  = safe_field(metrics{mi});
        rds_val = NaN;
        if isfield(rds_n, cond_f) && isfield(rds_n.(cond_f), met_f)
            rds_val = rds_n.(cond_f).(met_f);
        end
        vio_val = NaN;
        if isfield(violin_n, cond_f) && isfield(violin_n.(cond_f), met_f)
            vio_val = violin_n.(cond_f).(met_f);
        end

        if isnan(rds_val) && ~isnan(vio_val)
            fprintf('   recovered  %s %s: n = %d  (RDS summary missing N column)\n', ...
                conds{ci}, metrics{mi}, vio_val);
        elseif ~isnan(rds_val) && ~isnan(vio_val) && rds_val ~= vio_val
            any_mismatch = true;
            fprintf('!! mismatch  %s %s: RDS summary n=%d, per-cell ground truth n=%d\n', ...
                conds{ci}, metrics{mi}, rds_val, vio_val);
        elseif ~isnan(rds_val) && ~isnan(vio_val)
            fprintf('   ok         %s %s: n = %d (both sources agree)\n', ...
                conds{ci}, metrics{mi}, rds_val);
        end
    end
end
if ~any_mismatch
    fprintf('\n   (No mismatches.)\n');
end
fprintf('\n');

% =========================================================================
% Section 4: cells dropped from Kurtosis but retained in Norm-Divergence
% =========================================================================
fprintf('=== 4. Cells in Norm-Divergence but NOT in Kurtosis ===\n\n');

for ci = 1:numel(conds)
    cond_f = safe_field(conds{ci});
    if ~isfield(violin_cells, cond_f) || ...
       ~isfield(violin_cells.(cond_f), safe_field('Kurtosis')) || ...
       ~isfield(violin_cells.(cond_f), safe_field('Norm Divergence'))
        continue;
    end
    kurt  = violin_cells.(cond_f).(safe_field('Kurtosis'));
    nd    = violin_cells.(cond_f).(safe_field('Norm Divergence'));
    dropped = setdiff(nd, kurt);
    extra   = setdiff(kurt, nd);

    fprintf('   %s: %d Norm-Div, %d Kurtosis, %d in Norm-Div only', ...
        conds{ci}, numel(nd), numel(kurt), numel(dropped));
    if ~isempty(extra)
        fprintf(', %d in Kurtosis only', numel(extra));
    end
    fprintf('\n');
    if ~isempty(dropped)
        fprintf('     dropped from Kurtosis: %s\n', cell_list_to_str(dropped));
    end
    if ~isempty(extra)
        fprintf('     in Kurtosis only:       %s\n', cell_list_to_str(extra));
    end
end
fprintf('\n');

% =========================================================================
% Helpers
% =========================================================================

function s = safe_field(name)
    s = regexprep(name, '[^A-Za-z0-9]', '_');
end

function s = cell_list_to_str(cells)
% Format a list of cell IDs as a comma-separated string. Handles both
% cell-of-char (CD3/PLL: "20220609 4") and numeric arrays (DMSO/Cilio: 10).
    if isnumeric(cells)
        s = strjoin(arrayfun(@num2str, cells(:)', 'UniformOutput', false), ', ');
    else
        s = strjoin(cells, ', ');
    end
end

function metric = parse_metric(csv_name)
    if contains(csv_name, 'Norm Divergence', 'IgnoreCase', true)
        metric = 'Norm Divergence';
    elseif contains(csv_name, 'Kurtosis', 'IgnoreCase', true)
        metric = 'Kurtosis';
    else
        metric = 'unknown';
    end
end

function [cond, metric] = parse_violin_name(csv_name)
    [~, base, ~] = fileparts(csv_name);
    if endsWith(base, 'Norm Divergence')
        metric = 'Norm Divergence';
        cond = strtrim(base(1:end-numel('Norm Divergence')));
    elseif endsWith(base, 'Kurtosis')
        metric = 'Kurtosis';
        cond = strtrim(base(1:end-numel('Kurtosis')));
    else
        metric = 'unknown';
        cond = base;
    end
end
