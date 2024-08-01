function updated_dirs = ensure_path_separator(base_dirs)
    % This function ensures that each directory path in the input cell array
    % ends with the appropriate file separator for the current operating system.
    % It halts execution with an error if a path does not end with a file separator,
    % providing a clear instruction to add a "/" or "\" at the end.

    % Initialize the output cell array
    updated_dirs = base_dirs;

    % Loop through each directory path in the input array
    for i = 1:length(updated_dirs)
        % Check if the path ends with the OS-specific file separator
        if ~strcmp(updated_dirs{i}(end), filesep)
            % Halt execution and display an error message with instructions
            error('Directory path "%s" does not end with the correct file separator. Please add a "/" or "\\" at the end!', updated_dirs{i});
        end
    end
end