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
%TODO: move trial selection outside of first function
%TODO: separate out video alignment and imaging alignment in python
NFOLDS = 10;
REJECT_EMPTY_REGRESSORS = true;
REJECT_RANK_DEFICIENT = true;
FILENAME = 'deleteme';
TASK = 'SpatialDisc';

[regLabels,regIdx,fullR,regZeroFrames,zeromeanVc,U] = ridgeModel_returnDesignMatrix(cPath,animals{1},sessiondates{1}{1},glmFile,'attentive',[]);
shuffleLabels = regLabels(1:30);
shuffledDesignMatrix = shuffleDesignMatrix(regLabels,regIdx,fullR,shuffleLabels); %pass shuffle indices or labels here
[Vm, betas, RwithRejections, lambdas, rejIdx, cMap, cMovie] = ridgeRegressionCrossvalidate(fullR,U,zeromeanVc,regLabels,regIdx,75,NFOLDS,REJECT_EMPTY_REGRESSORS,REJECT_RANK_DEFICIENT); %need to adjust kernel zero points if they get discarded, or maybe make them nans

rejectedAlignmentFrameLabels = regLabels(regIdx(rejIdx & regZeroFrames));%check if the alignment event frames got rejected
fprintf('WARNING: The alignment frame for %s was rejected. \n', rejectedAlignmentFrameLabels{:});

R = RwithRejections;
regIdx = regIdx(~rejIdx);
regLabels = regLabels(unique(regIdx));

temp = []; count = 1;
for i = unique(regIdx)
    temp(regIdx == i) = count;
    count = count+1;
end
regLabels = temp;

saveEncodingModelResults(cPath,animals{1},sessiondates{1}{1}, FILENAME, Vm, Vc, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels);




