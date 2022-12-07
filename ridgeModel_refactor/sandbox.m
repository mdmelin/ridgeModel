clc;clear all;close all;
%% Get the animals and sessions
addpath('C:\Data\churchland\ridgeModel\Max_Analysis')

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'};
glmFile = 'allaudio_detection.mat';
method = 'cutoff';

mintrialnum = 20; %the minimum number of trials per state to be included in plotting
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

%% pseudo-code

%select the trials
%generate the design matrix, return the labels too. Eventually break this out to a seperate function to generate one trial
%generate Vc

%for desired number of shuffles
%do any shuffling of design matrix if desired
%run the crossvalidation, this will also need to return discared regressors

%for number of folds
%ridgeMML
%end

%end
%save
%%
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        runRidge_fullAndShuffle(cPath,animals{1},sessiondates{1}{1},glmFile);
    end
end



