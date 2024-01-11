function microgliacellmatch (filePath1, filePath2, filePath3)
if nargin < 1 || isempty(filePath1)
    [file1, path1] = uigetfile({'*.xlsx'},...
        'Excel File Selector');

    filePath1 = fullfile(path1,file1)
end

if nargin < 1 || isempty(filePath2)
    [file2, path2] = uigetfile({'*.xlsx'},...
        'Excel File Selector');

    filePath2 = fullfile(path2,file2);
end

if nargin < 1 || isempty(filePath3)
    [file3, path3] = uigetfile({'*.xlsx'},...
        'Excel File Selector');

    filePath3 = fullfile(path3,file3);
end
%% load in the file
movie1 = readtable(filePath1);
movie2 = readtable(filePath2);
%% select frame
lastframe= max(movie1.Centroid_Time_Frames); 
firstframe= 1;
movie1LF= movie1 (movie1.Centroid_Time_Frames== lastframe, :);
movie2FF= movie2 (movie2.Centroid_Time_Frames== firstframe, :);

disp(movie1LF)
disp(movie2FF)

XYCol= {'Object_Label', 'Centroid_X_Pixel', 'Centroid_Y_Pixel'};

movie1XY= movie1LF(:, XYCol );
movie2XY= movie2FF(:, XYCol);

%% Compare cells
movie2XYMat = [movie2XY.Centroid_X_Pixel movie2XY.Centroid_Y_Pixel];
matchCellID(:,1)= movie1XY.Object_Label;
for c = 1 : height (movie1XY)
   
    currOb = [movie1XY.Centroid_X_Pixel(c) movie1XY.Centroid_Y_Pixel(c)] ;
    dists = pdist2(currOb, movie2XYMat,"euclidean");
    [minDist(c,1), matchIndx] = min(dists);

    matchCellID(c,2) = movie2XY.Object_Label(matchIndx);

end

end
