clc;clear all;close all;
%% Get the animals and sessions
addpath('C:\Data\churchland\ridgeModel\Max_Analysis')

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'};
glmFile = 'allaudio_detection.mat';
method = 'cutoff';

mintrialnum = 20; %the minimum number of trials per state to be included in plotting
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data


%% Toy example showing that the shuffle drops R2 to zero
% for i = 1:length(animals)
%     for j = 1:length(sessiondates{i})
%         fprintf('\nRunning for %s, %s.\n\n',animals{i},sessiondates{i}{j});
%         runRidge_fullAndShuffle(cPath,animals{1},sessiondates{1}{1},glmFile);
%     end
% end

%% Retrain models over different states 
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fprintf('\nRunning for %s, %s.\n\n',animals{i},sessiondates{i}{j});
        runRidge_overStates(cPath,animals{1},sessiondates{1}{1},glmFile);
    end
end
