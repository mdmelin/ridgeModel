function [Mdl,cvAcc,betas_aligned,Vc] = logisticModel(cPath,Animal,Rec,glmFile,window,modality,shuffle)
addpath('C:\Data\churchland\ridgeModel\rateDisc');

if modality == "State"
    [inds,Ainds,Binds] = getStateInds(cPath,Animal,Rec,glmFile); %This gets us the trials we want to use for training the model.
    Y = ismember(inds,Ainds); %attentive state Y = 1
elseif modality == "Choice"
    [inds,Ainds,Binds] = getChoiceInds(cPath,Animal,Rec);
    Y = ismember(inds,Binds); %right choice Y = 1
elseif modality == "Reward"
    [inds,Ainds,Binds] = getRewardInds(cPath,Animal,Rec);
    Y = ismember(inds,Ainds); %rewarded Y = 1
end

if length(inds) < 200
    Mdl = [];
    cvAcc = [];
    betas_aligned = [];
    Vc = [];
    fprintf('\nthere are less than 200 trials, skipping this session\n');
    return;
end

if shuffle == "True"
    Y = Y(randperm(length(Y)));
end

[Vc,bhv] = align2behavior(cPath,Animal,Rec,inds); %align to behavior 
[dims,frames,trials] = size(Vc.all);

smoothed = movmean(Vc.all,window,2); %smooth

clear Yhat
nfolds = 10; %k-fold crossval
for i = 1:frames
    X = squeeze(smoothed(:,i,:))';
    X = zscore(X,[],2); %z score over dimensions so weights are normalized
    Mdl = fitclinear(X,Y,'Regularization','Lasso','Learner','logistic','KFold',nfolds); %there should be [pixels,frames] regressors with [trials] samples
    allmodels{i} = Mdl;
    cvAcc(i) = 1-kfoldLoss(Mdl);
    
    for j = 1:nfolds
        betas(i,j,:) = Mdl.Trained{j}.Beta; %betas are [frames,folds,dims]
    end
end
meanbetas = squeeze(mean(betas,2))'; %average over folds
[betas_aligned,mask] = unSVDalign2allen(meanbetas,Vc.U,Vc.transParams,[]);
betas_aligned = arrayShrink(betas_aligned,mask,'split');
end
