% This code deletes unnecessary files from simon's data structure. This
% helps keep data size small enought to keep locally

disk = 'V:\Temp'
mouse = 'CSP38'

datapath = [disk filesep mouse filesep 'SpatialDisc' filesep];
datapath2 = [disk filesep mouse filesep];
files = dir(datapath);
dirFlags = [files.isdir];
foldernames = {files(dirFlags).name};
keepers = {'SVD_CombinedSegments.mat', 'motionSVD_CombinedSegments.mat', 'bhvOpts.mat', 'FilteredPupil.mat', 'segInd1.mat','segInd2.mat','SVD_Cam'}; %These are the behavior files (within BehaviorVideo folder) that are used to train the model, don't delete these!
keepers2 = {'Vc.mat','rsVc.mat','opts.mat','opts2.mat','opts3.mat','opts4.mat','opts5.mat'};
for i = 1:length(foldernames)
    if length(foldernames{i}) <= 2
        continue
    end
    
    delfiles{1} = [datapath foldernames{i} filesep 'blueV.mat'];
    delfiles{2} = [datapath foldernames{i} filesep 'hemoV.mat'];
    delfiles{3} = [datapath foldernames{i} filesep 'firstV.mat'];
    delfiles{4} = [datapath foldernames{i} filesep 'allHemoAvg.mat'];
    delfiles{5} = [datapath foldernames{i} filesep 'allBlueAvg.mat'];
    delfiles{6} = [datapath foldernames{i} filesep 'fullcorr.mat'];
    delfiles{7} = [datapath foldernames{i} filesep 'regData.mat'];
    delfiles{8} = [datapath foldernames{i} filesep 'newAC_20_50.mat'];
    delfiles{9} = [datapath foldernames{i} filesep 'orthcorr.mat'];
    delfiles{10} = [datapath foldernames{i} filesep 'spontMotorregData.mat'];
    delfiles{11} = [datapath foldernames{i} filesep 'orgfullcorr.mat'];
    delfiles{12} = [datapath foldernames{i} filesep 'NTorgfullcorr.mat'];
    delfiles{13} = [datapath foldernames{i} filesep 'choicefullcorr.mat'];
 
    
    bhvviddir = [disk filesep mouse filesep 'SpatialDisc' filesep foldernames{i} filesep 'BehaviorVideo'];
    files = dir(bhvviddir);
    fileFlags = ~[files.isdir];
    filenames = {files(fileFlags).name};
    filestodel = filenames(~ismember(filenames,keepers));
    
    bhvviddir2 = [disk filesep mouse filesep 'SpatialDisc' filesep foldernames{i}];
    files2 = dir(bhvviddir2);
    fileFlags2 = ~[files2.isdir];
    filenames2 = {files2(fileFlags2).name};
    temp = {dir([bhvviddir2 filesep 'Analog_*.dat']).name};
    temp2 = {dir([bhvviddir2 filesep '*_Session*.mat']).name};
    keepers2 = [keepers2,temp,temp2];
    filestodel2 = filenames2(~ismember(filenames2,keepers2));
    
    
    
    parfor j = 1:length(delfiles)
         delete(delfiles{j});
    end
    
    parfor j = 1:length(filestodel)
         delete([bhvviddir filesep filestodel{j}]);
    end
    
    parfor j = 1:length(filestodel2)
         delete([bhvviddir2 filesep filestodel2{j}]);
    end    
    
end
