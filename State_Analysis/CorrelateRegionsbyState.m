% Ideally, this would be done on a visual task.... But simon does find that
% V1/V2 and M2 correlations go up with task learning. Lets try to replicate
% his correlation matrices for the different brain areas, but split up by
% state instead of learning.

clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions
cPath = 'X:\Widefield';

%animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'allaudio_detection.mat'; %32 not working for some reason
animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; %CSP32 missing transparams


method = 'signal';
dualCase = true
mintrialnum = 25; %the minimum number of trials per state to be included in plotting
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data
cmin = 0;
cmax = 1;
cmin2 = -.1;
cmax2 = .1;
%% Correlations
areaindices = 1:64;
load('C:\Data\churchland\ridgeModel\allenDorsalMapSM.mat');
areamap = dorsalMaps.areaMap(1:540,:); %allen edge map
clear dorsalMaps
count = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fprintf('\nRunning %s, session %i of %i for this animal.\n',animals{i},j,length(sessiondates{i}));
        [inds, Ainds,Binds] = getStateInds(cPath,animals{i},sessiondates{i}{j},'max',glmFile,dualCase);

        if length(Ainds) < 20 %skip session if less than 40 trials in each state
            continue
        end

        [aVc,~] = align2behavior(cPath,animals{i},sessiondates{i}{j},Ainds); %Align imaging to behavior. Pass trialinds based on the sessiondata file, this function will work out the imaging data
        [bVc,~] = align2behavior(cPath,animals{i},sessiondates{i}{j},Binds);

        nframes = size(aVc.all,2);
        ntrialsA = size(aVc.all,3);
        ntrialsB = size(bVc.all,3);
        clear Aavg Bavg
        Aavg = ones(length(areaindices), nframes,ntrialsA); Bavg = ones(length(areaindices), nframes, ntrialsB);
        for k = 1:length(areaindices) %we need to average over areas now in order to free up memory
            fprintf('\n%i',k);
            [Atemp,~] = unSVDalign2allen(aVc.all,aVc.U,aVc.transParams,k,true);
            Aavg(k,:,:) = squeeze(mean(Atemp,1,'omitnan'));
            clear Atemp;
            [Btemp,~] = unSVDalign2allen(bVc.all,bVc.U,bVc.transParams,k,true);
            Bavg(k,:,:) = squeeze(mean(Btemp,1,'omitnan'));
            clear Btemp;
        end
        clear Atemp Btemp aVc bVc 

        for k = 1:length(areaindices)
            for l = 1:length(areaindices)
                if strcmp(method,'signal')
                    Amovie1 = squeeze(mean(Aavg(k,:,:),3,'omitnan')); %average over trials
                    Amovie2 = squeeze(mean(Aavg(l,:,:),3,'omitnan'));
                    Bmovie1 = squeeze(mean(Bavg(k,:,:),3,'omitnan'));
                    Bmovie2 = squeeze(mean(Bavg(l,:,:),3,'omitnan'));

                    Acorr = corrcoef(Amovie1, Amovie2,'rows','pairwise');
                    Bcorr = corrcoef(Bmovie1,Bmovie2,'rows','pairwise');
                    A(k,l) = Acorr(1,2);
                    B(k,l) = Bcorr(1,2);

                elseif strcmp(method,'full')
                    Amovie1 = reshape(squeeze(Aavg(k,:,:)),[],1); %grab the data from one region and reshape it
                    Amovie2 = reshape(squeeze(Aavg(l,:,:)),[],1);
                    Bmovie1 = reshape(squeeze(Bavg(k,:,:)),[],1); %grab the data from one region and reshape it
                    Bmovie2 = reshape(squeeze(Bavg(l,:,:)),[],1);

                    Acorr = corrcoef(Amovie1, Amovie2,'rows','pairwise');
                    Bcorr = corrcoef(Bmovie1,Bmovie2,'rows','pairwise');
                    A(k,l) = Acorr(1,2);
                    B(k,l) = Bcorr(1,2);

                elseif strcmp(method,'noise')
                    Amovie1 = squeeze(Aavg(k,:,:)); %grab the data from one region and reshape it
                    Amovie2 = squeeze(Aavg(l,:,:));
                    Bmovie1 = squeeze(Bavg(k,:,:)); %grab the data from one region and reshape it
                    Bmovie2 = squeeze(Bavg(l,:,:));

                    Amovie1m = squeeze(mean(Aavg(k,:,:),3,'omitnan')); %average over trials
                    Amovie2m = squeeze(mean(Aavg(l,:,:),3,'omitnan'));
                    Bmovie1m = squeeze(mean(Bavg(k,:,:),3,'omitnan'));
                    Bmovie2m = squeeze(mean(Bavg(l,:,:),3,'omitnan'));

                    Amovie1 = reshape(Amovie1 - repmat(Amovie1m',[1 ntrials]),1,[]); %mean subtract
                    Amovie2 = reshape(Amovie2 - repmat(Amovie2m',[1 ntrials]),1,[]);
                    Bmovie1 = reshape(Bmovie1 - repmat(Bmovie1m',[1 ntrials]),1,[]);
                    Bmovie2 = reshape(Bmovie2 - repmat(Bmovie2m',[1 ntrials]),1,[]);

                    Acorr = corrcoef(Amovie1, Amovie2,'rows','pairwise');
                    Bcorr = corrcoef(Bmovie1,Bmovie2,'rows','pairwise');
                    A(k,l) = Acorr(1,2);
                    B(k,l) = Bcorr(1,2);
                else
                    error('please input a method for correlation');
                end
            end
        end

        nt = num2str(size(Aavg,3));
        diff = A - B;
        load('C:\Data\churchland\ridgeModel\allenDorsalMapSM.mat');
        labs = dorsalMaps.labelsSplit(areaindices);
        figure;imagesc(A,[cmin cmax]); title(['Engaged ' animals{i} ' ' sessiondates{i}{j} ': ' nt ' trials per state']); colorbar;
        colormap(gcf,'inferno');xticks(areaindices);xticklabels(labs);yticks(areaindices);yticklabels(labs);
        figure;imagesc(B,[cmin cmax]); title(['Biased ' animals{i} ' ' sessiondates{i}{j} ': ' nt ' trials per state']); colorbar;
        colormap(gcf,'inferno');xticks(areaindices);xticklabels(labs);yticks(areaindices);yticklabels(labs);
        figure;imagesc(diff,[cmin2 cmax2]); title(['Difference ' animals{i} ' ' sessiondates{i}{j} ': ' nt ' trials per state']); colorbar;
        colormap(gcf,'colormap_blueblackred');xticks(areaindices);xticklabels(labs);yticks(areaindices);yticklabels(labs);
        clear dorsalMaps

        Aall(:,:,count) = A;
        Ball(:,:,count) = B;
        diffall(:,:,count) = A - B;
        count = count+1;

    end
end

Amean = mean(Aall,3,'omitnan');
Bmean = mean(Ball,3,'omitnan');
diffmean = mean(diffall,3,'omitnan');

figure;imagesc(Amean,[cmin cmax]); title('Engaged avg'); colorbar;
colormap(gcf,'inferno');xticks(areaindices);xticklabels(labs);yticks(areaindices);yticklabels(labs);
figure;imagesc(Bmean,[cmin cmax]); title('Disengaged avg'); colorbar;
colormap(gcf,'inferno');xticks(areaindices);xticklabels(labs);yticks(areaindices);yticklabels(labs);
figure;imagesc(diffmean,[cmin2 cmax2]); title('Engaged minus disengaged avg'); colorbar;
colormap(gcf,'colormap_blueblackred');xticks(areaindices);xticklabels(labs);yticks(areaindices);yticklabels(labs);
figure;imagesc(Amean-Bmean,[cmin2 cmax2]); title('Engaged minus disengaged avg'); colorbar;
colormap(gcf,'colormap_blueblackred');xticks(areaindices);xticklabels(labs);yticks(areaindices);yticklabels(labs);


