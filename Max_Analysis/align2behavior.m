function [alignVc,bhv] = align2behavior(cPath,Animal,Rec,trialInds)
%where trialInds is the desired trials to select for alignment
%pass trialinds based on the sessiondata file, this function will work out
%the imaging data itself and discard requested trials that dont have imaging data.
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallstuff');
Paradigm = 'SpatialDisc';
cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
dims = 200; %number of dims of widefield SVD
%% Load data
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
SessionData.TrialStartTime = SessionData.TrialStartTime * 86400; %convert trailstart timestamps to seconds
nochoice = isnan(SessionData.ResponseSide); %trials without choice. used for interpolation of latent state on NaN choice trials (GLMHMM doesn't predict for these trials)
sRate = 30;
load([cPath 'Vc.mat'],'Vc','U','trials','bTrials'); %just need trials variable here. Vs is [dims of temporal components,frames,trials]
load([cPath 'opts2.mat'],'opts');
nRequested = length(trialInds);

%% get proper trials from Vc and SessionData
% ensure there are not too many trials in Vc
ind = trials > SessionData.nTrials;
trials(ind) = [];
bTrials(ind) = []; %btrials gives the indices of bpod trial numbers that have imaging data
Vc(:,:,ind) = [];

temp = trialInds(ismember(trialInds,bTrials)); %use only trial indices to grab that are in the Vc dataset. contains only bpod trial numbers that have imaging data.
bhv = selectBehaviorTrials(SessionData,temp); %this grabs trials that are in the requested indices AND the Vc dataset
bTrials = find(ismember(bTrials,trialInds)); %gets the indices of trialInds that have their bpod trial number contained in bTrials
Vc = Vc(:,:,bTrials);
nTrials = length(bTrials);

fprintf('Requested %i trials. Using %i trials (Vc dataset usually has a few missing trials).\n',nRequested,nTrials);

[~,~,a] = size(Vc);
b = length(bhv.CorrectSide);
if a~=b
    error('Size of data is not consistent!!!')
end

%% Some variables to be edited depending on how you want to align to trial events!

%these are to do with the Vc alignment to handlegrab
preStimDur = floor(2 * sRate) / sRate; % Duration of trial before lever grab in seconds - AFTER ALIGNMENT
postStimDur = floor(3.3 * sRate) / sRate; % Duration of trial after lever grab onset in seconds - AFTER ALIGNMENT
frames = round((preStimDur + postStimDur) * sRate); %nr of frames per trial - AFTER ALIGNMENT
trialDur = (frames * (1/sRate)); %duration of trial in seconds - AFTER ALIGNMENT

%other variables - how many seconds to grab around trial events,
%we will convert to frames later

grabPreTime = .75;   % preceed handle grab for .75 second 
grabPostTime = .5;   % follow handle grab for  0.5 seconds
grabPreTime = 0;   % preceed handle grab for .75 second 
grabPostTime = 0;   % follow handle grab for  0.5 seconds
fsPreTime = 1.5;   % preceed first stim event
fsPostTime = 1;   % follow first stim event - longest stim duration should be 2 seconds, most will be shorter
delayPreTime = 0; %this should always be zero otherwise some stimulus will be included
delayPostTime = .5;   % follow stim events for sPostStim in seconds - gives delay time, so should start from END of stim period. Should not be longer than .5 seconds. 
responsePreTime = 0;   % preceed response window for certain number of seconds
responsePostTime = .05; %MODIFY  % follow response window for certain number of seconds

shVal = sRate * opts.preStim  + 1; %expected position of stimulus onset in the imaging data (s).
%% getting trial timestamps


for iTrials = 1:nTrials %compute the times of trial events, all relative to HANDLE GRAB
    
    leverTimes = [reshape(bhv.RawEvents.Trial{iTrials}.States.WaitForAnimal1',1,[]) ...
        reshape(bhv.RawEvents.Trial{iTrials}.States.WaitForAnimal2',1,[]) ...
        reshape(bhv.RawEvents.Trial{iTrials}.States.WaitForAnimal3',1,[])];
    
    try
        stimGrab(iTrials) = leverTimes(find(leverTimes == bhv.RawEvents.Trial{iTrials}.States.WaitForCam(1))-1); %find start of lever state that triggered stimulus onset
        handleSounds{iTrials} = leverTimes(1:2:end) - stimGrab(iTrials); %track indicator sound when animal is grabing both handles
        stimTime(iTrials) = bhv.RawEvents.Trial{iTrials}.Events.Wire3High - stimGrab(iTrials); %time of stimulus onset - measured from soundcard
        stimEndTime(iTrials) = bhv.RawEvents.Trial{iTrials}.States.DecisionWait(1) - stimGrab(iTrials); %end of stimulus period, relative to handle grab
    catch
        stimTime(iTrials) = NaN;
        stimEndTime(iTrials) = NaN;
        stimGrab(iTrials) = 0;
    end
    
    spoutTime(iTrials) = bhv.RawEvents.Trial{iTrials}.States.MoveSpout(1) - stimGrab(iTrials); %spouts in time relative to handle grab time
    delayDuration(iTrials) = spoutTime(iTrials) - stimEndTime(iTrials); %length of the delay period. from end of stimulus to spouts in.
    leverIn(iTrials) = min(bhv.RawEvents.Trial{iTrials}.States.Reset(:)) - stimGrab(iTrials); %first reset state causes lever to move in
    
    if ~isnan(bhv.RawEvents.Trial{iTrials}.States.Reward(1)) %check for reward state
        water(iTrials) = bhv.RawEvents.Trial{iTrials}.States.Reward(1) - stimGrab(iTrials); %the time that water came relative to handle grab
    else
        water(iTrials) = NaN;
    end
end

%% re-align behavioral data and Vc to lever grab instead of stimulus onset
iiSpikeFrames = findInterictalSpikes(U, Vc, 2, false); %find interictal spikes
Vc = interpOverInterictal(Vc, iiSpikeFrames); %interpolate over interictal spikes


% re-align video/imaging data. currently its aligned to stimulus onset. 
temp1 = NaN(dims,frames,nTrials);
for x = 1 : nTrials %iterate thru trials
    try
        toby = (shVal - ceil(stimTime(x) / (1/sRate))) - (preStimDur * sRate) : (shVal - ceil(stimTime(x) / (1/sRate))) + (postStimDur * sRate) - 1; %unused variable. just to inspect what frames we're grabbing. 
        temp1(:,:,x) = Vc(:,(shVal - ceil(stimTime(x) / (1/sRate))) - (preStimDur * sRate) : (shVal - ceil(stimTime(x) / (1/sRate))) + (postStimDur * sRate) - 1,x);
        
        %now do behavioral variables
        stimShift(x) = round(stimTime(x) * sRate); %amount of stimshift. move diagonal on x-axis accordingly.
        handleReg(x) = preStimDur*sRate; %frame that is aligned with handle grab. should NEVER change because imaging is aligned to handlegrab
        stimReg(x) = round((preStimDur + stimTime(x)) * sRate); %frame that is aligned with stimulus onset. Gives the frame in the realigned imaging where the stimon occured. 
        delayReg(x) = floor((preStimDur + stimEndTime(x)) * sRate); %onset of delay period. round down to ensure there is at least one frame for the delay.
        responseReg(x) = ceil((preStimDur + spoutTime(x)) * sRate); %prestimdur tells us time to the handle grab in the realigned imaging data. spoutTime tells us time from handlegrab to spouts in. so add em up and convert to frames. 
    catch
        fprintf(1,'Could not align trial %d. Relative stim time: %fs\n', x, stimTime(x));
    end
end
Vc = temp1; clear temp1 %dims are [SVDdims,frames,trials]. This is the realigned imaging data (aligned to handle grab). 
time = 0:1/sRate:trialDur; 
time = time - time(handleReg(1)); %set t=0 to handle grab event
time = time(1:end-1); %the handlegrab aligned time for each frame


%% Now grab imaging frames for the different trial periods
grabPreFrames = ceil(grabPreTime * sRate);   % preceed handle grab for certain number of frames - 1 second curently
grabPostFrames = ceil(grabPostTime * sRate);   % follow handle grab for certain number of frames - 0 seconds currently
fsPreFrames = ceil(fsPreTime * sRate);   % preceed first stim event for fsPreTime in frames
fsPostFrames = ceil(fsPostTime * sRate);   % follow first stim event for fsPostStim in frames
delayPreFrames = ceil(delayPreTime * sRate);   %gives delay time, so should start from END of stim period.
delayPostFrames = ceil(delayPostTime * sRate);   %gives delay time, so should start from END of stim period.
responsePreFrames = ceil(responsePreTime * sRate);   % preceed choice for certain number of frames
responsePostFrames = ceil(responsePostTime * sRate);   % follow choice for certain number of frames

Vc_handle = NaN(dims,grabPreFrames+grabPostFrames+1,nTrials);
Vc_stim = NaN(dims,fsPreFrames+fsPostFrames+1,nTrials);
Vc_delay = NaN(dims,delayPreFrames+delayPostFrames+1,nTrials);
Vc_response = NaN(dims,responsePreFrames+responsePostFrames+1,nTrials);

for i = 1:nTrials
temp1 = handleReg(i)-grabPreFrames : handleReg(i)+grabPostFrames;
Vc_handle(:,:,i) = Vc(:,temp1,i);
handleLength = size(Vc_handle,2);
aligned_handleind = grabPreFrames+1; %now for all trials in Vc_handle, the handles move in at the index of aligned_handleind

temp2 = stimReg(i)-fsPreFrames : stimReg(i)+fsPostFrames;
Vc_stim(:,:,i) = Vc(:,temp2,i);
stimLength = size(Vc_stim,2);
aligned_stimind = fsPreFrames+1;

temp3 = delayReg(i)-delayPreFrames : delayReg(i)+delayPostFrames; %gets the frame indices around the event of interest
Vc_delay(:,:,i) = Vc(:,temp3,i); %grab these frame for the corresponding trial and put them into an event aligned matrix
delayLength = size(Vc_delay,2); %should never change
aligned_delayind = delayPreFrames+1; %tells us what index the event occurred at in the aligned matrix

temp4 = responseReg(i)-responsePreFrames : responseReg(i)+responsePostFrames;
Vc_response(:,:,i) = Vc(:,temp4,i);
responseLength = size(Vc_response,2);
aligned_responseind = responsePreFrames+1;
end

Vc_aligned = cat(2,Vc_handle, Vc_stim, Vc_delay, Vc_response); %put them all into one big aligned matrix

a = aligned_handleind;
b = handleLength + aligned_stimind;
c = handleLength + stimLength + aligned_delayind;
d = handleLength + stimLength + delayLength + aligned_responseind;
behavior_inds = [a,b,c,d]; %The indices in Vc_aligned of each trial event [handlegrab, stimOn, delayStart, spoutsIn]

alignVc.all = Vc_aligned; %all data combined
alignVc.allinds = behavior_inds; %behavior indices of combined data
alignVc.handle = Vc_handle;
alignVc.stim = Vc_stim;
alignVc.delay = Vc_delay;
alignVc.response = Vc_response; 

alignVc.handleind = aligned_handleind;
alignVc.stimind = aligned_stimind;
alignVc.delayind = aligned_delayind;
alignVc.responseind = aligned_responseind;
alignVc.U = U;

load([cPath 'opts3.mat']); %get allen stuff while were here
alignVc.transParams = opts3.transParams;
end
