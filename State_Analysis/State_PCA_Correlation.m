% Look at PCA components and how they correlate with engagement
clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions
animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat'; cPath = 'X:\Widefield';
method = 'cutoff';

mintrialnum = 25; %the minimum number of trials per state to be included in plotting
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

%%
mintrials = 20; count = 1;
for i = 1:length(sessiondates)
    for j = 1:length(sessiondates{i})
        [inds,a,b,~,postprobs] = getStateInds(cPath,animals{i},sessiondates{i}{j},'cutoff',glmFile,dualcase);
        trials = 1:1000;
        if length(a) > mintrials
            fprintf('\nRunning %s, %s\n',animals{i},sessiondates{i}{j});

            [aVc,~,goodtrials] = align2behavior(cPath,animals{i},sessiondates{i}{j},trials);
            postprobs = postprobs(:,goodtrials)'; %not all trials have imaging data
            segFrames = [1 aVc.segFrames];
            [aVc,mask] = unSVDalign2allen(aVc.all,aVc.U,aVc.transParams,[],true); %returns the unSVD'd, allen aligned, arrayShrunk movie (and its mask to undo the arrayshrink

            blframes = segFrames(1):segFrames(2)-1;
            stimframes = segFrames(3):segFrames(4)-1;
            delayframes = segFrames(4):segFrames(5)-1;
            choiceframes = segFrames(5):segFrames(6)-1;
            blVc = aVc(:,blframes,:);
            stimVc = aVc(:,stimframes,:);
            delayVc = aVc(:,delayframes,:);
            choiceVc = aVc(:,choiceframes,:);
            clear Avc
            meanblVc = squeeze(mean(blVc,2,'omitnan'))';
            meanstimVc = squeeze(mean(stimVc,2,'omitnan'))';
            meandelayVc = squeeze(mean(delayVc,2,'omitnan'))';
            meanchoiceVc = squeeze(mean(choiceVc,2,'omitnan'))';

            [coeff, score, ~, ~, explained] = pca(meanchoiceVc);
            p_engaged = postprobs(:,1);

            for k = 1:length(goodtrials)-1
                [r,p]= corrcoef(p_engaged,score(:,k),'rows','complete');
                R(k) = r(1,2); P(k) = p(1,2);
            end

            [bigR,f] = max(abs(R));
            [bigP,f2] = min(abs(P));

            dimsave1(count) = f;
            dimsave2(count) = f2;
            allR(count) = R(f2);
            allP(count) = P(f2);

            count = count+1;
        else
            continue
        end
    end
end


