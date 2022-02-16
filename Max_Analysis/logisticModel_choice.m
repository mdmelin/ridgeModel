function [Mdl,Yhat,accuracy,betas_aligned,Vc] = logisticModel_choice(cPath,Animal,Rec,glmFile,window)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
[inds,~,~] = getChoiceInds(cPath,Animal,Rec); %This gets us the trials we want to use for training the model.
[Vc,bhv] = align2behavior(cPath,Animal,Rec,inds);
[dims,frames,trials] = size(Vc.all);
Y = bhv.ResponseSide - 1; %get the choices

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

function [equalinds,leftinds,rightinds] = getChoiceInds(cPath,Animal,Rec)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
Paradigm = 'SpatialDisc';
cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
%equalize L/R choices
useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
equalinds = find(rateDisc_equalizeTrials(useIdx, bhv.ResponseSide == 1, bhv.Rewarded, inf, true)); %equalize correct L/R choices and balance correct/incorrects.

leftinds = equalinds(bhv.ResponseSide(equalinds) == 1);
rightinds = equalinds(bhv.ResponseSide(equalinds) == 2);
end