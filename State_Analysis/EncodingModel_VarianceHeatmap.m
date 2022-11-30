clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; %CSP32 missing transparams


method = 'cutoff';
mintrialnum = 20; %the minimum number of trials per state to be included in plotting
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

%% rerun encoding model - general variable groups , show variance over time
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        animals{i}
        sessiondates{i}{j}
        ridgeModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,"attentive",[], false);
        ridgeModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,"biased", [], false);
    end
end

%%
counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fulla(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_fullmodel.mat');
        sponta(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlyspontmotor.mat');
        opa(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlyopmotor.mat');
        taskvara(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlytaskvars.mat');
        nosponta(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_nospontmotor.mat');
        noopa(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_noopmotor.mat');
        notaskvara(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_notaskvars.mat');

        fullb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_fullmodel.mat');
        spontb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlyspontmotor.mat');
        opb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlyopmotor.mat');
        taskvarb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlytaskvars.mat');
        nospontb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_nospontmotor.mat');
        noopb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_noopmotor.mat');
        notaskvarb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_notaskvars.mat');

        counter = counter + 1;
        fprintf('\ncounter is %i\n',counter);
    end
end

dsponta = fulla-nosponta;
dspontb = fullb-nospontb;
dtaska = fulla-notaskvara;
dtaskb = fullb-notaskvarb;
dopa = fulla-noopa;
dopb = fullb-noopb;

%% plotting full model
clims = [0 .8];
clims2 = [-.2 .2];

time = linspace(0,5,size(fulla,2));
time = time-time(30);

figure;
subplot(1,3,1); hold on;
title('Engaged');
mapImg = imshow(squeeze(mean(fulla,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'inferno'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,2); hold on;
title('Disengaged');
mapImg = imshow(squeeze(mean(fullb,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'inferno'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,3)

mapImg = imshow(squeeze(mean(fulla,[1 4],'omitnan')) - squeeze(mean(fullb,[1 4],'omitnan')), clims2);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
title('Difference');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

%% op motors
clims = [0 .8];
clims2 = [-.2 .2];

figure;
subplot(1,3,1); hold on;
mapImg = imshow(squeeze(mean(opa,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'inferno'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
title('Engaged');
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,2); hold on;
mapImg = imshow(squeeze(mean(opb,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'inferno'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
title('Disengaged');
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,3)
mapImg = imshow(squeeze(mean(opa,[1 4],'omitnan')) - squeeze(mean(opb,[1 4],'omitnan')), clims2);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
title('Difference');
hcb = colorbar;
hcb.Title.String = 'cvR^2';

%% task vars

clims = [0 .3];
clims2 = [-.2 .2];

figure;
subplot(1,3,1); hold on;
mapImg = imshow(squeeze(mean(taskvara,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'inferno'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
title('Engaged');
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,2); hold on;
mapImg = imshow(squeeze(mean(taskvarb,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'inferno'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
title('Disengaged');
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,3)
mapImg = imshow(squeeze(mean(taskvara,[1 4],'omitnan')) - squeeze(mean(taskvarb,[1 4],'omitnan')), clims2);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
title('Difference');
hcb = colorbar;
hcb.Title.String = 'cvR^2';

%% uninstructed

clims = [0 .8];
clims2 = [-.2 .2];

figure;
subplot(1,3,1); hold on;
mapImg = imshow(squeeze(mean(sponta,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'inferno'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
title('Engaged');
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,2); hold on;
mapImg = imshow(squeeze(mean(spontb,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'inferno'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
title('Disengaged');
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,3)
mapImg = imshow(squeeze(mean(sponta,[1 4],'omitnan')) - squeeze(mean(spontb,[1 4],'omitnan')), clims2);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
title('Difference');
hcb = colorbar;
hcb.Title.String = 'cvR^2';

