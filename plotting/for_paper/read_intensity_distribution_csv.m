function frames = read_intensity_distribution_csv(csv_path)
% Parse the non-tabular IntensityDistribution.csv format produced by the BARCODE
% Analysis pipeline. Each frame is a 3-line block:
%   Frame N
%   <bin centers, comma-separated>
%   <P(I) values, comma-separated>
% separated by a blank line.
%
% Returns a struct array with fields:
%   frame_number  - scalar integer
%   bins          - 1xN double, bin centers
%   pdf           - 1xN double, P(I) at each bin (sums ~= 1)

    text  = fileread(csv_path);
    lines = regexp(text, '\r?\n', 'split');

    frames = struct('frame_number', {}, 'bins', {}, 'pdf', {});
    i = 1;
    while i <= numel(lines)
        line = strtrim(lines{i});
        if startsWith(line, 'Frame')
            idx = numel(frames) + 1;
            frames(idx).frame_number = sscanf(line, 'Frame %d');
            frames(idx).bins = str2double(strsplit(strtrim(lines{i+1}), ','));
            frames(idx).pdf  = str2double(strsplit(strtrim(lines{i+2}), ','));
            i = i + 3;
        else
            i = i + 1;
        end
    end
end
