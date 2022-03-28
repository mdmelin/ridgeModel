% This function returns state equalized indices for the desired modality
% (choice, stimulus, etc.). It is called by logisticModel_sepByState().
function [inds,Ainds,Binds,Y] = getModalitybyStateInds(cPath,Animal,Rec,glmfile,state,modality)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
Paradigm = 'SpatialDisc';

glmpath = [cPath filesep Animal filesep 'glm_hmm_models' filesep];
cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path

bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;

load([glmpath glmfile],'posterior_probs','model_training_sessions','state_label_indices'); %load behavior data
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

%equalize L/R choices for given state
if state == "Attentive"
    useIdx = ~isnan(bhv.ResponseSide) & state1hot == 1; %only use performed trials from desired state
elseif state == "Bias"
    useIdx = ~isnan(bhv.ResponseSide) & state1hot ~= 1; %only use performed trials from desired state
end

if modality == "Choice"
    inds = find(rateDisc_equalizeTrials(useIdx, bhv.ResponseSide == 1, bhv.Rewarded, inf, true)); %equalize correct L/R choices and balance correct/incorrects.
    choices = bhv.ResponseSide(inds);
    Ainds = inds(choices == 2); %right choices
    Binds = inds(choices == 1); %left choices
    Y = choices == 2; %right choices Y=1
elseif modality == "Stimulus"
    inds = find(rateDisc_equalizeTrials(useIdx, bhv.StimulusSide == 1, bhv.ResponseSide == 1, inf, true)); %equalize stimulus side with secondary L/R choice equalization
end




end