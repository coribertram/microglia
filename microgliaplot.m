function microgliaplot( filepath )
%% 
if nargin < 1 || isempty(filePath)
    [file, path] = uigetfile({'*.xlsx'},...
        'Excel File Selector');

    filePath = fullfile(path,file);
end

%% load in the file
microgliaTable = readtable(filePath);

%% 
cellIDs = unique(microgliaTable.Object_Label);
Object_Label = microgliaTable.Object_Label;
velocities = microgliaTable.velocityPerFrameMicronPerSec;
areaMicron = microgliaTable.Area_Micron2;

for i = 1:length(cellIDs)
  currentCell = cellIDs(i);
  currentCellVel= velocities(Object_Label == currentCell);
  
  currentCellArea = areaMicron(Object_Label == currentCell);
  
  figure("WindowState","maximized");
  
  ax1 = subplot(2,1,1);
  plot(ax1,1:length(currentCellVel), currentCellVel);
  title(['Velocity Cell Number: ' num2str(currentCell)]);
  
  ax1 = subplot(2,1,2);
  plot(ax1,1:length(currentCellVel), currentCellArea);
  title(['Area Cell Number: ' num2str(currentCell)]);
  
  tightfig(); 
  
  pause
  
  close();
    
end


end
