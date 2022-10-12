% Look at PCA components and how they correlate with engagement
clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions
animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat'; cPath = 'X:\Widefield';
method = 'cutoff';
%animals = {'mSM66'}; glmFile = 'allaudio_detection.mat'; cPath = 'X:\Widefield';

dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data
mintrials = 0;

%%
count = 1;
for i = 1:length(sessiondates)
    for j = 1:length(sessiondates{i})
        [~,a,b,~,postprobs] = getStateInds(cPath,animals{i},sessiondates{i}{j},'cutoff',glmFile,dualcase);
        %[equalinds,leftinds,rightinds] = getChoiceInds(cPath,animals{i},sessiondates{i}{j});
        [equalinds,leftinds,rightinds] = getStimInds(cPath,animals{i},sessiondates{i}{j});

        if true
            fprintf('\nRunning %s, %s\n',animals{i},sessiondates{i}{j});

            [aVc,bhv,goodtrials] = align2behavior(cPath,animals{i},sessiondates{i}{j},equalinds);
            postprobs = postprobs(:,goodtrials)'; %not all trials have imaging data
            leftinds = find(ismember(goodtrials,leftinds));
            rightinds = find(ismember(goodtrials,rightinds));

            segFrames = [1 aVc.segFrames];
            [aVc,mask] = unSVDalign2allen(aVc.all,aVc.U,aVc.transParams,[],true); %returns the unSVD'd, allen aligned, arrayShrunk movie (and its mask to undo the arrayshrink
            %aVc = aVc.all; %just use the original SVD
            left = aVc(:,:,leftinds);
            right = aVc(:,:,rightinds);

            lmean = mean(left,3,'omitnan');
            rmean = mean(right,3,'omitnan');
            left = left - lmean;
            right = right - rmean;
            aVc(:,:,leftinds) = left;
            aVc(:,:,rightinds) = right;


            %stimframes = segFrames(3):segFrames(4)-1;
            stimframes = segFrames(3) + 2: segFrames(3) + 12; %using the paper params
            %choiceframes = segFrames(5):segFrames(6)-1;
            %choiceframes  = segFrames(5) + 2: segFrames(5) + 12; %using the paper params
            %blVc = aVc(:,blframes,:);
            stimVc = aVc(:,stimframes,:);
            %choiceVc = aVc(:,choiceframes,:);
            clear Avc left right

            meanstimVc = squeeze(mean(stimVc,2,'omitnan'))';
            meanstimVc = movmean(meanstimVc,100,1); %running avg with 20 minute time window here

            [coeff, score, ~, ~, explained] = pca(meanstimVc);
            w = gausswin(50);

            for k = 1:length(goodtrials) - 1
                score(:,k) = nanconv(score(:,k),w,'edge','1d'); %gaussian smooth with 9 minute time window
            end

            p_engaged = postprobs(:,1);
            correct_rate = getCorrectRate(bhv,10);

            w = gausswin(100);
            correct_rate = nanconv(correct_rate,w,'edge','1d');
            p_engaged = nanconv(p_engaged,w,'edge','1d');

            clear P R P2 R2
            for k = 1:length(goodtrials)-1
                [r,p]= corrcoef(correct_rate,score(:,k),'rows','complete');
                [r2,p2]= corrcoef(p_engaged,score(:,k),'rows','complete');
                R(k) = r(1,2); P(k) = p(1,2);
                R2(k) = r2(1,2); P2(k) = p2(1,2);
            end

            [bigR,~] = max(abs(R));
            [bigP,f] = min(abs(P));
            [bigR2,~] = max(abs(R2));
            [bigP2,f2] = min(abs(P2));

            dimsave(count) = f;
            allR(count) = R(f);
            allP(count) = P(f);
            allRfirst(count) = R(1);
            allPfirst(count) = P(1);

            dimsave2(count) = f2;
            allR2(count) = R2(f2);
            allP2(count) = P2(f2);
            allRfirst2(count) = R2(1);
            allPfirst2(count) = P2(1);

            count = count+1;

            figure;
            set(0, 'DefaultLineLineWidth', 2);
            hold on;
            plot(correct_rate);
            plot(p_engaged);
            plot(score(:,1));
            plot(score(:,f));
            plot(score(:,f2));
            title(sprintf('Mouse: %s, Date: %s. Most correlated dimension: %i',animals{i},sessiondates{i}{j},f2));
            legend('smoothed correct rate','smoothed P(engaged)','PC1 score','PCmax performance score','PCmax state score')
        else
            continue
        end
    end
end
clear aVc score coeff meanstimVc mask left right stimVc

%%
figure;hold on;
boxplot(dimsave);
histogram(allPfirst2,30);

