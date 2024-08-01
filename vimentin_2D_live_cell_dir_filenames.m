%% specify directories, cell numbers, and formatting of the cell names

base_dirs = {'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220609_mCherry-Vimentin_SinglePlane\Cells\'};
cell_number = {1:4}; % specify the cells to consider in each directory
params.prefix = 'Cell'; % adjust as needed

% base_dirs = {
%     'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220623_mCherry-Vimentin_SinglePlane\Cells_PLL\', 
%     'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220623_mCherry-Vimentin_SinglePlane\Cells_CD3\'
% };
% cell_number = {1:5, 1:8}; % specify the cells to consider in each directory
% params.prefix = 'Cell'; % adjust as needed

% base_dirs = {
%     'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220719_mCherry-Vimentin_SinglePlane\Cells_PLL\', 
%     'G:\FF\Vimentin_Project_2ndharddrive\vimentin_contraction\2D\mCherry-Vimentin\20220719_mCherry-Vimentin_SinglePlane\Cells_CD3\'
% };
% cell_number = {1:9, 1:10}; % specify the cells to consider in each directory
% params.prefix = 'Cell'; % adjust as needed

% base_dirs = {
%     'H:\FF\Vimentin_Data\20221103_mCherry-Vimentin_EGFP-Centrin-2_live_glass\PLL\cells\time_series\channels\', 
%     'H:\FF\Vimentin_Data\20221103_mCherry-Vimentin_EGFP-Centrin-2_live_glass\aCD3\cells\time_series\channels\'
% };
% cell_number = {horzcat(1:3, 5), horzcat(1:3, 5, 8:9)}; % specify the cells to consider in each directory
% params.prefix = 'C1-Cell'; % adjust as needed

% base_dirs = {'G:\FF\Vimentin_Project_2ndharddrive\20230203_mCherry-Vimentin_EGFP-Centrin-2\For Vimentin Contraction Analysis\No Treatment - aCD3\individual channels\'};
% cell_number = {1:4}; % specify the cells to consider in each directory
% params.prefix = 'C1-cell'; % adjust as needed

% base_dirs = {
%     'H:\FF\Vimentin_Data\Ciliobrevin_live\Cell DMSO\', 
%     'H:\FF\Vimentin_Data\Ciliobrevin_live\Cell Ciliobrevin\'
% };
% cell_number = {1:21, 1:19}; % specify the cells to consider in each directory
% params.prefix = 'cell'; % adjust as needed