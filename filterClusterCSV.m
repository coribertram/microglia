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
% CCC filter
ClusterTable = microgliaTable(microgliaTable.cellClusterFlag == 1, :);

% length sampled filter
sampLen= 10; 
[cnt_unique, unique_a] = hist(ClusterTable.Object_Label,unique(ClusterTable.Object_Label));
cntInd = cnt_unique > sampLen;
objLabFilter = unique_a(cntInd);

% apply filter
ClusterTableFiltered = [];
for ob = 1:length(objLabFilter)
    temp = ClusterTable(ClusterTable.Object_Label == objLabFilter(ob), :);

    ClusterTableFiltered = vertcat(ClusterTableFiltered, temp);
end

[cnt_uniqueF, unique_aF] = hist(ClusterTableFiltered.Object_Label,unique(ClusterTableFiltered.Object_Label));


%% resave
[path, name, ext] = fileparts(filePath);

savePath = fullfile(path, [name '_Clusterfiltered_' num2str(sampLen) ext]);

writetable(ClusterTableFiltered, savePath);

% CCC in group 
end
