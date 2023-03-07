function [inds, attendinds,biasinds,Y, postprobs_sorted, bhv] = getStateInds(cPath,Animal,Rec,method,glmFile,dualCase)
Paradigm = 'SpatialDisc';
addpath('C:\Data\churchland\ridgeModel\rateDisc');
glmfile = [cPath filesep Animal filesep 'glm_hmm_models' filesep glmFile]; %Widefield data path

cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
load(glmfile,'posterior_probs','model_training_sessions','state_label_indices'); %load behavior data
model_training_sessions = num2cell(model_training_sessions,2); %convert to a cell for ease
model_training_sessions = strtrim(model_training_sessions);
sessionind = find(strcmp(model_training_sessions,Rec));%find the index of the session we want to pull latent states for
postprob_nonan = posterior_probs{sessionind}; %grab the proper session
nochoice = isnan(bhv.ResponseSide); %trials without choice. used for interpolation of latent state on NaN choice trials (GLMHMM doesn't predict for these trials)
counterind = 1;
numstates = size(postprob_nonan,2);
for i = 1:length(nochoice) %this for loop adds nan's to the latent state array. The nans will ultimatel get discarded later since the encoding model doesn't use trials without choice.
    if ~nochoice(i) %if a choice was made
        postprob_withnan(i,:) = postprob_nonan(counterind,:); %just put the probabilities into the new array
        counterind = counterind + 1;
    else %if no choice was made
        postprob_withnan(i,1:numstates) = NaN; %insert a NaN to new array
    end
end
postprobs = postprob_withnan';
stateinds = str2num(state_label_indices); %stateinds tells us what dimension has what state, the first index of stateinds tells us the index of attentive state
postprobs_sorted = postprobs(stateinds,:); %permute the states so theyre in the correct indices

if strcmp(method,'max')
    [~,state1hot] = max(postprobs_sorted,[],1);
    useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
elseif strcmp(method,'cutoff')
    binary = postprobs_sorted' > .8; %get indices with P(state) > .8
    for i = 1:size(binary,1)
        temp = binary(i,:) == 1;
        if sum(temp) == 0
            state1hot(i) = 0; % if no states are P > .8, set to 0 to indicate no state
        else
            state1hot(i) = find(temp);
        end
    end
    Atemp = state1hot == 1;
    Btemp = state1hot == 2 | state1hot == 3;
    useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
    useIdx = useIdx & (Atemp | Btemp); %and only use trials where P of ANY state was > .8
end

if strcmp(dualCase,'choice')
    inds = find(rateDisc_equalizeTrials(useIdx, state1hot == 1, bhv.ResponseSide == 1, inf, true)); %equalize state AND L/R choices
elseif strcmp(dualCase,'reward')
    inds = find(rateDisc_equalizeTrials(useIdx, state1hot == 1, bhv.Rewarded == 1, inf, true));  %equalize to state AND rewarded vs unrewarded
elseif strcmp(dualCase,'none')
    inds = find(rateDisc_equalizeTrials(useIdx, state1hot == 1, [], inf, []));  %equalize to state only
else
    error('Need to input a valid dualCase parameter')
end

attendinds = inds(state1hot(inds) == 1);
biasinds = inds(state1hot(inds) ~= 1);
Y = state1hot(inds) == 1;
end