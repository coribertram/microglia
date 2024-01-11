function microgliagraphs (excelFilePath)

% defaults

%filepath = '\\campus\rdw\ion10\10\retina\data\microglia\Cori microglia analysis - Copy\20230217\Control\ret2_IB4_400-470-635_timelaps1_cluster_cleaned_C1_EDoF_corrected_cleaned_valid.xlsx';
% filepath = '\\campus\rdw\ion10\10\retina\data\microglia\Cori microglia analysis - Copy\20230217\Probenecid\ret2_IB4_400-470-635_timelaps2_probenecid-1mM_cluster_cleaned_C1_EDoF_corrected_cleaned_valid.xlsx';

if nargin < 1 || isempty(filePath)
    [file, path] = uigetfile({'*.xlsx'},...
        'Excel File Selector');

    filePath = fullfile(path,file);
end

%% load in the file
microgliaTable = readtable(filePath);


% visualise histogram of rec length
[cnt_unique, unique_a] = hist(microgliaTable.Object_Label,unique(microgliaTable.Object_Label));