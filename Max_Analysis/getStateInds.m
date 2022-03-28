function [inds, attendinds,biasinds] = getStateInds(cPath,Animal,Rec,glmFile)
Paradigm = 'SpatialDisc';
glmfile = [cPath filesep Animal filesep 'glm_hmm_models' filesep glmFile]; %Widefield data path

cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
load(glmfile,'posterior_probs','model_training_sessions','state_label_indices'); %load behavior data
model_training_sessions = num2cell(model_training_sessions,2); %convert to a cell for ease

sessionind = find(strcmp(model_training_sessions,Rec));%find the index of the session we want to pull latent states for
postprob_nonan = posterior_probs{sessionind}; %grab the proper session
nochoice = isnan(bhv.ResponseSide); %trials without choice. used for interpolation of latent state on NaN choice trials (GLMHMM doesn't predict for these trials)
counterind = 1;

for i = 1:length(nochoice) %this for loop adds nan's to the latent state array. The nans will ultimatel get discarded later since the encoding model doesn't use trials without choice.
    if ~nochoice(i) %if a choice was made
        postprob_withnan(i,:) = postprob_nonan(counterind,:); %just put the probabilities into the new array
        counterind = counterind + 1;
    else %if no choice was made
        postprob_withnan(i,:) = NaN; %insert a NaN to new array
    end
end
postprobs = postprob_withnan';
stateinds = str2num(state_label_indices); %stateinds tells us what dimension has what state, the first index of stateinds tells us the index of attentive state

postprobs_sorted = postprobs(stateinds,:); %permute the states so theyre in the correct indices


[~,state1hot] = max(postprobs_sorted,[],1);

useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
inds = find(rateDisc_equalizeTrials(useIdx, state1hot == 1, bhv.Rewarded == 1, inf, true));  %equalize to rewarded vs unrewarded
%inds = find(rateDisc_equalizeTrials(useIdx, state1hot == 1, bhv.ResponseSide == 1, inf, true)); %equalize state and L/R choices, should also do reward. 
attendinds = inds(state1hot(inds) == 1);
biasinds = inds(state1hot(inds) ~= 1);
end