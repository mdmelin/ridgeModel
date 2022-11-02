function ridgeModel_vanillaAligned(cPath,Animal,Rec,dType,shufflelabels,ignoreflags)

%Mods by Max Melin. Trains the ridge regression model described in Musall 2019
%on that same datased. Added improved alignment. No state/glmhmm stuff. 
fprintf('\nTraining model for %s on %s.\n\n',Animal,Rec);
if ~strcmpi(cPath(end),filesep)
    cPath = [cPath filesep];
end
Paradigm = 'SpatialDisc';
cPath = [cPath Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
sPath = ['V:\GoogleDriveRclone' Animal filesep Paradigm filesep Rec filesep]; %server data path. not used on hpc.

%First, check if we need to run the model for this session, look for flag
%file
expectedflag = [mfilename '_hasrun.flag'];
fnames = {dir(cPath).name};
if ismember(expectedflag,fnames) && ~ignoreflags %if the flag file is found and we're not ignoring flag files
    fprintf('\nThere is already a model trained for this session. Skipping...\n\n');
    return %abort the model training
end

addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallStuff');


if ~exist('dType', 'var') || isempty(dType)
    dType = 'Widefield'; %default is widefield data
end

if strcmpi(dType,'twoP')
    piezoLine = 5;     % channel in the analog data that contains data from piezo sensor
    stimLine = 4;      % channel in the analog data that contains s
    timulus trigger.
    
elseif strcmpi(dType,'Widefield')
    piezoLine = 2;     % channel in the analog data that contains data from piezo sensor
    stimLine = 6;      % channel in the analog data that contains stimulus trigger.
end


%% general variables
load([cPath 'opts.mat'], 'opts');         % get some options from imaging data
sRate = opts.frameRate;           % Sampling rate of imaging in Hz
if sRate == 30
    vcFile = 'rsVc.mat'; %use downsampled data here and change sampling frequency
    sRate = 15;
else
    vcFile = 'Vc.mat';
end

preStimDur = floor(2 * sRate) / sRate; % Duration of trial before lever grab in seconds
postStimDur = floor(3 *sRate) / sRate; % Duration of trial after lever grab onset in seconds
frames = round((preStimDur + postStimDur) * sRate); %nr of frames per trial
trialDur = (frames * (1/sRate)); %duration of trial in seconds

%other variables
mPreTime = ceil(0.5 * sRate);  % precede motor events to capture preparatory activity in frames
mPostTime = ceil(5 * sRate);   % follow motor events for mPostStim in frames
fsPostTime = ceil(5 * sRate);   % follow first stim event for fsPostStim in frames
sPostTime = ceil(2 * sRate);   % follow stim events for sPostStim in frames
motorIdx = [-(mPreTime: -1 : 1) 0 (1:mPostTime)]; %index for design matrix to cover pre- and post motor action
tapDur = 0.1;      % minimum time of lever contact, required to count as a proper grab.
leverMoveDur = 0.3; %duration of lever movement. this is used to orthogonalize video against lever movement.
leverMoveDur = ceil(leverMoveDur * sRate); %convert to frames
ridgeFolds = 10; %number of cross-validations for motor/task models
opMotorLabels = {'lLick' 'rLick' 'lGrab' 'lGrabRel' 'rGrab' 'rGrabRel'}; %operant motor regressors
shVal = sRate * opts.preStim  + 1; %expected position of stimulus onset in the imaging data (s).
maxStimShift = 1 * sRate; % maximal stimulus onset after handle grab. (default is 1s - this means that stimulus onset should not be more than 1s after handle grab. Cognitive regressors will have up to 1s of baseline because of stim jitter.)
bhvDimCnt = 200;    % number of dimensions from behavioral videos that are used as regressors.
gaussShift = 1;     % inter-frame interval between regressors. Will use only every 'gaussShift' regressor and convolve with gaussian of according FHWM to reduce total number of used regressors.
%[~, motorLabels] = rateDiscRecordings; %get motor labels for motor-only model
dims = 200; %number of dims in Vc that are used in the model




%% load data
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
SessionData.TrialStartTime = SessionData.TrialStartTime * 86400; %convert trailstart timestamps to seconds
nochoice = isnan(SessionData.ResponseSide); %trials without choice. used for interpolation of latent state on NaN choice trials (GLMHMM doesn't predict for these trials)

if strcmpi(dType,'Widefield')
    if exist([cPath vcFile],'file') ~= 2 %check if data file exists and get from server otherwise
        copyfile([sPath vcFile],[cPath vcFile]);
        copyfile([sPath 'mask.mat'],[cPath 'mask.mat']);
        bhvFile = dir([sPath filesep Animal '_' Paradigm '*.mat']);
        copyfile([sPath bhvFile.name],[cPath bhvFile.name]);
    end
    load([cPath vcFile], 'Vc', 'U', 'trials', 'bTrials')
    Vc = Vc(1:dims,:,:);
    U = U(:,:,1:dims);
    
    % ensure there are not too many trials in Vc
    ind = trials > SessionData.nTrials;
    trials(ind) = [];
    bTrials(ind) = [];
    Vc(:,:,ind) = [];
    
elseif strcmpi(dType,'twoP')
    
    load([cPath 'data'], 'data'); %load 2p data
    % ensure there are not too many trials in the dataset
    bTrials = data.trialNumbers;
    trials = bTrials;
    bTrials(~ismember(data.trialNumbers,data.bhvTrials)) = []; %don't use trials that have problems with trial onset times
    bTrials(SessionData.DidNotChoose(bTrials) | SessionData.DidNotLever(bTrials) | ~SessionData.Assisted(bTrials)) = []; %don't use unperformed/assisted trials
    
    data.dFOF(:,:,~ismember(data.trialNumbers,bTrials)) = [];
    data.DS(:,:,~ismember(data.trialNumbers,bTrials)) = [];
    data.analog(:,:,~ismember(data.trialNumbers,bTrials)) = [];
    
    Vc = data.dFOF; %Vc is now neurons x frames x trials
    dims = size(data.dFOF,1); %dims is now # of neurons instead
end
bhv = selectBehaviorTrials(SessionData,bTrials); %only use completed trials that are in the Vc dataset

%equalize L/R choices
useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
choiceIdx = rateDisc_equalizeTrials(useIdx, bhv.ResponseSide == 1, bhv.Rewarded, inf, true); %equalize correct L/R choices
trials = trials(choiceIdx);
bTrials = bTrials(choiceIdx);
Vc = Vc(:,:,choiceIdx);
bhv = selectBehaviorTrials(SessionData,bTrials); %only use completed trials that are in the Vc dataset
trialCnt = length(bTrials);
%% load behavior data
if exist([cPath 'BehaviorVideo' filesep 'SVD_CombinedSegments.mat'],'file') ~= 2 || ... %check if svd behavior exists on hdd and pull from server otherwise
        exist([cPath 'BehaviorVideo' filesep 'motionSVD_CombinedSegments.mat'],'file') ~= 2
    
    if ~exist([cPath 'BehaviorVideo' filesep], 'dir')
        mkdir([cPath 'BehaviorVideo' filesep]);
    end
    copyfile([sPath 'BehaviorVideo' filesep 'SVD_CombinedSegments.mat'],[cPath 'BehaviorVideo' filesep 'SVD_CombinedSegments']);
    copyfile([sPath 'BehaviorVideo' filesep 'motionSVD_CombinedSegments.mat'],[cPath 'BehaviorVideo' filesep 'motionSVD_CombinedSegments.mat']);
    copyfile([sPath 'BehaviorVideo' filesep 'FilteredPupil.mat'],[cPath 'BehaviorVideo' filesep 'FilteredPupil.mat']);
    copyfile([sPath 'BehaviorVideo' filesep 'segInd1.mat'],[cPath 'BehaviorVideo' filesep 'segInd1.mat']);
    copyfile([sPath 'BehaviorVideo' filesep 'segInd2.mat'],[cPath 'BehaviorVideo' filesep 'segInd2.mat']);
    
    movFiles = dir([sPath 'BehaviorVideo' filesep '*Video_*1.mj2']);
    copyfile([sPath 'BehaviorVideo' filesep movFiles(1).name],[cPath 'BehaviorVideo' filesep movFiles(1).name]);
    movFiles = dir([sPath 'BehaviorVideo' filesep '*Video_*2.mj2']);
    copyfile([sPath 'BehaviorVideo' filesep movFiles(1).name],[cPath 'BehaviorVideo' filesep movFiles(1).name]);
    
    svdFiles = dir([sPath 'BehaviorVideo' filesep '*SVD*-Seg*']);
    for iFiles = 1:length(svdFiles)
        copyfile([sPath 'BehaviorVideo' filesep svdFiles(iFiles).name],[cPath 'BehaviorVideo' filesep svdFiles(iFiles).name]);
    end
end

load([cPath 'BehaviorVideo' filesep 'SVD_CombinedSegments.mat'],'vidV'); %load behavior video data
V1 = vidV(:,1:bhvDimCnt); %behavioral video regressors
load([cPath 'BehaviorVideo' filesep 'motionSVD_CombinedSegments.mat'],'vidV'); %load abs motion video data
V2 = vidV(:,1:bhvDimCnt); % motion regressors

% check options that were used for dimensionality reduction and ensure that imaging and video data trials are equal length
load([cPath 'BehaviorVideo' filesep 'bhvOpts.mat'], 'bhvOpts'); %load abs motion video data
bhvRate = bhvOpts.targRate; %framerate of face camera
if (bhvOpts.preStimDur + bhvOpts.postStimDur) > (opts.preStim + opts.postStim) %if behavioral video trials are longer than imaging data
    V1 = reshape(V1, [], SessionData.nTrials, bhvDimCnt);
    V2 = reshape(V2, [], SessionData.nTrials, bhvDimCnt);
    if bhvOpts.preStimDur > opts.preStim
        frameDiff = ceil((bhvOpts.preStimDur - opts.preStim) * bhvRate); %overhead in behavioral frames that can be removed.
        V1 = V1(frameDiff+1:end, :, :); %cut data to size
        V2 = V2(frameDiff+1:end, :, :);
    end
    if bhvOpts.postStimDur > opts.postStim
        frameDiff = ceil((bhvOpts.postStimDur - opts.postStim) * bhvRate); %overhead in behavioral frames that can be removed.
        V1 = V1(1 : end - frameDiff, :, :); %cut data to size
        V2 = V2(1 : end - frameDiff, :, :);
    end
    V1 = reshape(V1, [], bhvDimCnt);
    V2 = reshape(V2, [], bhvDimCnt);
end

load([cPath 'BehaviorVideo' filesep 'FilteredPupil.mat'], 'pTime', 'fPupil', 'sPupil', 'whisker', 'faceM', 'bodyM', 'nose', 'bTime'); %load pupil data
%check if timestamps from pupil data are shifted against bhv data
timeCheck1 = (SessionData.TrialStartTime(1)) - (pTime{1}(1)); %time difference between first acquired frame and onset of first trial
timeCheck2 = (SessionData.TrialStartTime(1)) - (bTime{1}(1)); %time difference between first acquired frame and onset of first trial
if (timeCheck1 > 3590 && timeCheck1 < 3610) && (timeCheck2 > 3590 && timeCheck2 < 3610) %timeshift by one hour (+- 10seconds)
    warning('Behavioral and video timestamps are shifted by 1h. Will adjust timestamps in video data accordingly.')
    for iTrials = 1 : length(pTime)
        pTime{iTrials} = pTime{iTrials} + 3600; %add one hour
        bTime{iTrials} = bTime{iTrials} + 3600; %add one hour
    end
elseif timeCheck1 > 30 || timeCheck1 < -30 || timeCheck2 > 30 || timeCheck2 < -30
    error('Something wrong with timestamps in behavior and video data. Time difference is larger as 30 seconds.')
end

if any(bTrials > length(pTime))
    warning(['There are insufficient trials in the pupil data. Rejected the last ' num2str(sum(bTrials > length(pTime))) ' trial(s)']);
    bTrials(bTrials > length(pTime)) = [];
    trialCnt = length(bTrials);
end


%% find events in BPod time - All timestamps are relative to stimulus onset event to synchronize to imaging data later
% pre-allocate vectors
lickL = cell(1,trialCnt);
lickR = cell(1,trialCnt);
leverIn = NaN(1,trialCnt);
levGrabL = cell(1,trialCnt);
levGrabR = cell(1,trialCnt);
levReleaseL = cell(1,trialCnt);
levReleaseR = cell(1,trialCnt);
water = NaN(1,trialCnt);
handleSounds = cell(1,trialCnt);

tacStimL = cell(1,trialCnt);
tacStimR = cell(1,trialCnt);
audStimL = cell(1,trialCnt);
audStimR = cell(1,trialCnt);

for iTrials = 1:trialCnt
    
    leverTimes = [reshape(bhv.RawEvents.Trial{iTrials}.States.WaitForAnimal1',1,[]) ...
        reshape(bhv.RawEvents.Trial{iTrials}.States.WaitForAnimal2',1,[]) ...
        reshape(bhv.RawEvents.Trial{iTrials}.States.WaitForAnimal3',1,[])];
    
    try
        stimGrab(iTrials) = leverTimes(find(leverTimes == bhv.RawEvents.Trial{iTrials}.States.WaitForCam(1))-1); %find start of lever state that triggered stimulus onset
        handleSounds{iTrials} = leverTimes(1:2:end) - stimGrab(iTrials); %track indicator sound when animal is grabing both handles
        stimTime(iTrials) = bhv.RawEvents.Trial{iTrials}.Events.Wire3High - stimGrab(iTrials); %time of stimulus onset - measured from soundcard
        stimEndTime(iTrials) = bhv.RawEvents.Trial{iTrials}.States.DecisionWait(1) - stimGrab(iTrials); %end of stimulus period, relative to handle grab, from simons email
    catch
        stimTime(iTrials) = NaN;
        stimGrab(iTrials) = 0;
    end
    
    %check for spout motion
    if isfield(bhv.RawEvents.Trial{iTrials}.States,'MoveSpout')
        spoutTime(iTrials) = bhv.RawEvents.Trial{iTrials}.States.MoveSpout(1) - stimGrab(iTrials);
        
        %also get time when the other spout was moved out at
        if bhv.Rewarded(iTrials)
            spoutOutTime(iTrials) = bhv.RawEvents.Trial{iTrials}.States.Reward(1) - stimGrab(iTrials);
        else
            spoutOutTime(iTrials) = bhv.RawEvents.Trial{iTrials}.States.HardPunish(1) - stimGrab(iTrials);
        end
    else
        spoutTime(iTrials) = NaN;
        spoutOutTime(iTrials) = NaN;
    end
    
    if isfield(bhv.RawEvents.Trial{iTrials}.Events,'Port1In') %check for licks
        lickL{iTrials} = bhv.RawEvents.Trial{iTrials}.Events.Port1In;
        lickL{iTrials}(lickL{iTrials} < bhv.RawEvents.Trial{iTrials}.States.MoveSpout(1)) = []; %dont use false licks that occured before spouts were moved in
        lickL{iTrials} = lickL{iTrials} - stimGrab(iTrials);
    end
    if isfield(bhv.RawEvents.Trial{iTrials}.Events,'Port3In') %check for right licks
        lickR{iTrials} = bhv.RawEvents.Trial{iTrials}.Events.Port3In;
        lickR{iTrials}(lickR{iTrials} < bhv.RawEvents.Trial{iTrials}.States.MoveSpout(1)) = []; %dont use false licks that occured before spouts were moved in
        lickR{iTrials} = lickR{iTrials} - stimGrab(iTrials);
    end
    
    % get stimulus events times
    audStimL{iTrials} = bhv.stimEvents{iTrials}{1} + stimTime(iTrials);
    audStimR{iTrials} = bhv.stimEvents{iTrials}{2} + stimTime(iTrials);
    tacStimL{iTrials} = bhv.stimEvents{iTrials}{5} + stimTime(iTrials);
    tacStimR{iTrials} = bhv.stimEvents{iTrials}{6} + stimTime(iTrials);
    
    leverIn(iTrials) = min(bhv.RawEvents.Trial{iTrials}.States.Reset(:)) - stimGrab(iTrials); %first reset state causes lever to move in
    
    if isfield(bhv.RawEvents.Trial{iTrials}.Events,'Wire2High') %check for left grabs
        levGrabL{iTrials} = bhv.RawEvents.Trial{iTrials}.Events.Wire2High - stimGrab(iTrials);
    end
    if isfield(bhv.RawEvents.Trial{iTrials}.Events,'Wire1High') %check for right grabs
        levGrabR{iTrials} = bhv.RawEvents.Trial{iTrials}.Events.Wire1High - stimGrab(iTrials);
    end
    
    if isfield(bhv.RawEvents.Trial{iTrials}.Events,'Wire2Low') %check for left release
        levReleaseL{iTrials} = bhv.RawEvents.Trial{iTrials}.Events.Wire2Low - stimGrab(iTrials);
    end
    if isfield(bhv.RawEvents.Trial{iTrials}.Events,'Wire1Low') %check for right release
        levReleaseR{iTrials} = bhv.RawEvents.Trial{iTrials}.Events.Wire1Low - stimGrab(iTrials);
    end
    
    if ~isnan(bhv.RawEvents.Trial{iTrials}.States.Reward(1)) %check for reward state
        water(iTrials) = bhv.RawEvents.Trial{iTrials}.States.Reward(1) - stimGrab(iTrials);
    end
end
maxSpoutRegs = length(min(round((preStimDur + spoutTime) * sRate)) : frames); %maximal number of required spout regressors

%% build regressors - create design matrix based on event times
%basic time regressors
timeR = logical(diag(ones(1,frames)));

lGrabR = cell(1,trialCnt);
lGrabRelR = cell(1,trialCnt);
rGrabR = cell(1,trialCnt);
rGrabRelR = cell(1,trialCnt);
lLickR = cell(1,trialCnt);
rLickR = cell(1,trialCnt);
leverInR = cell(1,trialCnt);

lfirstTacStimR = cell(1,trialCnt);
rfirstTacStimR = cell(1,trialCnt);
lfirstAudStimR = cell(1,trialCnt);
rfirstAudStimR = cell(1,trialCnt);

lTacStimR = cell(1,trialCnt);
rTacStimR = cell(1,trialCnt);
lAudStimR = cell(1,trialCnt);
rAudStimR = cell(1,trialCnt);

spoutR = cell(1,trialCnt);
spoutOutR = cell(1,trialCnt);


handleChoiceR = cell(1,trialCnt); %aligned choice regressors
stimChoiceR = cell(1,trialCnt);
delayChoiceR = cell(1,trialCnt);
responseChoiceR = cell(1,trialCnt);

handleRewardR = cell(1,trialCnt); %aligned reward regressors
stimRewardR = cell(1,trialCnt);
delayRewardR = cell(1,trialCnt);
responseRewardR = cell(1,trialCnt);

prevRewardR = cell(1,trialCnt);
prevChoiceR = cell(1,trialCnt);
prevStimR = cell(1,trialCnt);
nextChoiceR = cell(1,trialCnt);
repeatChoiceR = cell(1,trialCnt);

waterR = cell(1,trialCnt);
fastPupilR = cell(1,trialCnt);
slowPupilR = cell(1,trialCnt);

whiskR = cell(1,trialCnt);
noseR = cell(1,trialCnt);
piezoR = cell(1,trialCnt);
piezoMoveR = cell(1,trialCnt);
faceR = cell(1,trialCnt);
bodyR = cell(1,trialCnt);

handleSoundR = cell(1,trialCnt);

%%
tic
for iTrials = 1:trialCnt
    %% first tactile/auditory stimuli
    lfirstAudStimR{iTrials} = false(frames, fsPostTime);
    rfirstAudStimR{iTrials} = false(frames, fsPostTime);
    lfirstTacStimR{iTrials} = false(frames, fsPostTime);
    rfirstTacStimR{iTrials} = false(frames, fsPostTime);
    
    firstStim = NaN;
    if bhv.StimType(iTrials) == 2 || bhv.StimType(iTrials) == 6 %auditory or mixed stimulus
        if ~isempty(audStimL{iTrials}(~isnan(audStimL{iTrials})))
            firstStim = round((audStimL{iTrials}(1) + preStimDur) * sRate);
            stimEnd = firstStim - 1 + fsPostTime; stimEnd = min([frames stimEnd]);
            lfirstAudStimR{iTrials}(:,1 : stimEnd - firstStim + 1)  = timeR(:, firstStim : stimEnd);
        end
        if ~isempty(audStimR{iTrials}(~isnan(audStimR{iTrials})))
            firstStim = round((audStimR{iTrials}(1) + preStimDur) * sRate);
            stimEnd = firstStim - 1 + fsPostTime; stimEnd = min([frames stimEnd]);
            rfirstAudStimR{iTrials}(:,1 : stimEnd - firstStim + 1) = timeR(:, firstStim : stimEnd);
        end
    end
    
    if bhv.StimType(iTrials) == 4 || bhv.StimType(iTrials) == 6 %tactile or mixed stimulus
        if ~isempty(tacStimL{iTrials}(~isnan(tacStimL{iTrials})))
            firstStim = round((tacStimL{iTrials}(1) + preStimDur) * sRate);
            stimEnd = firstStim - 1 + fsPostTime; stimEnd = min([frames stimEnd]);
            lfirstTacStimR{iTrials}(:,1 : stimEnd - firstStim + 1) = timeR(:, firstStim : stimEnd);
        end
        if ~isempty(tacStimR{iTrials}(~isnan(tacStimR{iTrials})))
            firstStim = round((tacStimR{iTrials}(1) + preStimDur) * sRate);
            stimEnd = firstStim - 1 + fsPostTime; stimEnd = min([frames stimEnd]);
            rfirstTacStimR{iTrials}(:,1 : stimEnd - firstStim + 1) = timeR(:, firstStim : stimEnd);
        end
    end
    
    if gaussShift > 1
        % subsample regressors
        lfirstTacStimR{iTrials} = lfirstTacStimR{iTrials}(:,1:gaussShift:end);
        rfirstTacStimR{iTrials} = rfirstTacStimR{iTrials}(:,1:gaussShift:end);
        lfirstAudStimR{iTrials} = lfirstAudStimR{iTrials}(:,1:gaussShift:end);
        rfirstAudStimR{iTrials} = rfirstAudStimR{iTrials}(:,1:gaussShift:end);
    end
    
    %% other tactile/auditory stimuli
    lAudStimR{iTrials} = false(frames, sPostTime);
    rAudStimR{iTrials} = false(frames, sPostTime);
    lTacStimR{iTrials} = false(frames, sPostTime);
    rTacStimR{iTrials} = false(frames, sPostTime);
    
    for iRegs = 0 : sPostTime - 1
        allStims = audStimL{iTrials}(2:end) + (iRegs * 1/sRate);
        lAudStimR{iTrials}(logical(histcounts(allStims,-preStimDur:1/sRate:postStimDur)),iRegs+1) = 1;
        
        allStims = audStimR{iTrials}(2:end) + (iRegs * 1/sRate);
        rAudStimR{iTrials}(logical(histcounts(allStims,-preStimDur:1/sRate:postStimDur)),iRegs+1) = 1;
        
        allStims = tacStimL{iTrials}(2:end) + (iRegs * 1/sRate);
        lTacStimR{iTrials}(logical(histcounts(allStims,-preStimDur:1/sRate:postStimDur)),iRegs+1) = 1;
        
        allStims = tacStimR{iTrials}(2:end) + (iRegs * 1/sRate);
        rTacStimR{iTrials}(logical(histcounts(allStims,-preStimDur:1/sRate:postStimDur)),iRegs+1) = 1;
    end
    
    if gaussShift > 1
        % subsample regressors
        lTacStimR{iTrials} = lTacStimR{iTrials}(:,1:gaussShift:end);
        rTacStimR{iTrials} = rTacStimR{iTrials}(:,1:gaussShift:end);
        lAudStimR{iTrials} = lAudStimR{iTrials}(:,1:gaussShift:end);
        rAudStimR{iTrials} = rAudStimR{iTrials}(:,1:gaussShift:end);
    end
    
    %% spout regressors
    spoutIdx = round((preStimDur + spoutTime(iTrials)) * sRate) : round((preStimDur + postStimDur) * sRate); %index for which part of the trial should be covered by spout regressors
    spoutR{iTrials} = false(frames, maxSpoutRegs);
    if ~isnan(spoutTime(iTrials))
        spoutR{iTrials}(:, 1:length(spoutIdx)) = timeR(:, spoutIdx);
    end
    
    spoutOutR{iTrials} = false(frames, 3);
    spoutOut = round((preStimDur + spoutOutTime(iTrials)) * sRate); %time when opposing spout moved out again
    if ~isnan(spoutOut) && spoutOut < (frames + 1)
        cInd = spoutOut : spoutOut + 2; cInd(cInd > frames) = [];
        temp = diag(ones(1,3));
        spoutOutR{iTrials}(cInd, :) = temp(1:length(cInd),:);
    end
    
    if gaussShift > 1
        % subsample regressors
        spoutR{iTrials} = spoutR{iTrials}(:,1:gaussShift:end);
        spoutOutR{iTrials} = spoutOutR{iTrials}(:,1:gaussShift:end);
    end
    
    %% lick regressors
    lLickR{iTrials} = false(frames, length(motorIdx));
    rLickR{iTrials} = false(frames, length(motorIdx));
    
    for iRegs = 0 : length(motorIdx)-1
        licks = lickL{iTrials} - ((mPreTime/sRate) - (iRegs * 1/sRate));
        lLickR{iTrials}(logical(histcounts(licks,-preStimDur:1/sRate:postStimDur)),iRegs+1) = 1;
        
        licks = lickR{iTrials} - ((mPreTime/sRate) - (iRegs * 1/sRate));
        rLickR{iTrials}(logical(histcounts(licks,-preStimDur:1/sRate:postStimDur)),iRegs+1) = 1;
    end
    
    if gaussShift > 1
        % subsample regressors
        lLickR{iTrials} = lLickR{iTrials}(:,1:gaussShift:end);
        rLickR{iTrials} = rLickR{iTrials}(:,1:gaussShift:end);
    end
    
    %% lever in
    leverInR{iTrials} = false(frames, leverMoveDur);
    leverShift = round((preStimDur + leverIn(iTrials))* sRate); %timepoint in frames when lever moved in, relative to lever grab
    
    if ~isnan(leverShift)
        if leverShift > 0 %lever moved in during the recorded trial
            leverInR{iTrials}(leverShift : leverShift + leverMoveDur -1, :) = diag(ones(1, leverMoveDur));
        elseif (leverShift + leverMoveDur) > 0  %lever was moving before data was recorded but still moving at trial onset
            leverInR{iTrials}(1 : leverMoveDur + leverShift, :) = [zeros(leverMoveDur + leverShift, abs(leverShift)) diag(ones(1, leverMoveDur + leverShift))];
        end
    end
    
    if gaussShift > 1
        % subsample regressors
        leverInR{iTrials} = leverInR{iTrials}(:,1:gaussShift:end);
    end
    
    %% dual-handle indicator sound
    handleSoundR{iTrials} = false(frames, sPostTime);
    for iRegs = 0 : sPostTime - 1
        allStims = handleSounds{iTrials}(1:end) + (iRegs * 1/sRate);
        allStims = allStims(~isnan(allStims)) + 0.001;
        handleSoundR{iTrials}(logical(histcounts(allStims,-preStimDur:1/sRate:postStimDur)),iRegs+1) = 1;
    end
    
    %% choice, reward and state
    %make the stimtemp matrix
    stimTemp = false(frames, frames + maxStimShift);
    stimShift = round(stimTime(iTrials) * sRate); %amount of stimshift compared to possible maximum. move diagonal on x-axis accordingly.
    if (stimShift > maxStimShift) || isnan(stimTime(iTrials))
        stimTemp = NaN(frames, frames + maxStimShift); %don't use trial if stim onset is too late
    else
        stimTemp(:, end - stimShift - frames + 1 : end - stimShift) = timeR;
    end
    
    % get choice as binary design matrix during handle grab
    handleReg = preStimDur*sRate; %regressor that is aligned with handle grab
    handleChoiceR{iTrials} = false(size(stimTemp,1),sRate);
    if stimShift > size(handleChoiceR{iTrials},2); stimShift = size(handleChoiceR{iTrials},2); end %make sure stimshift is not beyond size of design matrix
    try
        if bhv.ResponseSide(iTrials) == 1
            handleChoiceR{iTrials}(:,1:stimShift) = timeR(:,handleReg:handleReg+stimShift-1);
        end
    end
    
    % get choice as binary design matrix during stimulus period. 2s max duration.
    stimReg = round((preStimDur + stimTime(iTrials)) * sRate); %frame that is aligned with stimulus onset
    delayReg = floor((preStimDur + stimEndTime(iTrials)) * sRate); %onset of delay period. round down to ensure there is at least one frame for the delay.
    responseReg = ceil((preStimDur + spoutTime(iTrials)) * sRate);
    
    stimChoiceR{iTrials} = false(size(timeR,1),(2*sRate)+1);
    try
        temp = timeR(:,stimReg:responseReg-1);
        if size(temp,2) > (2*sRate)+1; temp = temp(:,1:(2*sRate)+1); end %make sure stimduration is not longer than 2s by accident.
        if bhv.ResponseSide(iTrials) == 1
            stimChoiceR{iTrials}(:,1:responseReg-stimReg) = temp;
        end
    end
    
    % get choice as binary design matrix during delay period. 2s max duration
    responseReg = ceil((preStimDur + spoutTime(iTrials)) * sRate);
    delayChoiceR{iTrials} = false(size(stimTemp,1),(2*sRate)+1);
    try
        if bhv.ResponseSide(iTrials) == 1
            delayChoiceR{iTrials}(:,1:responseReg-delayReg) = timeR(:,delayReg:responseReg-1);
        end
    end
    
    % get choice as binary design matrix during response period. 2s max duration
    responseChoiceR{iTrials} = false(size(stimTemp,1),(2*sRate)+1);
    try
        if bhv.ResponseSide(iTrials) == 1
            responseChoiceR{iTrials}(:,1:frames-responseReg+1) = timeR(:,responseReg:end);
        end
    end
    
    % get reward as binary design matrix during handle grab
    handleReg = preStimDur*sRate; %regressor that is aligned with handle grab
    handleRewardR{iTrials} = false(size(stimTemp,1),sRate);
    if stimShift > size(handleRewardR{iTrials},2); stimShift = size(handleRewardR{iTrials},2); end %make sure stimshift is not beyond size of design matrix
    try
        if bhv.Rewarded(iTrials)
            handleRewardR{iTrials}(:,1:stimShift) = timeR(:,handleReg:handleReg+stimShift-1);
        end
    end
    
    % get reward as binary design matrix during stimulus period. 2s max duration.
    stimReg = round((preStimDur + stimTime(iTrials)) * sRate); %frame that is aligned with stimulus onset
    delayReg = floor((preStimDur + stimEndTime(iTrials)) * sRate); %onset of delay period. round down to ensure there is at least one frame for the delay.
    responseReg = ceil((preStimDur + spoutTime(iTrials)) * sRate);
    
    stimRewardR{iTrials} = false(size(timeR,1),(2*sRate)+1);
    try
        temp = timeR(:,stimReg:responseReg-1);
        if size(temp,2) > (2*sRate)+1; temp = temp(:,1:(2*sRate)+1); end %make sure stimduration is not longer than 2s by accident.
        if bhv.Rewarded(iTrials)
            stimRewardR{iTrials}(:,1:responseReg-stimReg) = temp;
        end
    end
    
    % get reward as binary design matrix during delay period. 2s max duration
    responseReg = ceil((preStimDur + spoutTime(iTrials)) * sRate);
    delayRewardR{iTrials} = false(size(stimTemp,1),(2*sRate)+1);
    try
        if bhv.Rewarded(iTrials)
            delayRewardR{iTrials}(:,1:responseReg-delayReg) = timeR(:,delayReg:responseReg-1);
        end
    end
    
    % get reward as binary design matrix during response period. 2s max duration
    responseRewardR{iTrials} = false(size(stimTemp,1),(2*sRate)+1);
    try
        if bhv.Rewarded(iTrials)
            responseRewardR{iTrials}(:,1:frames-responseReg+1) = timeR(:,responseReg:end);
        end
    end
    
    
    
    
    
    % previous trial regressors
    if iTrials == 1 %don't use first trial
        prevRewardR{iTrials} = NaN(size(timeR(:,1:end-4)));
        prevChoiceR{iTrials} = NaN(size(timeR(:,1:end-4)));
        prevStimR{iTrials} = NaN(size(timeR(:,1:end-4)));
        
    else %for all subsequent trials
        % same as for regular choice regressors but for prevoious trial
        prevChoiceR{iTrials} = false(size(timeR(:,1:end-4)));
        if SessionData.ResponseSide(bTrials(iTrials)-1) == 1
            prevChoiceR{iTrials} = timeR(:,1:end-4);
        end
        
        prevStimR{iTrials} = false(size(timeR(:,1:end-4)));
        if SessionData.CorrectSide(bTrials(iTrials)-1) == 1 % if previous trial had a left target
            prevStimR{iTrials} = timeR(:,1:end-4);
        end
        
        prevRewardR{iTrials} = false(size(timeR(:,1:end-4)));
        if SessionData.Rewarded(bTrials(iTrials)-1) %last trial was rewarded
            prevRewardR{iTrials} = timeR(:,1:end-4);
        end
    end
    
    % subsequent trial regressors
    if iTrials == length(bTrials) %don't use lat trial
        nextChoiceR{iTrials} = NaN(size(timeR(:,1:end-4)));
        repeatChoiceR{iTrials} = NaN(size(timeR(:,1:end-4)));
        
    else %for all subsequent trials
        nextChoiceR{iTrials} = false(size(timeR(:,1:end-4)));
        if SessionData.ResponseSide(bTrials(iTrials)+1) == 1 %choice in next trial is left
            nextChoiceR{iTrials} = timeR(:,1:end-4);
        end
        
        repeatChoiceR{iTrials} = false(size(timeR(:,1:end-4)));
        if SessionData.ResponseSide(bTrials(iTrials)) == SessionData.ResponseSide(bTrials(iTrials)+1) %choice in next trial is similar to the current one
            repeatChoiceR{iTrials} = timeR(:,1:end-4);
        end
    end
    
    if gaussShift > 1
        % subsample regressors
        rewardR{iTrials} = rewardR{iTrials}(:,1:gaussShift:end);
        prevRewardR{iTrials} = prevRewardR{iTrials}(:,1:gaussShift:end);
        ChoiceR{iTrials} = ChoiceR{iTrials}(:,1:gaussShift:end);
        prevChoiceR{iTrials} = prevChoiceR{iTrials}(:,1:gaussShift:end);
        prevStimR{iTrials} = prevStimR{iTrials}(:,1:Shift:end);
        nextChoiceR{iTrials} = nextChoiceR{iTrials}(:,1:gaussShift:end);
        repeatChoiceR{iTrials} = repeatChoiceR{iTrials}(:,1:gaussShift:end);
    end
    
    %determine timepoint of reward given
    waterR{iTrials} = false(frames, sRate * 2);
    if ~isnan(water(iTrials)) && ~isempty(water(iTrials))
        waterOn = round((preStimDur + water(iTrials)) * sRate); %timepoint in frames when reward was given
        if waterOn <= frames
            waterR{iTrials}(:, 1 : size(timeR,2) - waterOn + 1) = timeR(:, waterOn:end);
        end
    end
    
    if gaussShift > 1
        waterR{iTrials} = waterR{iTrials}(:,1:gaussShift:end); % subsample regressor
    end
    
    %% lever grabs
    cGrabs = levGrabL{iTrials};
    cGrabs(cGrabs >= postStimDur) = []; %remove grabs after end of imaging
    cGrabs(find(diff(cGrabs) < tapDur) + 1) = []; %remove grabs that are too close to one another
    lGrabR{iTrials} = histcounts(cGrabs,-preStimDur:1/sRate:postStimDur)'; %convert to binary trace
    
    cGrabs = levGrabR{iTrials};
    cGrabs(cGrabs >= postStimDur) = []; %remove grabs after end of imaging
    cGrabs(find(diff(cGrabs) < tapDur) + 1) = []; %remove grabs that are too close to one another
    rGrabR{iTrials} = histcounts(cGrabs,-preStimDur:1/sRate:postStimDur)'; %convert to binary trace
    
    %% pupil / whisk / nose / face / body regressors
    bhvFrameRate = round(1/mean(diff(pTime{bTrials(iTrials)}))); %framerate of face camera
    trialOn = bhv.TrialStartTime(iTrials) + (stimGrab(iTrials) - preStimDur);
    trialTime = pTime{bTrials(iTrials)} - trialOn;
    rejIdx = trialTime < trialDur; %don't use late frames
    trialTime = trialTime(rejIdx);
    
    if isempty(trialTime) || trialTime(1) > 0 %check if there is missing time at the beginning of a trial
        warning(['Trial ' int2str(bTrials(iTrials)) ': Missing behavioral video frames at trial onset. Trial removed from analysis']);
        fastPupilR{iTrials} = NaN(frames, 1);
        slowPupilR{iTrials} = NaN(frames, 1);
        whiskR{iTrials} = NaN(frames, 1);
        noseR{iTrials} = NaN(frames, 1);
        faceR{iTrials} = NaN(frames, 1);
        bodyR{iTrials} = NaN(frames, 1);
        
    else
        timeLeft = trialDur - trialTime(end); %check if there is missing time at the end of a trial
        if (timeLeft < trialDur * 0.9) && (timeLeft > 0) %if there is some time missing to make a whole trial
            addTime = trialTime(end) + (1/bhvFrameRate : 1/bhvFrameRate : timeLeft + 1/bhvFrameRate); %add some dummy times to make complete trial
            trialTime = [trialTime' addTime];
        end
        
        fastPupilR{iTrials} = Behavior_vidResamp(fPupil{bTrials(iTrials)}(rejIdx), trialTime, sRate);
        fastPupilR{iTrials} = smooth(fastPupilR{iTrials}(end - frames + 1 : end), 'rlowess');
        
        slowPupilR{iTrials} = Behavior_vidResamp(sPupil{bTrials(iTrials)}(rejIdx), trialTime, sRate);
        slowPupilR{iTrials} =  smooth(slowPupilR{iTrials}(end - frames + 1 : end), 'rlowess');
        
        whiskR{iTrials} = Behavior_vidResamp(whisker{bTrials(iTrials)}(rejIdx), trialTime, sRate);
        whiskR{iTrials} = smooth(whiskR{iTrials}(end - frames + 1 : end), 'rlowess');
        
        noseR{iTrials} = Behavior_vidResamp(nose{bTrials(iTrials)}(rejIdx), trialTime, sRate);
        noseR{iTrials} = smooth(noseR{iTrials}(end - frames + 1 : end), 'rlowess');
        
        faceR{iTrials} = Behavior_vidResamp(faceM{bTrials(iTrials)}(rejIdx), trialTime, sRate);
        faceR{iTrials} = smooth(faceR{iTrials}(end - frames + 1 : end), 'rlowess');
        
        
        % body regressors
        bhvFrameRate = round(1/mean(diff(bTime{bTrials(iTrials)}))); %framerate of body camera
        trialTime = bTime{bTrials(iTrials)} - trialOn;
        rejIdx = trialTime < trialDur; %don't use late frames
        trialTime = trialTime(rejIdx);
        timeLeft = trialDur - trialTime(end); %check if there is missing time at the end of a trial
        
        if (timeLeft < trialDur * 0.9) && (timeLeft > 0) %if there is some time missing to make a whole trial
            addTime = trialTime(end) + (1/bhvFrameRate : 1/bhvFrameRate : timeLeft + 1/bhvFrameRate); %add some dummy times to make complete trial
            trialTime = [trialTime' addTime];
        end
        
        bodyR{iTrials} = Behavior_vidResamp(bodyM{bTrials(iTrials)}(rejIdx), trialTime, sRate);
        bodyR{iTrials} = smooth(bodyR{iTrials}(end - frames + 1 : end), 'rlowess');
    end
    
    %% piezo sensor information
    if strcmpi(dType,'Widefield')
        if exist([cPath 'Analog_'  num2str(trials(iTrials)) '.dat'],'file') ~= 2  %check if files exists on hdd and pull from server otherwise
            cFile = dir([sPath 'Analog_'  num2str(trials(iTrials)) '.dat']);
            copyfile([sPath 'Analog_'  num2str(trials(iTrials)) '.dat'],[cPath 'Analog_'  num2str(trials(iTrials)) '.dat']);
        end
        [~,Analog] = Widefield_LoadData([cPath 'Analog_'  num2str(trials(iTrials)) '.dat'],'Analog'); %load analog data
        stimOn = find(diff(double(Analog(stimLine,:)) > 1500) == 1); %find stimulus onset in current trial
    elseif strcmpi(dType,'twoP')
        Analog = squeeze(data.analog(:,:,iTrials));
        stimOn = find(diff(double(Analog(stimLine,:)) > 1) == 1); %find stimulus onset in current trial
    end
    
    if ~isnan(stimTime(iTrials))
        try
            Analog(1,round(stimOn + ((postStimDur-stimTime(iTrials)) * 1000) - 1)) = 0; %make sure there are enough datapoints in analog signal
            temp = Analog(piezoLine,round(stimOn - ((preStimDur + stimTime(iTrials)) * 1000)) : round(stimOn + ((postStimDur - stimTime(iTrials))* 1000) - 1)); % data from piezo sensor. Should encode animals hindlimb motion.
            temp = smooth(double(temp), sRate*5, 'lowess')'; %do some smoothing
            temp = [repmat(temp(1),1,1000) temp repmat(temp(end),1,1000)]; %add some padding on both sides to avoid edge effects when resampling
            temp = resample(double(temp), sRate, 1000); %resample to imaging rate
            piezoR{iTrials} = temp(sRate + 1 : end - sRate)'; %remove padds again
            piezoR{iTrials} = piezoR{iTrials}(end - frames + 1:end); %make sure, the length is correct
            
            temp = abs(hilbert(diff(piezoR{iTrials})));
            piezoMoveR{iTrials} = [temp(1); temp]; %keep differential motion signal
            clear temp
        catch
            piezoMoveR{iTrials} = NaN(frames, 1);
            piezoR{iTrials} = NaN(frames, 1);
        end
    else
        piezoMoveR{iTrials} = NaN(frames, 1);
        piezoR{iTrials} = NaN(frames, 1);
    end
    
    % give some feedback over progress
    if rem(iTrials,50) == 0
        fprintf(1, 'Current trial is %d out of %d\n', iTrials,trialCnt);
        toc
    end
end

%% get proper design matrices for handle grab
lGrabR = cat(1,lGrabR{:});
lGrabR = Widefield_analogToDesign(lGrabR, 0.5, trialCnt, sRate, sRate, motorIdx, gaussShift); %get design matrix

rGrabR = cat(1,rGrabR{:});
rGrabR = Widefield_analogToDesign(rGrabR, 0.5, trialCnt, sRate, sRate, motorIdx, gaussShift); %get design matrix

%% rebuild analog motor regressors to get proper design matrices
temp = double(cat(1,fastPupilR{:}));
temp = (temp - prctile(temp,1))./ nanstd(temp); %minimum values are at 0, signal in standard deviation units
[dMat, traceOut] = Widefield_analogToDesign(temp, median(temp), trialCnt, sRate, sRate, motorIdx, gaussShift);
temp = [single(traceOut) cat(1,dMat{:})]; %rebuild continuous format
[dMat, ~] = Widefield_analogToDesign(traceOut, prctile(traceOut,75), trialCnt, sRate, sRate, motorIdx, gaussShift);
fastPupilR = [temp cat(1,dMat{:})]; %add high amplitude movements separately

[dMat, traceOut] = Widefield_analogToDesign(double(cat(1,whiskR{:})), 0.5, trialCnt, sRate, sRate, motorIdx, gaussShift);
temp = [single(traceOut) cat(1,dMat{:})]; %rebuild continuous format
[dMat, ~] = Widefield_analogToDesign(double(cat(1,whiskR{:})), 2, trialCnt, sRate, sRate, motorIdx, gaussShift);
whiskR = [temp cat(1,dMat{:})]; %add high amplitude movements separately

[dMat, traceOut] = Widefield_analogToDesign(double(cat(1,noseR{:})), 0.5, trialCnt, sRate, sRate, motorIdx, gaussShift);
temp = [single(traceOut) cat(1,dMat{:})]; %rebuild continuous format
[dMat, ~] = Widefield_analogToDesign(double(cat(1,noseR{:})), 2, trialCnt, sRate, sRate, motorIdx, gaussShift);
noseR = [temp cat(1,dMat{:})]; %add high amplitude movements separately

[dMat, traceOut] = Widefield_analogToDesign(double(cat(1,piezoR{:})), 2, trialCnt, sRate, sRate, motorIdx, gaussShift);
piezoR1 = [traceOut cat(1,dMat{:})]; %rebuild continuous format
[dMat, traceOut] = Widefield_analogToDesign(double(cat(1,piezoMoveR{:})), 0.5, trialCnt, sRate, sRate, motorIdx, gaussShift);
temp = [traceOut cat(1,dMat{:})]; %rebuild continuous format
[dMat, ~] = Widefield_analogToDesign(double(cat(1,piezoMoveR{:})), 2, trialCnt, sRate, sRate, motorIdx, gaussShift);
piezoR = [piezoR1 temp cat(1,dMat{:})]; %add high amplitude movements separately

[dMat, traceOut] = Widefield_analogToDesign(double(cat(1,faceR{:})), 0.5, trialCnt, sRate, sRate, motorIdx, gaussShift);
temp = [single(traceOut) cat(1,dMat{:})]; %rebuild continuous format
[dMat, ~] = Widefield_analogToDesign(double(cat(1,faceR{:})), 2, trialCnt, sRate, sRate, motorIdx, gaussShift);
faceR = [temp cat(1,dMat{:})]; %add high amplitude movements separately

[dMat, traceOut] = Widefield_analogToDesign(double(cat(1,bodyR{:})), 0.5, trialCnt, sRate, sRate, motorIdx, gaussShift);
temp = [single(traceOut) cat(1,dMat{:})]; %rebuild continuous format
[dMat, ~] = Widefield_analogToDesign(double(cat(1,bodyR{:})), 2, trialCnt, sRate, sRate, motorIdx, gaussShift);
bodyR = [temp cat(1,dMat{:})]; %add high amplitude movements separately
clear piezoR1 piezoR2 dMat traceOut temp

%% re-align behavioral video data and Vc to lever grab instead of stimulus onset
if strcmpi(dType,'Widefield')
    iiSpikeFrames = findInterictalSpikes(U, Vc, 2, false); %find interictal spikes
    Vc = interpOverInterictal(Vc, iiSpikeFrames); %interpolate over interictal spikes
end

V1 = reshape(V1, [], SessionData.nTrials, bhvDimCnt);
V2 = reshape(V2, [], SessionData.nTrials, bhvDimCnt);

%if video sampling rate is different from widefield, resample video data
if bhvOpts.targRate ~= sRate
    vidR = NaN(size(Vc,2), length(bTrials), size(V1,3), 'single');
    moveR = NaN(size(Vc,2), length(bTrials), size(V1,3), 'single');
    for iTrials = 1 : length(bTrials)
        
        temp1 = squeeze(V1(:,bTrials(iTrials),:));
        if ~any(isnan(temp1(:)))
            trialTime = 1/bhvRate : 1/bhvRate : size(Vc,2)/sRate;
            vidR(:, iTrials, :) = Behavior_vidResamp(double(temp1), trialTime, sRate);
            
            temp2 = squeeze(V2(:,bTrials(iTrials),:));
            trialTime = 1/bhvRate : 1/bhvRate : size(Vc,2)/sRate;
            moveR(:, iTrials, :) = Behavior_vidResamp(double(temp2), trialTime, sRate);
        end
    end
else
    vidR = V1(:,bTrials,:); clear V1 %get correct trials from behavioral video data.
    moveR = V2(:,bTrials,:); clear V2 %get correct trials from behavioral video data.
end

% re-align video data
temp1 = NaN(dims,frames,trialCnt);
temp2 = NaN(frames,trialCnt,bhvDimCnt);
temp3 = NaN(frames,trialCnt,bhvDimCnt);
temp4 = NaN(2,frames,trialCnt);
for x = 1 : size(vidR,2) %iterate thru trials
    try
        temp1(:,:,x) = Vc(:,(shVal - ceil(stimTime(x) / (1/sRate))) - (preStimDur * sRate) : (shVal - ceil(stimTime(x) / (1/sRate))) + (postStimDur * sRate) - 1,x);
        temp2(:,x,:) = vidR((shVal - ceil(stimTime(x) / (1/sRate))) - (preStimDur * sRate) : (shVal - ceil(stimTime(x) / (1/sRate))) + (postStimDur * sRate) - 1,x,:);
        temp3(:,x,:) = moveR((shVal - ceil(stimTime(x) / (1/sRate))) - (preStimDur * sRate) : (shVal - ceil(stimTime(x) / (1/sRate))) + (postStimDur * sRate) - 1,x,:);
        if strcmpi(dType,'twoP')
            temp4(:,:,x) = data.DS(:,(shVal - ceil(stimTime(x) / (1/sRate))) - (preStimDur * sRate) : (shVal - ceil(stimTime(x) / (1/sRate))) + (postStimDur * sRate) - 1,x);
        end
    catch
        fprintf(1,'Could not align trial %d. Relative stim time: %fs\n', x, stimTime(x));
    end
end
Vc = reshape(temp1,dims,[]); clear temp1
vidR = reshape(temp2,[],bhvDimCnt); clear temp2
moveR = reshape(temp3,[],bhvDimCnt); clear temp3

if strcmpi(dType,'twoP')
    DS = reshape(temp4,2,[]); %keep image motion trace for 2p imaging
end
clear temp4


%% reshape regressors, make design matrix and indices for regressors that are used for the model
timeR = repmat(logical(diag(ones(1,frames))),trialCnt,1); %time regressor
timeR = timeR(:,1:end-4);

lGrabR = cat(1,lGrabR{:});
lGrabRelR = cat(1,lGrabRelR{:});
rGrabR = cat(1,rGrabR{:});
rGrabRelR = cat(1,rGrabRelR{:});

lLickR = cat(1,lLickR{:});
rLickR = cat(1,rLickR{:});
leverInR = cat(1,leverInR{:});
leverInR(:,sum(leverInR) == 0) = [];

handleSoundR = cat(1,handleSoundR{:});

lTacStimR = cat(1,lTacStimR{:});
rTacStimR = cat(1,rTacStimR{:});
lAudStimR = cat(1,lAudStimR{:});
rAudStimR = cat(1,rAudStimR{:});

lfirstTacStimR = cat(1,lfirstTacStimR{:});
rfirstTacStimR = cat(1,rfirstTacStimR{:});
lfirstAudStimR = cat(1,lfirstAudStimR{:});
rfirstAudStimR = cat(1,rfirstAudStimR{:});

spoutR = cat(1,spoutR{:});
spoutOutR = cat(1,spoutOutR{:});
spoutR(:,sum(spoutR) == 0) = [];
spoutOutR(:,sum(spoutOutR) == 0) = [];


handleChoiceR = cat(1,handleChoiceR{:});
stimChoiceR = cat(1,stimChoiceR{:});
delayChoiceR = cat(1,delayChoiceR{:});
responseChoiceR = cat(1,responseChoiceR{:});

handleRewardR = cat(1,handleRewardR{:});
stimRewardR = cat(1,stimRewardR{:});
delayRewardR = cat(1,delayRewardR{:});
responseRewardR = cat(1,responseRewardR{:});

prevRewardR = cat(1,prevRewardR{:});
prevChoiceR = cat(1,prevChoiceR{:});
prevStimR = cat(1,prevStimR{:});
nextChoiceR = cat(1,nextChoiceR{:});
repeatChoiceR = cat(1,repeatChoiceR{:});

waterR = cat(1,waterR{:});

slowPupilR = cat(1,slowPupilR{:});
slowPupilR(~isnan(slowPupilR(:,1)),:) = zscore(slowPupilR(~isnan(slowPupilR(:,1)),:));

%% create full design matrix
fullR = [timeR handleChoiceR stimChoiceR delayChoiceR responseChoiceR  ...
    handleRewardR stimRewardR delayRewardR responseRewardR lGrabR lGrabRelR rGrabR rGrabRelR ...
    lLickR rLickR handleSoundR lfirstTacStimR lTacStimR rfirstTacStimR rTacStimR ...
    lfirstAudStimR lAudStimR rfirstAudStimR rAudStimR prevRewardR prevChoiceR ...
    nextChoiceR waterR piezoR whiskR noseR fastPupilR ...
    slowPupilR faceR bodyR moveR vidR];

% labels for different regressor sets. It is REALLY important this agrees with the order of regressors in fullR.
regLabels = {
    'time' 'handleChoice' 'stimChoice' 'delayChoice' 'responseChoice' 'handleReward' 'stimReward' 'delayReward' 'responseReward' ...
    'lGrab' 'lGrabRel' 'rGrab' 'rGrabRel' 'lLick' 'rLick' 'handleSound' ...
    'lfirstTacStim' 'lTacStim' 'rfirstTacStim' 'rTacStim' 'lfirstAudStim' 'lAudStim' 'rfirstAudStim' 'rAudStim' ...
    'prevReward' 'prevChoice' 'nextChoice' 'water' 'piezo' 'whisk' 'nose' 'fastPupil' 'slowPupil' 'face' 'body' 'Move' 'bhvVideo'};

%index to reconstruct different response kernels
regIdx = [
    ones(1,size(timeR,2))*find(ismember(regLabels,'time')) ...
    ones(1,size(handleChoiceR,2))*find(ismember(regLabels,'handleChoice')) ...
    ones(1,size(stimChoiceR,2))*find(ismember(regLabels,'stimChoice')) ...
    ones(1,size(delayChoiceR,2))*find(ismember(regLabels,'delayChoice')) ...
    ones(1,size(responseChoiceR,2))*find(ismember(regLabels,'responseChoice')) ...
    ones(1,size(handleRewardR,2))*find(ismember(regLabels,'handleReward')) ...
    ones(1,size(stimRewardR,2))*find(ismember(regLabels,'stimReward')) ...
    ones(1,size(delayRewardR,2))*find(ismember(regLabels,'delayReward')) ...
    ones(1,size(responseRewardR,2))*find(ismember(regLabels,'responseReward')) ...
    ones(1,size(lGrabR,2))*find(ismember(regLabels,'lGrab')) ...
    ones(1,size(lGrabRelR,2))*find(ismember(regLabels,'lGrabRel')) ...
    ones(1,size(rGrabR,2))*find(ismember(regLabels,'rGrab')) ...
    ones(1,size(rGrabRelR,2))*find(ismember(regLabels,'rGrabRel')) ...
    ones(1,size(lLickR,2))*find(ismember(regLabels,'lLick')) ...
    ones(1,size(rLickR,2))*find(ismember(regLabels,'rLick')) ...
    ones(1,size(handleSoundR,2))*find(ismember(regLabels,'handleSound')) ...
    ones(1,size(lfirstTacStimR,2))*find(ismember(regLabels,'lfirstTacStim')) ...
    ones(1,size(lTacStimR,2))*find(ismember(regLabels,'lTacStim')) ...
    ones(1,size(rfirstTacStimR,2))*find(ismember(regLabels,'rfirstTacStim')) ...
    ones(1,size(rTacStimR,2))*find(ismember(regLabels,'rTacStim')) ...
    ones(1,size(lfirstAudStimR,2))*find(ismember(regLabels,'lfirstAudStim')) ...
    ones(1,size(lAudStimR,2))*find(ismember(regLabels,'lAudStim')) ...
    ones(1,size(rfirstAudStimR,2))*find(ismember(regLabels,'rfirstAudStim')) ...
    ones(1,size(rAudStimR,2))*find(ismember(regLabels,'rAudStim')) ...
    ones(1,size(prevRewardR,2))*find(ismember(regLabels,'prevReward')) ...
    ones(1,size(prevChoiceR,2))*find(ismember(regLabels,'prevChoice')) ...
    ones(1,size(nextChoiceR,2))*find(ismember(regLabels,'nextChoice')) ...
    ones(1,size(waterR,2))*find(ismember(regLabels,'water')) ...
    ones(1,size(piezoR,2))*find(ismember(regLabels,'piezo')) ...
    ones(1,size(whiskR,2))*find(ismember(regLabels,'whisk')) ...
    ones(1,size(noseR,2))*find(ismember(regLabels,'nose')) ...
    ones(1,size(fastPupilR,2))*find(ismember(regLabels,'fastPupil')) ...
    ones(1,size(slowPupilR,2))*find(ismember(regLabels,'slowPupil')) ...
    ones(1,size(faceR,2))*find(ismember(regLabels,'face')) ...
    ones(1,size(bodyR,2))*find(ismember(regLabels,'body')) ...
    ones(1,size(moveR,2))*find(ismember(regLabels,'Move')) ...
    ones(1,size(vidR,2))*find(ismember(regLabels,'bhvVideo'))];

% orthogonalize video against spout/handle movement
vidIdx = find(ismember(regIdx, find(ismember(regLabels,{'Move' 'bhvVideo'})))); %index for video regressors
trialIdx = ~isnan(mean(fullR(:,vidIdx),2)); %don't use trials that failed to contain behavioral video data
smallR = [leverInR spoutR spoutOutR];

for iRegs = 1 : length(vidIdx)
    Q = qr([smallR(trialIdx,:) fullR(trialIdx,vidIdx(iRegs))],0); %orthogonalize video against other regressors
    fullR(trialIdx,vidIdx(iRegs)) = Q(:,end); % transfer orthogonolized video regressors back to design matrix
end

% reject trials with broken regressors that contain NaNs
trialIdx = isnan(mean(fullR,2)); %don't use first trial or trials that failed to contain behavioral video data
fprintf(1, 'Rejected %d/%d trials for NaN entries in regressors\n', sum(trialIdx)/frames, trialCnt);
fullR(trialIdx,:) = []; %clear bad trials
%% do the shuffling of labels contained in "shufflelabels" - this can be empty
%worth noting, this does not shuffle the trial labels, it shuffles the
%design matrix columns after they have already been created from the task variable labels for each trial.

if ~isempty(shufflelabels)
    shufflelabels = regLabels(sort(find(ismember(regLabels,shufflelabels)))); %make sure  in the right order
    shuffleinds = find(ismember(regLabels,shufflelabels));
    shuffleregs = ismember(regIdx,shuffleinds);
    for i = find(shuffleregs)
        onecol = fullR(:,i);
        permuted = onecol(randperm(length(onecol)));
        fullR(:,i) = permuted;
    end
end


saveLabels = regLabels;

%% save modified Vc
Vc(:,trialIdx) = []; %clear bad trials
Vc = bsxfun(@minus, Vc, mean(Vc,2)); %should be zero-mean

if strcmpi(dType,'Widefield')
    save([cPath 'interpVc.mat'], 'Vc', 'frames', 'preStimDur', 'postStimDur', 'bTrials');
elseif strcmpi(dType,'twoP')
    DS(:,trialIdx) = []; %clear bad trials
    save([cPath 'interpVc.mat'], 'Vc', 'DS', 'frames', 'preStimDur', 'postStimDur', 'bTrials');
end

%% clear individual regressors
clear stimR lGrabR lGrabRelR rGrabR rGrabRelR waterR lLickR rLickR ...
    lAudStimR rAudStimR rewardR prevRewardR ChoiceR ...
    prevChoiceR prevStimR nextChoiceR repeatChoiceR fastPupilR moveR piezoR whiskR noseR faceR bodyR attentiveR lBiasR rBiasR


%% Run full model

labels = saveLabels;
labels = saveLabels(sort(find(ismember(saveLabels,labels)))); %make sure  in the right order

[Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(fullR,U,Vc,labels,regLabels,regIdx,frames,10);
save([cPath 'allvars.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds','fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3');

%% Run the model for each task variable group
spontMotorLabels = regLabels(29:37);
opMotorLabels = regLabels(10:15);
taskVarLabels = regLabels([1:9,16:28]);

labels = saveLabels(ismember(saveLabels,spontMotorLabels));
labels = saveLabels(sort(find(ismember(saveLabels,labels)))); %make sure  in the right order

[Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(fullR,U,Vc,labels,regLabels,regIdx,frames,10);
save([cPath 'spontmotor.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds','fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3');

labels = saveLabels(ismember(saveLabels,opMotorLabels));
labels = saveLabels(sort(find(ismember(saveLabels,labels)))); %make sure  in the right order

[Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(fullR,U,Vc,labels,regLabels,regIdx,frames,10);
save([cPath 'opmotor.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds','fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3');

labels = saveLabels(ismember(saveLabels,taskVarLabels));
labels = saveLabels(sort(find(ismember(saveLabels,labels)))); %make sure  in the right order

[Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(fullR,U,Vc,labels,regLabels,regIdx,frames,10);
save([cPath 'taskvars.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds','fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3');

%% Now run the model with task variable groups knocked out (for deltaR2 calculation)
labels = saveLabels(~ismember(saveLabels,spontMotorLabels));
labels = saveLabels(sort(find(ismember(saveLabels,labels)))); %make sure  in the right order

[Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(fullR,U,Vc,labels,regLabels,regIdx,frames,10);
save([cPath 'nospontmotor.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds','fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3');

labels = saveLabels(~ismember(saveLabels,opMotorLabels));
labels = saveLabels(sort(find(ismember(saveLabels,labels)))); %make sure  in the right order

[Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(fullR,U,Vc,labels,regLabels,regIdx,frames,10);
save([cPath 'noopmotor.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds','fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3');

labels = saveLabels(~ismember(saveLabels,taskVarLabels));
labels = saveLabels(sort(find(ismember(saveLabels,labels)))); %make sure  in the right order

[Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(fullR,U,Vc,labels,regLabels,regIdx,frames,10);
save([cPath 'notaskvars.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds','fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3');


%% create a flag file to log that this version of the model was run
flag = [cPath mfilename '_hasrun.flag'];
command = ['fsutil file createnew ' flag ' 1'];
system(command);

%% nested functions

% They're gone... Refactored due to conflicting globals.

end



