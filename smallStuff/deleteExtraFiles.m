% This code deletes unnecessary files from simon's data structure. This
% helps keep data size small enought to keep locally

%disk = 'V:\StateProjectCentralRepo\Widefield_Sessions';
%mice = {'Fez73','Fez74','Fez75','mSM61','mSM62','mSM63','mSM64','mSM65','mSM66','Plex01','CSP22','CSP22a','CSP23',...
    'CSP22','CSP22a','CSP23','CSP31','CSP32','CSP38','CSP39','CSP40','CSP41','CSP44','Fez7','Fez8','Fez10','Fez71','Fez72'}; 

%disk = 'X:\Widefield';
%mice = {'mSM62','mSM63','mSM64','mSM65','mSM66','CSP22','CSP22a','CSP23','CSP31','CSP32','CSP38','CSP39','CSP40','CSP41','CSP44','Fez7','Fez8','Fez10','Fez71'};

disk = 'X:\Widefield';
%mice = {'mSM64copy'};

for i = 1:length(mice)

mouse = mice{i};
datapath = [disk filesep mouse filesep 'SpatialDisc' filesep];
datapath2 = [disk filesep mouse filesep];
files = dir(datapath);
dirFlags = [files.isdir];
foldernames = {files(dirFlags).name};
keepers = {'BehaviorVideo' 'SVD_CombinedSegments.mat', 'motionSVD_CombinedSegments.mat', 'bhvOpts.mat', 'FilteredPupil.mat', 'segInd1.mat','segInd2.mat','SVD_Cam'}; %These are the behavior files (within BehaviorVideo folder) that are used to train the model, don't delete these!
keepers2 = {'BehaviorVideo' 'Vc.mat','rsVc.mat','opts.mat','opts2.mat','opts3.mat','opts4.mat','opts5.mat'};
for i = 1:length(foldernames)
    if length(foldernames{i}) <= 2
        continue
    end
    
    bhvviddir = [disk filesep mouse filesep 'SpatialDisc' filesep foldernames{i} filesep 'BehaviorVideo'];
    files = dir(bhvviddir);
    fileFlags = ~[files.isdir];
    filenames = {files(fileFlags).name};
    filestodel = filenames(~ismember(filenames,keepers));
    
    bhvviddir2 = [disk filesep mouse filesep 'SpatialDisc' filesep foldernames{i}];
    filenames2 = {dir(bhvviddir2).name};
    temp = {dir([bhvviddir2 filesep 'Analog_*.dat']).name};
    temp2 = {dir([bhvviddir2 filesep '*_Session*.mat']).name};
    keepers2 = [keepers2,temp,temp2];
    filestodel2 = filenames2(~ismember(filenames2,keepers2));
    
    parfor j = 1:length(filestodel)
         delete([bhvviddir filesep filestodel{j}]);
         try
             rmdir([bhvviddir filesep filestodel{j}],'s');
         end
    end
    
    parfor j = 1:length(filestodel2)
         delete([bhvviddir2 filesep filestodel2{j}]);
    end    
    
end
end
