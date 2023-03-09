function imageSet2BIDS(folder2Process, stringID, saveDir, saveFolderName, resolution, rawImageType, speciesText, sampleText, imageModeText)
% Function converts a folder of images which have axondeepseg masks created
% into BIDS format such that it will run with the ivadomed training
% package. Assumes all images are in the same folder and have a common root
% name, i.e LM-1.tif, LM-24.tif etc 
%
% Inputs:   folder2Process- fullfile to folder containing images
%
%           stringID- root common string for all the images
%
%           saveDir- save location for the BIDS folder
%
%           saveFolderName- string of save folder name
%
%           resolution- image resolution in micron per pixel
%
%           rawImageType- image suffix for microscopy images,
%                         DEFAULT- '.tif'
%
%           speciesText- species text to use for metadata, 
%                        DEFAULT- 'macaca mulatta'
%
%           sampleText- sample type text used for metadata, 
%                       DEFAULT- 'tissue'
%
%           imageModeText- image modality suffix used for identification
%                          DEFAULT- 'BF'
%
% Usage: imageSet2BIDS('/Data1/FirminData/LM/Pictures_raw/20_segmentations_trained', 'LM', '/Data1/FirminData', 'test2',0.064);
%        imageSet2BIDS('/Data1/Training/Training_Set_ellipse', 'LM', '/Data1/Training', 'Training_Set_ellipsePNG',0.064);
% Written 20220401 M.Savage msavage2@ncl.ac.uk
%% defaults

if nargin < 6 || isempty(rawImageType)
    rawImageType = '.tif';
end

if nargin < 7 || isempty(speciesText)
    speciesText = 'macaca mulatta';
end

if nargin < 8 || isempty(sampleText)
    sampleText = 'tissue';
end

if nargin < 9 || isempty(imageModeText)
    imageModeText = 'BF';
end

% maskSufix = [{'seg-myelin.'},{'seg-axon.'}]; % masks to extract
maskSufix = [{'seg-Mask.'}]; % masks to extract


%% get image paths

% get raw image filepaths
rawImagesFilepaths = dir(fullfile(folder2Process,[stringID '*'  rawImageType]));

% remove any mask images from raw data
index2Remove = contains({rawImagesFilepaths.name}, 'seg');
rawImagesFilepaths(index2Remove) =[];

% get the mask image filepaths
for i =1:length(maskSufix)
   maskImageFilePaths{i} = dir(fullfile(folder2Process,[stringID '*'  maskSufix{i} '*']));
end

rawImagesNames = {rawImagesFilepaths.name};

% get image IDs without underscore (illegal character in ivadomed)
fileNames = cellfun(@(x) x(1:end-4), rawImagesNames, 'Un', 0); % remove filetype suffix
fileNames = cellfun(@(x) strrep(x,'_',''), fileNames, 'Un', 0); % remove underscore
fileNames = cellfun(@(x) strrep(x,'-',''), fileNames, 'Un', 0); % remove hyphen


%% create saveDir file struct

for imageNo = 1:length(rawImagesFilepaths)
   mkdir(fullfile(saveDir, saveFolderName, 'derivatives','labels',['sub-' fileNames{imageNo}],'micr'));
   mkdir(fullfile(saveDir, saveFolderName, ['sub-' fileNames{imageNo}],'micr'));
end

%% create all the text files

% dataset_description

fid = fopen(fullfile(saveDir, saveFolderName, 'dataset_description.json'), 'w');

fprintf(fid,[ '{\n\t"Name": "%s",\n\t' ...
    '"BIDSVersion": "1.7.0",\n\t' ...
    '"License": "MIT" \n}'],saveFolderName);

fclose(fid);

% partipants.json
fid = fopen(fullfile(saveDir, saveFolderName, 'participants.json'), 'w');

fprintf(fid,[ '{\n\t"participant_id": {\n\t\t' ...
    '"Description": "Unique participant ID" \n\t' ...
    '}, \n\t' ...
    '"species": { \n\t\t' ...
    '"Description": "Binomial species name from the NCBI Taxonomy (https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi)"\n\t' ...
    '} \n}']);
    
fclose(fid);

% partipants.tsv
fid = fopen(fullfile(saveDir, saveFolderName, 'participants.tsv'), 'w');

fprintf(fid,'%s\t%s\n','participant_id','species');
for i = 1:length(rawImagesFilepaths)
    fprintf(fid ,'sub-%s\t%s\n' ,rawImagesFilepaths(i).name(1:end-4), speciesText);
end

fclose(fid);

% samples.tsv
fid = fopen(fullfile(saveDir, saveFolderName, 'samples.tsv'), 'w');

fprintf(fid,'%s\t%s\t%s\n', 'sample_id', 'participant_id','sample_type');
for i = 1:length(rawImagesFilepaths)
    fprintf(fid ,'sample-data%s\tsub-%s\t%s\n' ,num2str(i),rawImagesFilepaths(i).name(1:end-4), sampleText);
end

fclose(fid);

% pixel size per image

for i =1:length(rawImagesFilepaths)
    fid = fopen(fullfile(saveDir, saveFolderName, ['sub-' fileNames{i}],'micr', ...
        ['sub-' fileNames{i} '_sample-data' num2str(i) '_' imageModeText '.json' ]), 'w');
    
  fprintf(fid,[ '{\n\t "PixelSize": [%s, %s],\n\t\t' ...
    '"PixelSizeUnits": "um" \n}'], num2str(resolution), num2str(resolution));
    
fclose(fid);
end


%% save all the images

for i =1:length(rawImagesFilepaths)

    rawImage = imread(fullfile(rawImagesFilepaths(i).folder,rawImagesFilepaths(i).name));
    
    numDim = ndims(rawImage);
    
    if numDim == 2
        options.color = false;
    elseif numDim == 3
        options.color = true;
    end
    
%     saveastiff(rawImage,fullfile(saveDir, saveFolderName, ['sub-' fileNames{i}],'micr', ...
%         ['sub-' fileNames{i} '_sample-data' num2str(i) '_' imageModeText '.tif']), options);
%     
    imwrite(rawImage,fullfile(saveDir, saveFolderName, ['sub-' fileNames{i}],'micr', ...
        ['sub-' fileNames{i} '_sample-data' num2str(i) '_' imageModeText '.png']));
    
    for x = 1:length(maskImageFilePaths)
       maskImage = imread(fullfile(maskImageFilePaths{x}(i).folder,maskImageFilePaths{x}(i).name));
       
       options.color = false;
%         saveastiff(maskImage,fullfile(saveDir, saveFolderName, 'derivatives','labels',['sub-' fileNames{i}],'micr', ...
%         ['sub-' fileNames{i} '_sample-data' num2str(i) '_' imageModeText '_' maskSufix{x}(1:end-1) '-manual.tif']), options);

 imwrite(maskImage,fullfile(saveDir, saveFolderName, 'derivatives','labels',['sub-' fileNames{i}],'micr', ...
        ['sub-' fileNames{i} '_sample-data' num2str(i) '_' imageModeText '_' maskSufix{x}(1:end-1) '-manual.png']));
    end
end


end