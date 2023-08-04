function imageSet2BIDSMicroglia(folder2Process, saveDir, resolution, speciesText, sampleText, imageModeText)
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

if nargin < 4 || isempty(speciesText)
    speciesText = 'mus musculus';
end

if nargin < 5 || isempty(sampleText)
    sampleText = 'tissue';
end

if nargin < 6 || isempty(imageModeText)
    imageModeText = 'FLUO';
end

% maskSufix = [{'seg-myelin.'},{'seg-axon.'}]; % masks to extract
maskSufix = {'labelMasks.'}; % masks to extract


%% get image paths

% get raw image filepaths
rawImagesFilepaths = dir(fullfile(folder2Process,'*tif'));

% remove any mask images from raw data
index2Remove = contains({rawImagesFilepaths.name}, 'labelMasks');
rawImagesFilepaths(index2Remove) =[];

% get the mask image filepaths
% for i =1:length(maskSufix)
%    maskImageFilePaths{i} = dir(fullfile(folder2Process,['*'  maskSufix{i} '*']));
% end
maskImageFilePaths = dir(fullfile(folder2Process,['*'  maskSufix{1} '*']));

rawImagesNames = {rawImagesFilepaths.name};

% get image IDs without underscore (illegal character in ivadomed)
fileNames = cellfun(@(x) x(1:end-4), rawImagesNames, 'Un', 0); % remove filetype suffix
% fileNames = cellfun(@(x) strrep(x,'_',''), fileNames, 'Un', 0); % remove underscore
fileNames = cellfun(@(x) strrep(x,'-','_'), fileNames, 'Un', 0); % remove hyphen

% rename fileNames as eye01, eye02 etc
for dd = 1:size(fileNames,2)
    fileRenames{dd} = sprintf('eye%03i',dd);
end

%% create saveDir file struct

for imageNo = 1:length(rawImagesFilepaths)
    mkdir(fullfile(saveDir, 'derivatives','labels',['sub-' fileRenames{imageNo}],'micr'));
    mkdir(fullfile(saveDir, ['sub-' fileRenames{imageNo}],'micr'));
end


%% save all the images

% for each subject/recording
for i =1:length(rawImagesFilepaths)

    [subjectImage, metaData{i}] = readFLAMEData(fullfile(rawImagesFilepaths(i).folder,rawImagesFilepaths(i).name));

    [maskImage] = readFLAMEData(fullfile(maskImageFilePaths(i).folder,maskImageFilePaths(i).name));


    %     numDim = ndims(rawImage);
    %
    %     if numDim == 2
    %         options.color = false;
    %     elseif numDim == 3
    %         options.color = true;
    %     end

    %     saveastiff(rawImage,fullfile(saveDir, saveFolderName, ['sub-' fileNames{i}],'micr', ...
    %         ['sub-' fileNames{i} '_sample-data' num2str(i) '_' imageModeText '.tif']), options);
    %

    % save each subject image individually
    for q = 1:size(subjectImage,3)
        imwrite(subjectImage(:,:,q),fullfile(saveDir, ...
            ['sub-' fileRenames{i}], ...
            'micr', ...
            sprintf('sub-%s_sample-data%03i_%s.png',fileRenames{i},q,imageModeText)));
    end

    % save each mask image individually
    for q = 1:size(subjectImage,3)
        imageTemp = logical(maskImage(:,:,q));
        imageTemp = uint16(imageTemp * (2^16));
        imwrite(imageTemp,fullfile(saveDir, ...
            'derivatives',...
            'labels',...
            ['sub-' fileRenames{i}], ...
            'micr', ...
            sprintf('sub-%s_sample-data%03i_%s_%s.png',fileRenames{i},q,imageModeText,maskSufix{1}(1:end-1))));
    end
end


%% create all the text files

% dataset_description

fid = fopen(fullfile(saveDir, 'dataset_description.json'), 'w');

fprintf(fid,[ '{\n\t"Name": "%s",\n\t' ...
    '"BIDSVersion": "1.7.0",\n\t' ...
    '"License": "MIT" \n}'],saveDir);

fclose(fid);

% partipants.json
fid = fopen(fullfile(saveDir, 'participants.json'), 'w');

fprintf(fid,[ '{\n\t"participant_id": {\n\t\t' ...
    '"Description": "Unique participant ID" \n\t' ...
    '}, \n\t' ...
    '"species": { \n\t\t' ...
    '"Description": "Binomial species name from the NCBI Taxonomy (https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi)"\n\t' ...
    '} \n}']);

fclose(fid);

% partipants.tsv
fid = fopen(fullfile(saveDir, 'participants.tsv'), 'w');

fprintf(fid,'%s\t%s\n','participant_id','species');
for i = 1:length(rawImagesFilepaths)
    fprintf(fid ,'sub-%s\t%s\n' ,fileRenames{i}, speciesText);
end

fclose(fid);

% pixel size per subject

for i =1:length(rawImagesFilepaths)
    resolution = metaData{i}.pixelDimensions(1);
    fid = fopen(fullfile(saveDir, ['sub-' fileRenames{i}],'micr', ...
        ['sub-' fileRenames{i} '_' imageModeText '.json' ]), 'w');

    fprintf(fid,[ '{\n\t "PixelSize": [%s, %s],\n\t\t' ...
        '"PixelSizeUnits": "um" \n}'], num2str(resolution), num2str(resolution));

    fclose(fid);
end

% for i =1:length(rawImagesFilepaths)
%     fid = fopen(fullfile(saveDir, ['sub-' fileNames{i}],'micr', ...
%         ['sub-' fileNames{i} '_sample-data' num2str(i) '_' imageModeText '.json' ]), 'w');
%
%   fprintf(fid,[ '{\n\t "PixelSize": [%s, %s],\n\t\t' ...
%     '"PixelSizeUnits": "um" \n}'], num2str(resolution), num2str(resolution));
%
% fclose(fid);
% end


% samples.tsv
% contains all the image names etc
fid = fopen(fullfile(saveDir, 'samples.tsv'), 'w');

fprintf(fid,'%s\t%s\t%s\n', 'sample_id', 'participant_id','sample_type');
for i = 1:length(rawImagesFilepaths)
    for aa = 1:metaData{i}.timePoints
    fprintf(fid ,'sample-data%03i\tsub-%s\t%s\n' ,aa,fileRenames{i}, sampleText);
    end
end

fclose(fid);

end