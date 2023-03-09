function splitMicrogliaCSV(csvFilepath)

if nargin < 1 || isempty(csvFilepath)
   [file, path] = uigetfile({'*.csv'},...
                          'Image File Selector');

   csvFilepath = fullfile(path,file);
end


csvTab = readtable(csvFilepath);
tableLen = height(csvTab);

% add new table columns
csvTab.Area_Micron2 = zeros(tableLen,1);
csvTab.ConvexArea_Micron2 = zeros(tableLen,1);
csvTab.GeodesicDiameter_Micron = zeros(tableLen,1);
csvTab.Perimeter_Micron = zeros(tableLen,1);
csvTab.SkeletonAvgBranchLength_Micron = zeros(tableLen,1);
csvTab.SkeletonLongestBranchLength_Micron = zeros(tableLen,1);
csvTab.SkeletonTotalLength_Micron = zeros(tableLen,1);
csvTab.DistanceMovePix = zeros(tableLen,1);
csvTab.DistanceMoveMicron =  zeros(tableLen,1);
csvTab.velocityPerFrameMicronPerSec = zeros(tableLen,1);
csvTab.circularity = zeros(tableLen,1);
csvTab.somaness = zeros(tableLen,1);
csvTab.branchiness = zeros(tableLen,1);

cellNum = max(csvTab.Object_Label);

writetable(csvTab,[csvFilepath(1:end-4) '_Split.xlsx'],'Sheet', 'Original Table');

for i = 1:cellNum
    tempTab = csvTab(csvTab.Object_Label == i,:);

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

    tempTab.circularity = tempTab.Area_Pixel2 ./(tempTab.Perimeter_Pixel .^2);

    tempTab.somaness = (tempTab.RadiusAtBrightestPoint_Pixel .^2) ./tempTab.Area_Pixel2;

    tempTab.branchiness = tempTab.SkeletonNumBranchPoints ./ tempTab.GeodesicDiameter_Pixel;

    csvTab(csvTab.Object_Label == i,:) = tempTab;

    writetable(tempTab,[csvFilepath(1:end-4) '_Split.xlsx'],'Sheet', ['Cell_' num2str(i)]);
end

writetable(csvTab,[csvFilepath(1:end-4) '_Split.xlsx'],'Sheet', 'Original Table');


end