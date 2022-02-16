clc;clear all;close all
cPath = 'X:\Widefield';
Animal = 'mSM63';
Recs = {'16-Jul-2018','17-Jul-2018','18-Jul-2018','19-Jul-2018','20-Jul-2018'};
glmFile = 'allaudio.mat';
%% train a model for choice decode

inds = getChoiceInds(cPath,Animal,Recs{1}); %This gets us the trials we want to use for training the model.
[Vc,bhv] = align2behavior(cPath,Animal,Recs{1},inds);
[dims,frames,trials] = size(Vc.all);
Vc = Vc.all;
clear Yhat;
Y = bhv.ResponseSide - 1;
for i = 1:frames
    X = squeeze(Vc(:,i,:))'; 
    [Mdl,fitinfo] = fitclinear(X,Y,'Regularization','Lasso','Learner','logistic'); %there should be [pixels,frames] regressors with [trials] samples
    allmodels{i} = Mdl;
    Yhat(i,:) = predict(Mdl,X)'; %estimate Y for each frame and trial
end
acc = sum(Yhat==Y,2) / trials;

%% stim decode

inds = getStimInds(cPath,Animal,Recs{1}); %This gets us the trials we want to use for training the model.
[Vc,bhv] = align2behavior(cPath,Animal,Recs{1},inds);
[dims,frames,trials] = size(Vc.all);
Vc = Vc.all;
Y = bhv.CorrectSide - 1;
clear Yhat
for i = 1:frames
    X = squeeze(Vc(:,i,:))'; 
    [Mdl,fitinfo] = fitclinear(X,Y,'Regularization','Lasso','Learner','logistic'); %there should be [pixels,frames] regressors with [trials] samples
    allmodels{i} = Mdl;
    Yhat(i,:) = predict(Mdl,X)'; %estimate Y for each frame and trial
end
acc = sum(Yhat==Y,2) / trials;

%% state decode


stateinds = getStateInds(cPath,Animal,Recs{1},glmFile); %This gets us the trials we want to use for training the model.
[Vc,bhv] = align2behavior(cPath,Animal,Recs{1},stateinds);
[dims,frames,trials] = size(Vc.all);
Vc = Vc.all;
Y = bhv.CorrectSide - 1;
clear Yhat
for i = 1:frames
    X = squeeze(Vc(:,i,:))'; 
    [Mdl,fitinfo] = fitclinear(X,Y,'Regularization','Lasso','Learner','logistic'); %there should be [pixels,frames] regressors with [trials] samples
    allmodels{i} = Mdl;
    Yhat(i,:) = predict(Mdl,X)'; %estimate Y for each frame and trial
end
acc = sum(Yhat==Y,2) / trials;



%% Functions
%the following function gets left and right choices, equal numbers,
%counterbalances correct and incorrect as well
function [inds] = getChoiceInds(cPath,Animal,Rec)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
Paradigm = 'SpatialDisc';
cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
%equalize L/R choices
useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
inds = find(rateDisc_equalizeTrials(useIdx, bhv.ResponseSide == 1, bhv.Rewarded, inf, true)); %equalize correct L/R choices and balance correct/incorrects.
% leftinds = equalinds(bhv.ResponseSide(equalinds) == 1);
% rightinds = equalinds(bhv.ResponseSide(equalinds) == 2);
end

%the following function gets left and right stimulus, equal numbers,
%counterbalances correct and incorrect as well
function inds = getStimInds(cPath,Animal,Rec)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
Paradigm = 'SpatialDisc';
cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
%equalize L/R choices
useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
inds = find(rateDisc_equalizeTrials(useIdx, bhv.CorrectSide == 1, bhv.Rewarded, inf, true)); %equalize correct L/R choices and balance correct/incorrects.
end

function inds = getStateInds(cPath,Animal,Rec,glmFile)
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
postprobs = postprob_withnan;
[~,state1hot] = max(postprobs,[],2);

stateinds = str2num(state_label_indices); %stateinds tells us what dimension has what state, the first index of stateinds tells us the index of attentive state
attendinds = (state1hot == stateinds(1));
biasinds = (state1hot ~= stateinds(1));

useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
inds = find(rateDisc_equalizeTrials(useIdx, (attendinds == 1)', bhv.ResponseSide == 1, inf, true)); %equalize state and choice

end

%% graveyard
% for i = 1:frames
%     X = squeeze(Vc(:,i,:))'; 
%     Mdl2 = fitclinear(X,Y,'Kfold',10,'Regularization','Lasso','Learner','logistic'); %there should be [pixels,frames] regressors with [trials] samples
%     allmodels2{i} = Mdl;
%     
%     trainidx = training(Mdl2.Partition);
%     testidx = test(Mdl2.Partition);
%     
%     Yhattrain(i,:) = predict(Mdl,X(trainidx,:))'; 
%     Yhattest(i,:) = predict(Mdl,X(testidx,:))';
% end
% acctrain = sum(Yhattrain==Y(trainidx),2) / size(Yhattrain,2);
% acctest = sum(Yhattest==Y(testidx),2) / size(Yhattest,2);
