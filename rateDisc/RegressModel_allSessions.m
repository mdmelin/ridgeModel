clc;clear all;close all;
%runs encoding model over ALL sessions for given mouse/mice
addpath('C:\Data\churchland\ridgeModel\widefield');

diary RegressAllSessionsDiary_mSM6state %turn the diary on
cPath = 'X:\Widefield'
animal = 'mSM63'
glmfile = 'allaudio.mat';

wrkdir = [cPath filesep animal filesep 'SpatialDisc' filesep];
files = dir(wrkdir);
dirflags = [files.isdir];
subfolders = files(dirflags);
sessiondates = {subfolders(:).name};
numsess = length(sessiondates)

%% insert code here to get session metadata and apply more criteria before running model
%perhaps a minimum number of trials in the session

%%

for i = 1:numsess
    fprintf('\n\nRunning session number %i. Date is %s\n\n',i,sessiondates{i});
    if length(sessiondates{i}) > 2
        try
            ridgeModel_stateEncoding(cPath,animal,sessiondates{i},glmfile,[]);
        catch
            fprintf('something wrong with the session from this day...');
        end
    end
end
diary off