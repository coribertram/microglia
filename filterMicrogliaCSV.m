function filterMicrogliaCSV(filePath, sampLen)
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



% bar(cnt_unique);
%% apply filters

% microglia filter
microgliaTableFiltered = microgliaTable(microgliaTable.cellClusterFlag == 0,:);

if nargin < 2 || isempty(sampLen)
    sampLen = 20;
end

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

savePath = fullfile(path, [name '_filtered_' ext]);

writetable(microgliaTableFiltered, savePath);

%filter microglia IN plexus
microgliaINPlexus = microgliaTableFiltered(microgliaTableFiltered.inPlexusFlag == 1,:);

%filter microglia OUT plexus 
microgliaOUTPlexus = microgliaTableFiltered(microgliaTableFiltered.inPlexusFlag == 0,:);

%microglia in cluster cell group 
microgliaCCC = microgliaTableFiltered(microgliaTableFiltered.inCC_Groups > 0,:);

%microglia in plexus, not in cluster cell group 
microgliaplexusNoCCC= microgliaINPlexus(microgliaINPlexus.inCC_Groups== 0,:);
%% 


% Example: Select specific columns and rows (circularity)
MCCColumnscirc = microgliaCCC(:, [1, 46]); % Select 1 and 46
dataMCCcircHistogram = MCCColumnscirc{:,:}; % Convert table to array


MCCcrichistData = dataMCCcircHistogram(dataMCCcircHistogram(:,2)<1,2);

% Example: Create a histogram
figH = figure('Units','normalized',OuterPosition=[0 0 1 1]);
subplot(3,1,1);
histogram(MCCcrichistData,300);


% Add labels and title
xlabel('Circularity');
ylabel('Frequency');
title('Cirularity of Microglia in Cluster Cell Groups');


MIPNCcircColumns= microgliaplexusNoCCC(:, [1, 46]); % Select 1 and 46)
dataMIPNCcircHistogram = MIPNCcircColumns{:,:}; % Convert table to array

MIPNcircChistData= dataMIPNCcircHistogram (dataMIPNCcircHistogram (:,2)<1,2);


%figH = figure('Units','normalized',OuterPosition=[0 0 1 1]);
subplot(3,1,2);
histogram(gca, MIPNcircChistData,300);


% Add labels and title
xlabel('Circularity');
ylabel('Frequency');
title('Cirularity of Microglia in The Plexus, Not In Cluster Cell Groups');


MOPcircColumns= microgliaOUTPlexus(:, [1, 46]); % Select 1 and 46)
dataMOPcircHistogram = MOPcircColumns{:,:}; % Convert table to array

MOPcirchistData= dataMOPcircHistogram (dataMOPcircHistogram (:,2)<1,2);

%figH = figure('Units','normalized',OuterPosition=[0 0 1 1]);
subplot(3,1,3);
histogram(gca, MOPcirchistData,300);

% Add labels and title
xlabel('Circularity');
ylabel('Frequency');
title('Cirularity of Microglia Out of The Plexus');
%tightfig

subplotEvenAxes(gcf)
%% 

% Example: Select specific columns and rows (branchiness)
MCCbranchColumns = microgliaCCC(:, [1, 48]); % Select 1 and 48
dataMCCbranchHistogram = MCCbranchColumns{:,:}; % Convert table to array


MCCCbranchhistData = dataMCCbranchHistogram(dataMCCbranchHistogram(:,2)<1,2);

% Example: Create a histogram
figH = figure('Units','normalized',OuterPosition=[0 0 1 1]);
subplot(3,1,1);
histogram(MCCCbranchhistData,300);


% Add labels and title
xlabel('Branchiness');
ylabel('Frequency');
title('Branchiness of Microglia in Cluster Cell Groups');

MIPNCbranchColumns= microgliaplexusNoCCC(:, [1, 48]); % Select 1 and 48)
dataMIPNCbranchHistogram = MIPNCbranchColumns{:,:}; % Convert table to array

MIPNCbranchhistData= dataMIPNCbranchHistogram (dataMIPNCbranchHistogram (:,2)<1,2);


%figH = figure('Units','normalized',OuterPosition=[0 0 1 1]);
subplot(3,1,2);
histogram(gca, MIPNCbranchhistData,300);

% Add labels and title
xlabel('Branchiness');
ylabel('Frequency');
title('Branchiness of Microglia in The Plexus, Not In Cluster Cell Groups');



MOPbranchColumns= microgliaOUTPlexus(:, [1, 48]); % Select 1 and 48)
dataMOPbranchHistogram = MOPbranchColumns{:,:}; % Convert table to array

MOPbranchhistData= dataMOPbranchHistogram (dataMOPbranchHistogram (:,2)<1,2);

%figH = figure('Units','normalized',OuterPosition=[0 0 1 1]);
subplot(3,1,3);
histogram(gca, MOPbranchhistData,300);

% Add labels and title
xlabel('Branchiness');
ylabel('Frequency');
title('Branchiness of Microglia Out of The Plexus');
%tightfig

subplotEvenAxes(gcf)
%% 


lowerLim = 0;
upperLim =60;

% Example: Select specific columns and rows (distance moved micron)
MCCdmmColumns = microgliaCCC(:, [1, 44]); % Select 1 and 44
dataMCCdmmHistogram = MCCdmmColumns{:,:}; % Convert table to array


MCCdmmhistData = dataMCCdmmHistogram(dataMCCdmmHistogram (:,2)>lowerLim,2);
MCCdmmhistData = dataMCCdmmHistogram(dataMCCdmmHistogram (:,2)<upperLim,2);

% Example: Create a histogram
figH = figure('Units','normalized',OuterPosition=[0 0 1 1]);
subplot(3,1,1);
histogram(MCCdmmhistData, 200);


% Add labels and title
xlabel('Distance Moved in microns');
ylabel('Frequency');
title('Distance moved in microns by Microglia in Cluster Cell Groups');
% tightfig

MIPNCdmmColumns= microgliaplexusNoCCC(:, [1, 44]); % Select 1 and 44)
dataMIPNCdmmHistogram = MIPNCdmmColumns{:,:}; % Convert table to array

MIPNCdmmhistData= dataMIPNCdmmHistogram (dataMIPNCdmmHistogram (:,2)>lowerLim,2);
MIPNCdmmhistData= dataMIPNCdmmHistogram (dataMIPNCdmmHistogram (:,2)<upperLim,2);


%figH = figure('Units','normalized',OuterPosition=[0 0 1 1]);
subplot(3,1,2);
histogram(gca, MIPNCdmmhistData, 200);


% Add labels and title
xlabel('Distance moved in microns');
ylabel('Frequency');
title('Distance moved in microns by Microglia in The Plexus, Not In Cluster Cell Groups');
% tightfig



MOPdmmColumns= microgliaOUTPlexus(:, [1, 44]); % Select 1 and 44)
dataMOPdmmHistogram = MOPdmmColumns{:,:}; % Convert table to array

MOPdmmhistData= dataMOPdmmHistogram (dataMOPdmmHistogram (:,2)>lowerLim,2);
MOPdmmhistData= dataMOPdmmHistogram (dataMOPdmmHistogram (:,2)<upperLim,2);

% figH = figure('Units','normalized',OuterPosition=[0 0 1 1]);
subplot(3,1,3);
histogram(gca,MOPdmmhistData, 200);

% Add labels and title
xlabel('Distance moved in microns');
ylabel('Frequency');
title('Distance moved in microns by Microglia Out of The Plexus');
% tightfig

subplotEvenAxes(gcf)

end
