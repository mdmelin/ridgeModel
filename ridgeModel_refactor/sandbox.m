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

[regLabels,regIdx,fullR,regZeroFrames,zeromeanVc] = ridgeModel_returnDesignMatrix(cPath,animals{1},sessiondates{1}{1},glmFile,'attentive',[]);
%need to return the kernel zero points in the functionn above, make NaN if
%analog
% shuffleLabels = regLabels(1:30);
shuffledDesignMatrix = shuffleDesignMatrix(regLabels,regIdx,fullR,shuffleLabels); %pass shuffle indices or labels here
ridgeRegressionCrossvalidate(); %need to adjust kernel zero points if they get discarded, or maybe make them nans
saveEncodingModelResults();

%TODO: move trial selection outside of first function
%TODO: separate out video alignment and imaging alignment in python
