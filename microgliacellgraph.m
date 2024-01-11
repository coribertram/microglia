function microgliacellgraph (filePath)
if nargin < 1 || isempty(filePath)
    [file, path] = uigetfile({'*.xlsx'},...
        'Excel File Selector');

    filePath = fullfile(path,file);
end
%% load in the file
microgliaTable = readtable(filePath);
%% %% apply filters

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

[cnt_unique, unique_aF] = hist(microgliaTableFiltered.Object_Label,unique(microgliaTableFiltered.Object_Label));


%% resave
[path, name, ext] = fileparts(filePath);

savePath = fullfile(path, [name '_filtered_' ext]);

writetable(microgliaTableFiltered, savePath);

%% In and out of plexus filters
%filter microglia IN plexus
microgliaINPlexus = microgliaTableFiltered(microgliaTableFiltered.inPlexusFlag == 1,:);

%filter microglia OUT plexus
microgliaOUTPlexus = microgliaTableFiltered(microgliaTableFiltered.inPlexusFlag == 0,:);

%microglia in cluster cell group
microgliaCCC = microgliaTableFiltered(microgliaTableFiltered.inCC_Groups > 0,:);

%microglia in plexus, not in cluster cell group
microgliaplexusNoCCC= microgliaINPlexus(microgliaINPlexus.inCC_Groups== 0,:);




cellIDs = unique(microgliaTable.Object_Label);
Object_Label = microgliaTable.Object_Label;
velocities = microgliaTable.velocityPerFrameMicronPerSec;
areaMicron = microgliaTable.Area_Micron2;
velmax= max(velocities);
roundedvelmax= round(velmax *2)/2 ;
areamax= max(areaMicron);
roundedareamax= round(areamax *2)/2;



for i = 1:length(unique_aF)

    currentCell = unique_aF(i);
    currentCellVel= velocities(Object_Label == currentCell);
    currentCellArea = areaMicron(Object_Label == currentCell);

    figure("WindowState","maximized");

    ax1 = subplot(2,1,1);
    plot(ax1,1:length(currentCellVel), currentCellVel);
    title(['Velocity Cell Number: ' num2str(currentCell)]);
    ylim([0 roundedvelmax]);

    ax1 = subplot(2,1,2);
    plot(ax1,1:length(currentCellVel), currentCellArea);
    title(['Area Cell Number: ' num2str(currentCell)]);
    ylim ([0 roundedareamax]);
    tightfig();

    

    %% create folder

    saveDir = fullfile(path, 'Cell_Velocity_Area');

    if ~exist(saveDir,"dir")
        mkdir(saveDir);
    else
        delete(saveDir);
        mkdir (saveDir, "dir");
    end
    %% save graph

    saveas(gcf, fullfile(saveDir, ['Cell_Velocity_Area_'  sprintf('%03d', currentCell) '.png']));

    close();
end
end


