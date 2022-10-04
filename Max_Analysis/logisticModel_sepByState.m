function [Mdl,cvAcc,betas_aligned,Vc] = logisticModel_sepByState(cPath,Animal,Rec,glmFile,window,state,modality,shuffle, ignoreflags)

addpath('C:\Data\churchland\ridgeModel\rateDisc');

fprintf('\nTraining logistic decoder for %s, %s.\n',Animal,Rec);
%First, check if we need to run the model for this session, look for flag
%file
checkPath = [cPath filesep Animal filesep 'SpatialDisc' filesep Rec];

if shuffle
    expectedflag = [mfilename '_' modality '_shuff_hasrun.flag'];
else
    expectedflag = [mfilename '_' modality '_hasrun.flag'];
end

fnames = {dir(checkPath).name};
if ismember(expectedflag,fnames) && ~ignoreflags %if the flag file is found and we're not ignoring flag files
    fprintf('\nThere is already a model trained for this session. Skipping...\n\n');
    return %abort the model training
end


[inds,Ainds,Binds,Y] = getModalitybyStateInds(cPath,Animal,Rec,glmFile,state,modality); %This gets us the trials we want to use for training the model.

MINTRIALS = 50;

if length(inds) < MINTRIALS
    Mdl = [];
    cvAcc = [];
    betas_aligned = [];
    Vc = [];
    fprintf(['\nthere are less than ', num2str(MINTRIALS),' trials, skipping this session\n']);
    return;
end




[Vc,bhv,goodtrials] = align2behavior(cPath,Animal,Rec,inds);
temp = ismember(inds,goodtrials); %align2behavior can sometimes return less than requested number of trials if there is no imaging data for a trial
Y = Y(temp);

inds2grab = randperm(length(Y),MINTRIALS); % need to subsample so that decoders have balanced trial numbers
Y = Y(inds2grab);
Vc.all = Vc.all(:,:,inds2grab);

[dims,frames,trials] = size(Vc.all);

if shuffle
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
[betas_aligned,mask] = unSVDalign2allen(meanbetas,Vc.U,Vc.transParams,[],false);

%============= saving below

savepath = [cPath filesep Animal filesep 'SpatialDisc' filesep Rec filesep 'logisticDecode_' char(modality) '.mat'];
if shuffle
    savepath = strrep(savepath,'.mat','_shuffle.mat');
end

% save(savepath,'Mdl','cvAcc','betas_aligned','Vc');
% if shuffle
%     flag = [checkPath filesep mfilename '_' modality '_shuff_hasrun.flag'];
% else
%     flag = [checkPath filesep mfilename '_' modality '_hasrun.flag'];
% end
%
% if ~ismember(expectedflag,fnames)
%     command = ['fsutil file createnew ' flag ' 1'];
%     system(command);
% end

end

%% functions

