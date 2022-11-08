clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';


method = 'cutoff';
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data
SAVEPATH = 'X:\'
%% rerun encoding model - general variable groups
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        [inds, attendinds,biasinds,~, postprobs_sorted] = getStateInds('X:/Widefield',animals{i},sessiondates{i}{j},'cutoff','allaudio_detection.mat',true);
        fname = [SAVEPATH filesep animals{i} '_' sessiondates{i}{j}];
        save(fname,'postprobs_sorted');
    end
end