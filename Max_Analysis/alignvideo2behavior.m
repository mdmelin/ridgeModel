function [alignVideo,bhv,goodtrials] = alignvideo2behavior(cPath,Animal,Rec,trialInds,camnum)
%like align2behavior, but meant for video data rather than widefield data
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallstuff');
Paradigm = 'SpatialDisc';
cPathSave = cPath;
cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
dims = 200; %number of dims of widefield SVD
%% Load data
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
SessionData.TrialStartTime = SessionData.TrialStartTime * 86400; %convert trailstart timestamps to seconds
nochoice = isnan(SessionData.ResponseSide); %trials without choice. used for interpolation of latent state on NaN choice trials (GLMHMM doesn't predict for these trials)
try
    load([cPath 'opts3.mat']);
    opts = opts3;clear opts3;
catch
    try
        load([cPath 'opts2.mat']);
    catch
        load([cPath 'opts.mat']);
    end
end

nRequested = length(trialInds);
nTotalTrials = SessionData.nTrials;
inds = 1:1:nTotalTrials;
%% get proper trials from SessionData
temp = trialInds(ismember(trialInds,inds)); %use only trial indices to grab that are in the Vc dataset. contains only bpod trial numbers that have imaging data.
bhv = selectBehaviorTrials(SessionData,temp); %this grabs trials that are in the requested indices AND the Vc dataset
nTrials = length(temp);
goodtrials = temp;

fprintf('Requested %i trials. Using %i trials (video data should not have any missing trials, unlike widefield data).\n',nRequested,nTrials);

%segIdx = [2 0.75 1.25 0.75 1]; %what simon sent me.
if sum(ismember(Animal,'mSM')) == 3 %mSM Mice
    segIdx = [1 0.5 1.00 0.75 .75]; %[baseline, handle, stim, delay, response] maximal duration of each segment in seconds, use this for EMX mice
elseif sum(ismember(Animal,'CSP')) == 3 %CSP Mice
    segIdx = [1 0.2 .5 0.15 .75]; %[baseline, handle, stim, delay, response] maximal duration of each segment in seconds, use this for CSP mice
end

[alignVideo.cam,alignVideo.segFrames] = realignBhvVideo2(cPathSave, Animal, Rec, goodtrials, camnum, segIdx, opts); %we pass segIdx here instead of segFrames (for Vc realignment) becasue we don't yet have sample rate
alignVideo.segIdx = segIdx;
end
