function cleanMicrogliaCSV_v2(csvFilepath)

%% defaults
if nargin < 1 || isempty(csvFilepath)
   [file, path] = uigetfile({'*.csv'},...
                          'Image File Selector');

   csvFilepath = fullfile(path,file);
end

areaLim = 100; % pixels ^2
frameNo = 3;
imageSz = 2048; % in pixels
boundaryLim = 25;  % in microns

%% read in data
microgliaTab = readtable(csvFilepath);

csvHeight = height(microgliaTab);
microgliaTab.object2Remove = zeros(csvHeight,1);
%% clean data

% remove objects by size
microgliaTab.object2Remove(microgliaTab.Area_Pixel2 <= areaLim) = 1;

% remove objects by number of frames
objLab = unique(microgliaTab.Object_Label);

% get eucildian image boundary
boundaryX = [ones(1,imageSz) 1:imageSz (ones(1,imageSz)* imageSz) imageSz:-1:1];
boundaryY = [1:imageSz (ones(1,imageSz)* imageSz) imageSz:-1:1 ones(1,imageSz)];

% pixel limit conversion
pixelLim = boundaryLim/microgliaTab.VoxelSpacing_X(1);

% for each object
for i = 1:length(objLab)
    obj2Check = microgliaTab(microgliaTab.Object_Label == objLab(i),:);

    % check if it is in the recording for longer than frameNo
    if height(obj2Check) < frameNo
        microgliaTab.object2Remove(microgliaTab.Object_Label == objLab(i)) = 1;
    end

    % get the minmum boundary distance for each frame object
    distPerFrame = pdist2([boundaryX;boundaryY]',[obj2Check.Centroid_X_Pixel obj2Check.Centroid_Y_Pixel],'euclidean', 'Smallest',1);

    if sum(distPerFrame < pixelLim) > 1
        microgliaTab.object2Remove(microgliaTab.Object_Label == objLab(i)) = 1;
    end
end

%% calculate other metrics

% add new table columns
microgliaTab.Area_Micron2 = zeros(csvHeight,1);
microgliaTab.ConvexArea_Micron2 = zeros(csvHeight,1);
microgliaTab.GeodesicDiameter_Micron = zeros(csvHeight,1);
microgliaTab.Perimeter_Micron = zeros(csvHeight,1);
microgliaTab.SkeletonAvgBranchLength_Micron = zeros(csvHeight,1);
microgliaTab.SkeletonLongestBranchLength_Micron = zeros(csvHeight,1);
microgliaTab.SkeletonTotalLength_Micron = zeros(csvHeight,1);
microgliaTab.DistanceMovePix = zeros(csvHeight,1);
microgliaTab.DistanceMoveMicron =  zeros(csvHeight,1);
microgliaTab.velocityPerFrameMicronPerSec = zeros(csvHeight,1);
microgliaTab.circularity = zeros(csvHeight,1);
microgliaTab.somaness = zeros(csvHeight,1);
microgliaTab.branchiness = zeros(csvHeight,1);


for i = 1:length(objLab)
    tempTab = microgliaTab(microgliaTab.Object_Label == objLab(i),:);

    P1 = [tempTab.Centroid_X_Pixel tempTab.Centroid_Y_Pixel];
    % add other metrics

    tempTab.Area_Micron2 = tempTab.Area_Pixel2 * tempTab.VoxelSpacing_X(1);
    tempTab.ConvexArea_Micron2 = tempTab.ConvexArea_Pixel2 * tempTab.VoxelSpacing_X(1);
    tempTab.GeodesicDiameter_Micron = tempTab.GeodesicDiameter_Pixel * tempTab.VoxelSpacing_X(1);
    tempTab.Perimeter_Micron = tempTab.Perimeter_Pixel * tempTab.VoxelSpacing_X(1);
    tempTab.SkeletonAvgBranchLength_Micron = tempTab.SkeletonAvgBranchLength_Pixel * tempTab.VoxelSpacing_X(1);
    tempTab.SkeletonLongestBranchLength_Micron = tempTab.SkeletonLongestBranchLength_Pixel * tempTab.VoxelSpacing_X(1);
    tempTab.SkeletonTotalLength_Micron = tempTab.SkeletonTotalLength_Pixel * tempTab.VoxelSpacing_X(1);


    % distance moved in pixels
    dists = pdist2(P1, P1,"euclidean" );
    inxd1 = 2:length(dists);
    indx2 = 1:length(dists)-1;
    indFromSub = sub2ind(size(dists),inxd1,  indx2);

    tempTab.DistanceMovePix = [0 dists(indFromSub)]';

    tempTab.DistanceMoveMicron =  tempTab.DistanceMovePix * tempTab.VoxelSpacing_X(1);

    tempTab.velocityPerFrameMicronPerSec = tempTab.DistanceMoveMicron ./tempTab.FrameInterval;

    tempTab.circularity = (4 * pi * tempTab.Area_Pixel2) ./(tempTab.Perimeter_Pixel .^2);

    tempTab.somaness = (tempTab.RadiusAtBrightestPoint_Pixel .^2) ./tempTab.Area_Pixel2;

    tempTab.branchiness = tempTab.SkeletonNumBranchPoints ./ tempTab.GeodesicDiameter_Pixel;

    microgliaTab(microgliaTab.Object_Label == objLab(i),:) = tempTab;
end

%% save the struct 

[folder, name] = fileparts(csvFilepath);

writetable(microgliaTab,fullfile(folder,[name '_corrected.xlsx']));

end