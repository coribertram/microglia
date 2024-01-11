function filterMicrogliaCSV(filePath, sampLen)
% defaults

%filepath = '\\campus\rdw\ion10\10\retina\data\microglia\Cori microglia analysis - Copy\20230217\Control\ret2_IB4_400-470-635_timelaps1_cluster_cleaned_C1_EDoF_corrected_cleaned_valid.xlsx';
% filepath = '\\campus\rdw\ion10\10\retina\data\microglia\Cori microglia analysis - Copy\20230217\Probenecid\ret2_IB4_400-470-635_timelaps2_probenecid-1mM_cluster_cleaned_C1_EDoF_corrected_cleaned_valid.xlsx';

if nargin < 1 || isempty(filePath)
    [file, path] = uigetfile({'*.xlsx'},...
        'Excel File Selector');

    filePath = fullfile(path,file);
end


% frame sample lengt
if nargin < 2 || isempty(sampLen)
    sampLen = 20;
end

%% load in the file
microgliaTable = readtable(filePath);

% visualise histogram of rec length
[cnt_unique, unique_a] = hist(microgliaTable.Object_Label,unique(microgliaTable.Object_Label));

% bar(cnt_unique);
%% apply filters

% microglia filter
microgliaTableFiltered = microgliaTable(microgliaTable.cellClusterFlag == 0,:);

% length sampled filter
[cnt_unique, unique_a] = hist(microgliaTable.Object_Label,unique(microgliaTable.Object_Label));
cntInd = cnt_unique > sampLen;
objLabFilter = unique_a(cntInd);

% apply filter
microgliaTableFiltered = [];
for ob = 1:length(objLabFilter)
    temp = microgliaTable(microgliaTable.Object_Label == objLabFilter(ob), :);

    microgliaTableFiltered = vertcat(microgliaTableFiltered, temp);
end

[cnt_uniqueF, unique_aF] = hist(microgliaTableFiltered.Object_Label,unique(microgliaTableFiltered.Object_Label));


%% resave
[path, name, ext] = fileparts(filePath);

savePath = fullfile(path, [name '_filtered_' num2str(sampLen) ext]);

writetable(microgliaTableFiltered, savePath);
end