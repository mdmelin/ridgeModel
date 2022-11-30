clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; %CSP32 missing transparams


method = 'cutoff';
mintrialnum = 20; %the minimum number of trials per state to be included in plotting
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

%%
counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        [Vm,Vc] = return_reconstruction(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_fullmodel.mat');
        
        
        counter = counter + 1;
        fprintf('\ncounter is %i\n',counter);
    end
end