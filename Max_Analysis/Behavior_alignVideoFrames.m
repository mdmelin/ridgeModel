function Behavior_alignVideoFrames(dPath,Animal,Rec,preStimDur)
% Code to create some alignment data for behavioral videos. Creates an
% output file cameraTimes in the target folder that can be used to align
% behavioral videos with events in the SessionData structure or the
% widefield imaging data.
%
% Usage: Behavior_alignVideoFrames(fPath,animal)
% fPath is the path for a folder that contains video data as mp4s,
% corresponding 'frameTimes' fildes and a single behavioral file that
% contains the SessionData structure from Bpod. The output file will be
% written to the same folder.
% animal is the name of the animal in this folder (e.g. mSM63).


%% opts values
% these values are specific for each widefield recording but should usually
% be stiulus onset after 3s (which is frame 90 at 30Hz). To be sure, you can
% load the file 'opts.mat' from a given recording but this should be correct.
opts.preStimDur = preStimDur; %prestim duration in seconds.

%% get behavioral file
bhvFile = dir([dPath filesep Animal filesep 'SpatialDisc' filesep Rec filesep '*_SpatialDisc*.mat']);
load(fullfile(bhvFile.folder, bhvFile.name), 'SessionData');

%% go through trials and determine trial events for behavioral video
cameraTimes = cell(2, size(SessionData.RawEvents.Trial,2));
trialOn = NaN(2, size(SessionData.RawEvents.Trial,2));
stimOn = NaN(2, size(SessionData.RawEvents.Trial,2));
stimOff = NaN(2, size(SessionData.RawEvents.Trial,2));
spoutsIn = NaN(2, size(SessionData.RawEvents.Trial,2));
handlesIn = NaN(2, size(SessionData.RawEvents.Trial,2));
optoStimOn = NaN(2, size(SessionData.RawEvents.Trial,2));
for iTrials = 1:size(SessionData.RawEvents.Trial,2)
    
    % get trial events
    try
        stimTime(iTrials) = SessionData.RawEvents.Trial{iTrials}.Events.Wire3High; %time of stimulus onset - measured from soundcard
    catch
        stimTime(iTrials) = NaN;
    end
    stimEndTime(iTrials) = SessionData.RawEvents.Trial{iTrials}.States.DecisionWait(1);
    handleTime(iTrials) = min(SessionData.RawEvents.Trial{iTrials}.States.Reset(:)); %first reset state causes handles to move in
    spoutTime(iTrials) = SessionData.RawEvents.Trial{iTrials}.States.MoveSpout(1); % time when spouts move in
        
    optoTime(iTrials) = NaN;
    
    if isfield(SessionData,'optoType') && ~isnan(SessionData.optoType(iTrials))
        if SessionData.optoType(iTrials) == 1
            optoTime(iTrials) = stimTime(iTrials); %starts with stimulus
        elseif SessionData.optoType(iTrials) == 2
            optoTime(iTrials) = SessionData.RawEvents.Trial{iTrials}.States.DecisionWait(1); %time of delay onset
        elseif SessionData.optoType(iTrials) == 3
            optoTime(iTrials) = SessionData.RawEvents.Trial{iTrials}.States.MoveSpout(1); %time of response onset
        elseif SessionData.optoType(iTrials) == 4
            optoTime(iTrials) = SessionData.RawEvents.Trial{iTrials}.States.DecisionWait(1) - (SessionData.optoDur(1) + 0.2); %time of delay onset
        elseif SessionData.optoType(iTrials) == 5
            optoTime(iTrials) = SessionData.RawEvents.Trial{iTrials}.Events.Wire3High; %baseline
        end
    end
        
    % get camera frame times
    for iCams = 1 : 2
        
        timeFile = dir([dPath filesep Animal filesep 'video' filesep Rec filesep '*frameTimes*_' num2str(iTrials, '%04i') '_' int2str(iCams) '*']); %frametimes for current video
        
        load([timeFile.folder filesep timeFile.name], 'frameTimes') % load frame times
        % check if timestamps are shifted by an hour. Apparently that can happen sometimes.
        timeCheck = (SessionData.TrialStartTime(iTrials)*86400) - (frameTimes(1:10) * 86400); %time difference between first acquired frame and onset of current trial
        if any(timeCheck > 3540 & timeCheck < 3660) %timeshift by one hour (+- 10seconds)
            if iTrials == 1
                warning('Behavioral and video timestamps are shifted by 1h. Will adjust timestamps in video data accordingly.')
            end
            frameTimes = frameTimes + (1/24); %add one hour
        elseif any(timeCheck > 30)
            error(['Something wrong with timestamps in behavior and video data. Time difference is larger as 30 seconds in file: ' timeFile.name])
        end
        
        trialOn = (SessionData.TrialStartTime(iTrials) * 86400); % absolute trial onset time
        cameraTimes{iCams, iTrials} = frameTimes * 86400 - trialOn; % get frame times for current cam, relative to trial onset time in SessionData
        
        if ~isnan(stimTime(iTrials))
            stimOn(iCams,iTrials) = find(cameraTimes{iCams, iTrials} > stimTime(iTrials),1); %stimulus onset
            stimOff(iCams,iTrials) = find(cameraTimes{iCams, iTrials} > stimEndTime(iTrials),1); %stimulus off
            trialOn(iCams,iTrials) = find(cameraTimes{iCams, iTrials} > (stimTime(iTrials) - opts.preStimDur),1); %onset of the widefield data in frames (usualy 3s earlier)
            spoutsIn(iCams,iTrials) = find(cameraTimes{iCams, iTrials} > spoutTime(iTrials),1); %time of spouts movement
            handlesIn(iCams,iTrials) = find(cameraTimes{iCams, iTrials} > handleTime(iTrials),1); %time of handle movement
            if ~isnan(optoTime(iTrials))
             optoStimOn(iCams,iTrials) = find(cameraTimes{iCams, iTrials} > optoTime(iTrials),1); %time of handle movement
            end
        end
    end
end
savepath = [dPath filesep Animal filesep 'video' filesep Rec];
save([savepath filesep strrep(bhvFile.name,'.mat','_cameraTimes.mat')], 'cameraTimes', 'trialOn', 'stimOn', 'spoutsIn', 'handlesIn', 'stimOff', 'optoStimOn'); % save frame times down
end