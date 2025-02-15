function ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,dType)

%Mods by Max Melin. Trains the ridge regression model described in Musall 2019 
%on that same dataset, but adds regressors for neural state (predicted by 
%the Ashwood GLM-HMM). State regressors span the whole trial length and
%include the following states: ___,___,___.
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\rateDisc');
addpath('C:\Data\churchland\ridgeModel\smallStuff');
if ~strcmpi(cPath(end),filesep)
    cPath = [cPath filesep];
end

if ~exist('dType', 'var') || isempty(dType)
    dType = 'Widefield'; %default is widefield data
end

if strcmpi(dType,'twoP')
    piezoLine = 5;     % channel in the analog data that contains data from piezo sensor
    stimLine = 4;      % channel in the analog data that contains stimulus trigger.
    
elseif strcmpi(dType,'Widefield')
    piezoLine = 2;     % channel in the analog data that contains data from piezo sensor
    stimLine = 6;      % channel in the analog data that contains stimulus trigger.
end

Paradigm = 'SpatialDisc';
glmPath = [cPath Animal filesep 'glm_hmm_models'];
cPath = [cPath Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
sPath = ['\\grid-hs\churchland_nlsas_data\data\BpodImager\Animals\' Animal filesep Paradigm filesep Rec filesep]; %server data path. not used on hpc.
% sPath = ['/sonas-hs/churchland/hpc/home/space_managed_data/BpodImager/Animals/' Animal filesep Paradigm filesep Rec filesep]; %server data path. not used on hpc.

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
load([glmPath filesep glmFile],'glmhmm_params','choices','posterior_probs','model_training_sessions','state_label_indices'); %load latent states and model info
SessionData.TrialStartTime = SessionData.TrialStartTime * 86400; %convert trailstart timestamps to seconds
nochoice = isnan(SessionData.ResponseSide); %trials without choice. used for interpolation of latent state on NaN choice trials (GLMHMM doesn't predict for these trials)

model_training_sessions = cellstr(model_training_sessions); %convert to cell
sessionidx = find(strcmp(Rec,model_training_sessions)); %find the index of the session we want to pull latent states for
postprob_nonan = posterior_probs{sessionidx}; %get latent states for desired session
counterind = 1;
for i = 1:length(nochoice) %this for loop adds nan's to the latent state array. The nans will ultimatel get discarded later since the encoding model doesn't use trials without choice. 
    if ~nochoice(i) %if a choice was made
        postprob_withnan(i,:) = postprob_nonan(counterind,:); %just put the probabilities into the new array
        counterind = counterind + 1;
    else %if no choice was made
        postprob_withnan(i,:) = NaN; %insert a NaN to new array
    end
end
postprobs = postprob_withnan;
postprobs = postprobs(:,str2num(state_label_indices)); %permute the states to the correct indices
clear postprob_withnan postprob_nonan;
glmweights = squeeze(glmhmm_params.observations.Wk);
glmweights = glmweights(str2num(state_label_indices),:);
fprintf('\nGLM weights:\n');
disp(glmweights);

% figure;
% plot(glmweights','LineWidth',2);%plot states to make sure predicted labels are reasonable
% y = 5;
% line([1,2],[0,0],'LineStyle','--','Color','black');
% title('Latent state weights - Verify that these labels look correct');
% legend('Attentive','Lbias','Rbias');
% drawnow;
% 
% figure;
% plot(postprobs,'LineWidth',2);%plot states to make sure predicted labels are reasonable
% y = 5;
% title('Posterior probabilities');
% legend('Attentive','Lbias','Rbias');
% drawnow;

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
postprobs = postprobs(bTrials,:); %trim to sessions with good imaging
[~,inds] = max(postprobs,[],2); 
attentiveind = inds == 1; %get attentive trials

%equalize L/R choices
useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
choiceIdx = rateDisc_equalizeTrials(useIdx, bhv.ResponseSide == 1, bhv.Rewarded, inf, true); %equalize correct L/R choices
choiceIdx = rateDisc_equalizeTrials(choiceIdx, attentiveind', bhv.Rewarded, inf, []); %equalize attentive and inattentive state
trials = trials(choiceIdx);
bTrials = bTrials(choiceIdx);
Vc = Vc(:,:,choiceIdx);
postprobs = postprobs(choiceIdx,:);
bhv = selectBehaviorTrials(SessionData,bTrials); %only use completed trials that are in the Vc dataset   
trialCnt = length(bTrials);
[~,trialstates] = max(postprobs,[],2);

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

rewardR = cell(1,trialCnt);
ChoiceR = cell(1,trialCnt);

attentiveR = cell(1,trialCnt); %attentive state regressor added by max

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
    
    %% choice and reward
    stimTemp = false(frames, frames + maxStimShift);
    stimShift = round(stimTime(iTrials) * sRate); %amount of stimshift compared to possible maximum. move diagonal on x-axis accordingly.
    if (stimShift > maxStimShift) || isnan(stimTime(iTrials))
        stimTemp = NaN(frames, frames + maxStimShift); %don't use trial if stim onset is too late
    else
        stimTemp(:, end - stimShift - frames + 1 : end - stimShift) = timeR;
    end
    attentiveR{iTrials} = false(size(stimTemp));
    rewardR{iTrials} = false(size(stimTemp));
    
    if bhv.Rewarded(iTrials) %rewarded
        rewardR{iTrials} = stimTemp; %trial was rewarded
    end
    
    % get L/R choices as binary design matrix
    ChoiceR{iTrials} = false(size(stimTemp));
    if bhv.ResponseSide(iTrials) == 1 %IF LEFT CHOICE!!! Left choice is 1, right is 2
        ChoiceR{iTrials} = stimTemp;
    end
    
    % get attentive state as binary design matrix
    if trialstates(iTrials) == 1
        attentiveR{iTrials} = stimTemp; %mouse was in attentive state for this trial
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

rewardR = cat(1,rewardR{:});
prevRewardR = cat(1,prevRewardR{:});

ChoiceR = cat(1,ChoiceR{:});

attentiveR = cat(1,attentiveR{:});

prevChoiceR = cat(1,prevChoiceR{:});
prevStimR = cat(1,prevStimR{:});
nextChoiceR = cat(1,nextChoiceR{:});
repeatChoiceR = cat(1,repeatChoiceR{:});

waterR = cat(1,waterR{:});

slowPupilR = cat(1,slowPupilR{:});
slowPupilR(~isnan(slowPupilR(:,1)),:) = zscore(slowPupilR(~isnan(slowPupilR(:,1)),:));

%% create full design matrix
fullR = [timeR ChoiceR rewardR lGrabR lGrabRelR rGrabR rGrabRelR ...
    lLickR rLickR handleSoundR lfirstTacStimR lTacStimR rfirstTacStimR rTacStimR ...
    lfirstAudStimR lAudStimR rfirstAudStimR rAudStimR prevRewardR prevChoiceR ...
    nextChoiceR waterR piezoR whiskR noseR fastPupilR ...
    slowPupilR faceR bodyR moveR vidR attentiveR];

% labels for different regressor sets. It is REALLY important this agrees with the order of regressors in fullR.
regLabels = {
    'time' 'Choice' 'reward' 'lGrab' 'lGrabRel' 'rGrab' 'rGrabRel' 'lLick' 'rLick' 'handleSound' ...
    'lfirstTacStim' 'lTacStim' 'rfirstTacStim' 'rTacStim' 'lfirstAudStim' 'lAudStim' 'rfirstAudStim' 'rAudStim' ...
    'prevReward' 'prevChoice' 'nextChoice' 'water' 'piezo' 'whisk' 'nose' 'fastPupil' 'slowPupil' 'face' 'body' 'Move' 'bhvVideo' 'attentive'};

%index to reconstruct different response kernels
regIdx = [
    ones(1,size(timeR,2))*find(ismember(regLabels,'time')) ...
    ones(1,size(ChoiceR,2))*find(ismember(regLabels,'Choice')) ...
    ones(1,size(rewardR,2))*find(ismember(regLabels,'reward')) ...
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
    ones(1,size(vidR,2))*find(ismember(regLabels,'bhvVideo')) ...
    ones(1,size(attentiveR,2))*find(ismember(regLabels,'attentive'))];

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

saveLabels = regLabels;
saveR = fullR;

%% save modified Vc
Vc(:,trialIdx) = []; %clear bad trials
Vc = bsxfun(@minus, Vc, mean(Vc,2)); %should be zero-mean

if strcmpi(dType,'Widefield')
    save([cPath 'interpVc.mat'], 'Vc', 'frames', 'preStimDur', 'postStimDur', 'bTrials');
elseif strcmpi(dType,'twoP')
    DS(:,trialIdx) = []; %clear bad trials
    save([cPath 'interpVc.mat'], 'Vc', 'DS', 'frames', 'preStimDur', 'postStimDur', 'bTrials');
end

%% apply gaussian filter to design matrix if using sub-sampling
% if gaussShift > 1
%     [a,b] = size(fullR);
%
%     % find non-continous regressors (contain values different from -1, 0 or 1)
%     temp = false(size(fullR));
%     temp(fullR(:) ~= 0 & fullR(:) ~= 1 & fullR(:) ~= -1 & ~isnan(fullR(:))) = true;
%     regIdx = nanmean(temp) == 0; %index for non-continous regressors
%
%     % do gaussian convolution. perform trialwise to avoid overlap across trials.
%     trialCnt = a/frames;
%     fullR = reshape(fullR,frames,trialCnt,b);
%     for iTrials = 1:trialCnt
%         fullR(:,iTrials,regIdx) = smoothCol(squeeze(fullR(:,iTrials,regIdx)),gaussShift*2,'gauss');
%     end
%     fullR = reshape(fullR,a,b);
% end

%% clear individual regressors
clear stimR lGrabR lGrabRelR rGrabR rGrabRelR waterR lLickR rLickR ...
    lAudStimR rAudStimR rewardR prevRewardR ChoiceR ...
    prevChoiceR prevStimR nextChoiceR repeatChoiceR fastPupilR moveR piezoR whiskR noseR faceR bodyR attentiveR lBiasR rBiasR

 glmFile = strrep(glmFile,'.mat','_'); %for nicer filenames
 
% run ridge regression in low-D, with state this time
% run model. Zero-mean without intercept. only video qr.
% [ridgeVals, dimBeta] = ridgeMML(Vc', fullR, true); %get ridge penalties and beta weights.
% fprintf('Mean ridge penalty for original video, zero-mean model, WITH state: %f\n', mean(ridgeVals));
% save([cPath 'orgdimBeta_withstate.mat'], 'dimBeta', 'ridgeVals');
% save([cPath filesep 'orgregData_withstate.mat'], 'fullR', 'spoutR', 'leverInR', 'rejIdx' ,'trialIdx', 'regIdx', 'regLabels','gaussShift','fullQRR','-v7.3');
%rateDisc_videoRebuild(cPath, 'org'); % rebuild video regressors by projecting beta weights for each wiedfield dimensions back on the behavioral video data

% [Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(regLabels);
% save([cPath glmFile 'deleteme3.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds', 'fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3'); %this saves model info based on all regressors

%% Run with everything

labels = regLabels(ismember(regLabels,regLabels)); %all labels 
labels = regLabels(sort(find(ismember(regLabels,labels)))); %make sure  in the right order

[Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(labels);
save([cPath glmFile 'fullmodel.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds','fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3'); %this saves model info based on state only

% %% Run with state ONLY
% 
% labels = {'attentive'};
% labels = regLabels(sort(find(ismember(regLabels,labels)))); %make sure  in the right order
% 
% [Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(labels);
% save([cPath glmFile 'onlystate.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds','fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3'); %this saves model info based on state only
% 
% %% run with choice
% labels = {'Choice'};
% labels = regLabels(sort(find(ismember(regLabels,labels)))); %make sure  in the right order
% 
% [Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(labels);
% save([cPath glmFile 'onlychoice.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds', 'fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3'); %this saves model info based on state only
% 
% %% run with reward
% labels = {'reward'};
% labels = regLabels(sort(find(ismember(regLabels,labels)))); %make sure  in the right order
% 
% [Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(labels);
% save([cPath glmFile 'onlyreward.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds', 'fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3'); %this saves model info based on state only
% 
% %% run with prev choice
% labels = {'prevChoice'};
% labels = regLabels(sort(find(ismember(regLabels,labels)))); %make sure  in the right order
% 
% [Vm, fullBeta, R, fullIdx, fullRidge, fullLabels, fullLabelInds, fullMap, fullMovie] = crossValModel(labels);
% save([cPath glmFile 'onlyprevchoice.mat'],'regIdx','rejIdx','Vm', 'fullBeta', 'fullIdx', 'R', 'fullLabels', 'fullLabelInds', 'fullRidge', 'regLabels', 'fullMap', 'fullMovie','-v7.3'); %this saves model info based on state only

%% nested functions

function [Vm, cBeta, cR, subIdx, cRidge, keptLabels, cLabelInds, cMap, cMovie] =  crossValModel(cLabels)
        
        regs2grab = ismember(regIdx,find(ismember(regLabels,cLabels))); %these are just the regressors chosen by labels, no rejection yet
        cR = fullR(:,regs2grab); %grab desired labels from design matrix
        %reject regressors
        rejIdx = nansum(abs(cR)) < 10;
        [~, fullQRR] = qr(bsxfun(@rdivide,cR(:,~rejIdx),sqrt(sum(cR(:,~rejIdx).^2))),0); %orthogonalize design matrix
        %figure; plot(abs(diag(fullQRR))); ylim([0 1.1]); title('Regressor orthogonality'); drawnow; %this shows how orthogonal individual regressors are to the rest of the matrix
        if sum(abs(diag(fullQRR)) > max(size(cR)) * eps(fullQRR(1))) < size(cR,2) %check if design matrix is full rank
            temp = ~(abs(diag(fullQRR)) > max(size(cR)) * eps(fullQRR(1)));
            fprintf('Design matrix is rank-defficient. Removing %d/%d additional regressors.\n', sum(temp), sum(~rejIdx));
            rejIdx(~rejIdx) = temp; %reject regressors that cause rank-defficint matrix
        end
        
        cR = cR(:,~rejIdx); % reject regressors that are too sparse or rank-defficient
        
        regs2grab = regIdx(regs2grab); %get indices that have our desired labels
        
        temporary = unique(regs2grab);
        keptLabels = regLabels(temporary);
        for x = 1 : length(temporary)
            cLabelInds(regs2grab == temporary(x)) = x; %make it so that cLabelInds doesn't skip any integers when we move past a label we don't want
        end
        
        cLabelInds = cLabelInds(~rejIdx); %now reject the regressors (from our subselection of labels) that had NaN's or were rank deficient
        subIdx = cLabelInds; %get rid of this redundant variable later
        
        fprintf(1, 'Rejected %d/%d empty or rank deficient regressors\n', sum(rejIdx),length(rejIdx));
        
        discardLabels = cLabels(~ismember(cLabels,keptLabels));
        
        if length(discardLabels) > 0
            fprintf('\nFully discarded regressor: %s because of NaN''s or emptiness \n', discardLabels{:});
        else 
            fprintf('\nNo regressors were FULLY discarded\n');
        end
        
        %now move on to the regression
        Vm = zeros(size(Vc),'single'); %pre-allocate motor-reconstructed V
        randIdx = randperm(size(Vc,2)); %generate randum number index
        foldCnt = floor(size(Vc,2) / ridgeFolds);
        cBeta = cell(1,ridgeFolds);
        
        for iFolds = 1:ridgeFolds
            dataIdx = true(1,size(Vc,2));
            
            if ridgeFolds > 1
                dataIdx(randIdx(((iFolds - 1)*foldCnt) + (1:foldCnt))) = false; %index for training data
                if iFolds == 1
                    [cRidge, cBeta{iFolds}] = ridgeMML(Vc(:,dataIdx)', cR(dataIdx,:), true); %get beta weights and ridge penalty for task only model
                else
                    [~, cBeta{iFolds}] = ridgeMML(Vc(:,dataIdx)', cR(dataIdx,:), true, cRidge); %get beta weights for task only model. ridge value should be the same as in the first run.
                end
                Vm(:,~dataIdx) = (cR(~dataIdx,:) * cBeta{iFolds})'; %predict remaining data
                
                if rem(iFolds,ridgeFolds/5) == 0
                    fprintf(1, 'Current fold is %d out of %d\n', iFolds, ridgeFolds);
                end
            else
                [cRidge, cBeta{iFolds}] = ridgeMML(Vc', cR, true); %get beta weights for task-only model.
                Vm = (cR * cBeta{iFolds})'; %predict remaining data
                disp('Ridgefold is <= 1, fit to complete dataset instead');
            end
        end
        
        % computed all predicted variance
        Vc = reshape(Vc,size(Vc,1),[]);
        Vm = reshape(Vm,size(Vm,1),[]);
        if length(size(U)) == 3
            U = arrayShrink(U, squeeze(isnan(U(:,:,1))));
        end
        covVc = cov(Vc');  % S x S
        covVm = cov(Vm');  % S x S
        cCovV = bsxfun(@minus, Vm, mean(Vm,2)) * Vc' / (size(Vc, 2) - 1);  % S x S
        covP = sum((U * cCovV) .* U, 2)';  % 1 x P
        varP1 = sum((U * covVc) .* U, 2)';  % 1 x P
        varP2 = sum((U * covVm) .* U, 2)';  % 1 x P
        stdPxPy = varP1 .^ 0.5 .* varP2 .^ 0.5; % 1 x P
        cMap = gather((covP ./ stdPxPy)');
        
        % movie for predicted variance
        cMovie = zeros(size(U,1),frames, 'single');
        for iFrames = 1:frames
            
            frameIdx = iFrames:frames:size(Vc,2); %index for the same frame in each trial
            cData = bsxfun(@minus, Vc(:,frameIdx), mean(Vc(:,frameIdx),2));
            cModel = bsxfun(@minus, Vm(:,frameIdx), mean(Vm(:,frameIdx),2));
            covVc = cov(cData');  % S x S
            covVm = cov(cModel');  % S x S
            cCovV = cModel * cData' / (length(frameIdx) - 1);  % S x S
            covP = sum((U * cCovV) .* U, 2)';  % 1 x P
            varP1 = sum((U * covVc) .* U, 2)';  % 1 x P
            varP2 = sum((U * covVm) .* U, 2)';  % 1 x P
            stdPxPy = varP1 .^ 0.5 .* varP2 .^ 0.5; % 1 x P
            cMovie(:,iFrames) = gather(covP ./ stdPxPy)';
            clear cData cModel
            
        end
        fprintf('Run finished. Mean Rsquared: %f... Median Rsquared: %f\n', mean(cMap(:).^2), median(cMap(:).^2));
        
        
    end

end


