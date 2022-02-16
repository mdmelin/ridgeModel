function [Mdl,Yhat,accuracy,betas_aligned,Vc] = logisticModel_state(cPath,Animal,Rec,glmFile,window)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
[stateinds,attendinds,biasinds] = getStateInds(cPath,Animal,Rec,glmFile); %This gets us the trials we want to use for training the model.
[Vc,bhv] = align2behavior(cPath,Animal,Rec,stateinds);
[dims,frames,trials] = size(Vc.all);
Y = ismember(stateinds,attendinds); %attentive state Y = 1

handle = movmean(Vc.handle,window,2);
stim = movmean(Vc.stim,window,2);
delay = movmean(Vc.delay,window,2);
response = movmean(Vc.response,window,2);

smoothed = [handle stim delay response];
clear Yhat
nfolds = 10;
for i = 1:frames
    X = squeeze(smoothed(:,i,:));
    X = zscore(X,[],1)'; %z score over dimensions so weights are normalized
    Mdl = fitclinear(X,Y,'Regularization','Lasso','Learner','logistic','KFold',nfolds); %there should be [pixels,frames] regressors with [trials] samples
    allmodels{i} = Mdl;
    Yhat(i,:) = kfoldPredict(Mdl); %estimate Y for each frame and trial
    end
accuracy = sum(Yhat==Y,2) / trials;
% betaz = zscore(Mdl.Beta); %zscore the betas across pixels
% [betas_aligned,mask] = unSVDalign2allen(betaz,Vc.U,Vc.transParams,[]);
% betas_aligned = arrayShrink(betas_aligned,mask,'split');
betas_aligned = [];%deleteme
end

%% functions

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
inds = find(rateDisc_equalizeTrials(useIdx, state1hot == 1, bhv.ResponseSide == 1, inf, true)); %equalize state and L/R choices
attendinds = inds(state1hot(inds) == 1);
biasinds = inds(state1hot(inds) ~= 1);
end