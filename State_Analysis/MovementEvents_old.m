% Look at delay period whisking
clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions
%cPath = 'V:\StateProjectCentralRepo\Widefield_Sessions';

animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat'; cPath = 'X:\Widefield';

%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'allaudio_detection.mat'; cPath = 'Y:\Widefield'%32 not working for some reason
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; cPath = 'Y:\Widefield' %CSP32 missing transparams
%animals = {'CSP22','CSP38'}; glmFile = 'alldisc.mat'; cPath = 'Y:\Widefield' %CSP32 missing transparams

method = 'cutoff';
mintrialnum = 20; %the minimum number of trials per state to be included in plotting
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data
%%

for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        path = [cPath filesep animals{i} filesep 'SpatialDisc' filesep sessiondates{i}{j}];
        [inds,a,b,~] = getStateInds(cPath,animals{i},sessiondates{i}{j},'cutoff',glmFile,dualcase);
        if length(a) > mintrialnum
            fprintf('\nRunning %s, %s\n',animals{i},sessiondates{i}{j});
            load([path filesep 'BehaviorVideo' filesep 'FilteredPupil.mat'], 'pTime', 'fPupil', 'sPupil', 'whisker', 'faceM', 'bodyM', 'nose', 'bTime'); %load pupil data
            bhvFile = dir([path filesep '*_SpatialDisc*.mat']);
            load(fullfile(bhvFile.folder, bhvFile.name), 'SessionData');
        else
            continue
        end
        assert(length(sPupil) == length(SessionData.CorrectSide),'Lengths are not equal!');
        inds = {};
        for k = 1:length(sPupil) %iterate thru trials
            pTime{k} = pTime{k} - pTime{k}(1);

            delayStart(k) = SessionData.RawEvents.Trial{k}.States.DecisionWait(1);
            delayEnd(k) = SessionData.RawEvents.Trial{k}.States.MoveSpout(1);
            handle(k) = min(SessionData.RawEvents.Trial{k}.States.Reset(:)); 
            inds{k} = find(pTime{k} > delayStart(k) & pTime{k} < delayEnd(k));
        end
    end
end
