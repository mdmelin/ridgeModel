function [Mdl,cvAcc,betas_aligned,Vc] = logisticModel_sepByState(cPath,Animal,Rec,glmFile,window,state,modality,shuffle)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
[inds,Ainds,Binds,Y] = getModalitybyStateInds(cPath,Animal,Rec,glmFile,state,modality); %This gets us the trials we want to use for training the model.

if length(inds) < 100
    Mdl = [];
    cvAcc = [];
    betas_aligned = [];
    Vc = [];
    fprintf('\nthere are less than 100 trials, skipping this session\n');
    return;
end

[Vc,bhv] = align2behavior(cPath,Animal,Rec,inds);
[dims,frames,trials] = size(Vc.all);

if shuffle == "True"
    Y = Y(randperm(length(Y)));
end

smoothed = movmean(Vc.all,window,2);

clear Yhat
nfolds = 10;
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

%% functions

