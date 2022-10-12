function [Mdl,cvAcc,betas_aligned,Vc] = logisticModel(cPath,Animal,Rec,glmFile,mintrials, window,modality,shuffle,ignoreflags)
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

%===============================

addpath('C:\Data\churchland\ridgeModel\rateDisc');


if modality == "State" 
    [inds,Ainds,Binds,Y] = getStateInds(cPath,Animal,Rec,'cutoff',glmFile,true); %This gets us the trials we want to use for training the model. Doesnt care if imaging data exists or not
    [Vc,bhv,goodtrials] = align2behavior(cPath,Animal,Rec,inds); %align imaging data to behavior
    [dims,frames,trials] = size(Vc.all);
    temp = ismember(inds,goodtrials);
    Y = Y(temp);
    

elseif modality == "Choice"
    %equalize L/R choices
    cPath2 = [cPath filesep Animal filesep 'SpatialDisc' filesep Rec filesep]; %Widefield data path
    bhvFile = dir([cPath2 filesep Animal '_' 'SpatialDisc' '*.mat']);
    load([bhvFile(1).folder filesep bhvFile(1).name ],'SessionData'); %load behavior data
    bhv = SessionData;clear SessionData;clear bhvFile;
    useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
    inds = find(rateDisc_equalizeTrials(useIdx, bhv.ResponseSide == 1, bhv.Rewarded, inf, true)); %equalize correct L/R choices and balance correct/incorrects.
    Ainds = inds(bhv.ResponseSide(inds) == 1);
    Binds = inds(bhv.ResponseSide(inds) == 2);
    [Vc,bhv,goodtrials] = align2behavior(cPath,Animal,Rec,inds); %align imaging data to behavior
    [dims,frames,trials] = size(Vc.all);
    Y = bhv.ResponseSide == 2; %right choice Y = 1

elseif modality == "Stimside"
    %equalize L/R stimside
    cPath2 = [cPath filesep Animal filesep 'SpatialDisc' filesep Rec filesep]; %Widefield data path
    bhvFile = dir([cPath2 filesep Animal '_' 'SpatialDisc' '*.mat']);
    load([bhvFile(1).folder filesep bhvFile(1).name ],'SessionData'); %load behavior data
    bhv = SessionData;clear SessionData;clear bhvFile;
    useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
    inds = find(rateDisc_equalizeTrials(useIdx, bhv.CorrectSide == 1, bhv.ResponseSide == 1, inf, true)); %equalize correct side and balance choice
    Ainds = inds(bhv.CorrectSide(inds) == 1);
    Binds = inds(bhv.CorrectSide(inds) == 2);
    [Vc,bhv,goodtrials] = align2behavior(cPath,Animal,Rec,inds); %align imaging data to behavior
    [dims,frames,trials] = size(Vc.all);
    Y = bhv.CorrectSide == 2; %right side Y = 1

elseif modality == "Reward" % THIS NEEDS TO BE REWORKED, SEE "CHOICE"
    error('see comment');
    [inds,Ainds,Binds] = getRewardInds(cPath,Animal,Rec);
    Y = ismember(inds,Ainds); %rewarded Y = 1
end

MINTRIALS = mintrials;

if length(inds) < MINTRIALS
    Mdl = [];
    cvAcc = [];
    betas_aligned = [];
    Vc = [];
    fprintf('\nthere are less than %i trials, skipping this session\n',MINTRIALS);
    return;
end

%++++++++
temp = ismember(inds,goodtrials); %align2behavior can sometimes return less than requested number of trials if there is no imaging data for a trial

% inds2grab = randperm(length(Y),MINTRIALS); % need to subsample so that decoders have balanced trial numbers
% Y = Y(inds2grab);
% Vc.all = Vc.all(:,:,inds2grab);

[dims,frames,trials] = size(Vc.all);

%++++++

if shuffle
    Y = Y(randperm(length(Y)));
end

smoothed = movmean(Vc.all,window,2); %smooth

clear Yhat
nfolds = 10; %k-fold crossval
for i = 1:frames
    %fprintf('\n%i',i);
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
[betas_aligned,~] = unSVDalign2allen(meanbetas,Vc.U,Vc.transParams,[],false);

savepath = [cPath filesep Animal filesep 'SpatialDisc' filesep Rec filesep 'logisticDecode_' char(modality) '.mat'];
if shuffle
    savepath = strrep(savepath,'.mat','_shuffle.mat');
end
save(savepath,'Mdl','cvAcc','betas_aligned','Vc');


if shuffle
    flag = [checkPath filesep mfilename '_' modality '_shuff_hasrun.flag'];
else
    flag = [checkPath filesep mfilename '_' modality '_hasrun.flag'];
end

if ~ismember(expectedflag,fnames)
    command = ['fsutil file createnew ' flag ' 1'];
    system(command);
end

end
