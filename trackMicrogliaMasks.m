function reclassImage = trackMicrogliaMasks(maskPath, erodeFlag)

% defaults
if nargin < 2
    erodeFlag = 0;
end

hardCentroidDistLimPix = 75; % search radius in pixels

try
    gpuArray(1);
    canUseGPU=false;
catch
    canUseGPU=false;
end

%% load in data

if isstring(maskPath)
    masks = read_Tiffs(maskPath);

    if canUseGPU == true
        masks = gpuArray(masks);
    end
else
    if canUseGPU == true
        masks = gpuArray(maskPath);
    else
        masks = maskPath;
    end
end

%% get improps

% for each image
for i = 1: size(masks,3)-1

    disp(['On Frame ' num2str(i) ' of ' num2str(size(masks,3))]);
    % if we are looking at first image, use the raw masks
    if i == 1
        currImage = masks(:,:,i);
        curImProps = struct2cell(regionprops(currImage, "PixelIdxList"));

        % clean image props to remove blanks and very small objects
        currImLens = cellfun(@length, curImProps);
        currImFilterNums = find(currImLens < 100);

        currImage = changem(currImage, [zeros(length(currImFilterNums),1)], [currImFilterNums]); % replace all small objects with zero
        currImage =  changem(currImage, [0:length(unique(currImage))-1], [unique(currImage)]); % renumber the array

        if erodeFlag == 1
            % erode image by 1 pixel
            se = strel('disk', 1, 0);
            binaryImage = currImage > 0; % Threshold.
            mask = imerode(binaryImage, se);
            currImage(~mask) = 0;
        end

        reIndexStack = currImage;
    else % otherwise use the last image in the cleaned aligned stack

        currImage = reIndexStack(:,:,i);

    end

    if erodeFlag == 1
        % erode image by 1 pixel
        nextImage = masks(:,:,i+1);
        binaryImage = nextImage > 0; % Threshold.
        mask = imerode(binaryImage, se);
        nextImage(~mask) = 0;
    else
        nextImage = masks(:,:,i+1);
    end

    nextImProps =  struct2cell(regionprops(nextImage, "PixelIdxList"));

    % clean image props to remove blanks and very small objects
    nextImLens = cellfun(@length, nextImProps);
    nextImFilterNums = find(nextImLens < 100);

    nextImage = changem(nextImage, [zeros(length(nextImFilterNums),1)], [nextImFilterNums]); % replace all small objects with zero
    nextImage =  changem(nextImage, [0:length(unique(nextImage))-1], [unique(nextImage)]); % renumber the array

    %     % get filtered image objects
    %     curImPropsFiltered = struct2cell(regionprops(currImage, "PixelIdxList"));
    %     nextImPropsFiltered = struct2cell(regionprops(nextImage, "PixelIdxList"));

    % run through all objects in current and next frame looking for
    % highest correlation matches

    currentIndexes = unique(currImage);
    currentIndexes = currentIndexes(2:end); % remove the 0 from the index list

    nextIndexes = unique(nextImage);
    nextIndexes = nextIndexes(2:end); % remove the 0 from the index list

    corrMat = [];

    % get the center distances to use a filter in whether to try
    % correlation
    currImCenter = regionprops(currImage,"Centroid");
    currImCenter = [currImCenter.Centroid];
    currImCenter = reshape(currImCenter,2,[])';

    nextImCenter = regionprops(nextImage,"Centroid");
    nextImCenter = [nextImCenter.Centroid];
    nextImCenter = reshape(nextImCenter,2,[])';

    distCenters = pdist2(currImCenter, nextImCenter, "euclidean" );
    distCenters = distCenters(currentIndexes,:);

    nIndLen = length(nextIndexes);
    parfor ob = 1:length(currentIndexes) % clean this up here so remove if statement....
        %     for ob = 1:length(currentIndexes) % clean this up here so remove if statement....

        for n = 1:nIndLen

            if distCenters(ob,n) < hardCentroidDistLimPix
                curImOb = ismember(currImage, currentIndexes(ob));
                nextImOb = ismember(nextImage,  nextIndexes(n));

                corrMat(ob, n) = corr2(curImOb, nextImOb);

            end
        end
    end

    [maxCorr, matchIndx] = max(corrMat, [],2);

    % build the next aligned stack for the current frames

    if canUseGPU == true
        maxInd = double(gather(max(reIndexStack(:)))+1); % has to be double for multiplication below
    else
        maxInd = max(reIndexStack(:))+1;
    end

    %     maxInd = max(reIndexStack(:))+1;

    currIndx = []; % blank out before filling for each frame

    for ee = 1:length(nextIndexes)  % for all objects in the next image
        if ismember(nextIndexes(ee),matchIndx) % see if it has a match in the previous image

            % get the matching index for this object
            currentMatchingIndx = currentIndexes(find(matchIndx == nextIndexes(ee)));

            % if there are more than two choose the one that has the
            % highest correlation
            if length(currentMatchingIndx) > 1
                overlappedIndx = find(matchIndx == nextIndexes(ee)); % indexing within the unique numbers in the next image
                [~, tempIndx] = max(maxCorr(overlappedIndx));
                currentMatchingIndx = currentIndexes(overlappedIndx(tempIndx));
            end

            if canUseGPU == true
                currentMatchingIndx = gather(currentMatchingIndx);  % has to be double for multiplication below
            end

            currIndx(:,:,ee) = ismember(nextImage, nextIndexes(ee)) * double(currentMatchingIndx);

            %             nextImOb = gather(ismember(nextImage,  ee));
            %             prevImOb = gather(ismember(currImage, currentIndexes(find(matchIndx == ee))));
            %             C = imfuse(prevImOb,nextImOb,'falsecolor','Scaling','joint','ColorChannels',[1 2 0]);
            %             imshow(C);
            %             C;
        else
            currIndx(:,:,ee) = ismember(nextImage, ee)* double(maxInd) ;
            maxInd = maxInd +1;
        end
    end

    % get the max for the next frame
    reIndexStack(:,:,i+1) = max(currIndx,[],3);
end

if canUseGPU == true
    reclassImage = gather(reIndexStack);
else
    reclassImage = reIndexStack;
end

% saveastiff(saveIm, '\\campus\rdw\ion10\10\retina\data\microglia\Cori microglia analysis - Copy\20230220\Control1\testAlign.tif');
end