function cleanMicrogliaCSV(csvFilepath)
% set remove flag for low area shapes and shapes which are in less than 3
% frames

areaLim = 100; % pixels ^2
frameNo = 3;

if nargin < 1 || isempty(csvFilepath)
   [file, path] = uigetfile({'*.csv;*.xlsx'},...
                          'Image File Selector');

   csvFilepath = fullfile(path,file);
end

csvTab = readtable(csvFilepath);

csvTab.object2Remove(csvTab.Area_Pixel2 <= areaLim) = 1;

objLab = unique(csvTab.Object_Label);
for i = 1:length(objLab)

    obj2Check = csvTab(csvTab.Object_Label == objLab(i),:);

    if height(obj2Check) < frameNo
        csvTab.object2Remove(csvTab.Object_Label == objLab(i)) = 1;
        obj2Check.object2Remove = ones(height(obj2Check),1);
    end

    writetable(obj2Check,csvFilepath,'Sheet', ['Cell_' num2str(i)]);

end

writetable(csvTab,csvFilepath,'Sheet', 'Original Table');

end