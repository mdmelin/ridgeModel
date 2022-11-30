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
clear lfirstauda lfirstaudb
counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fullMEa(counter,:,:,:) = getBetas(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_fullmodel.mat',{'Move'},[]);
        lfirstauda(counter,:,:,:) = getBetas(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_fullmodel.mat',{'lfirstAudStim'},1:10);
%         opa(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlyopmotor.mat');
%         taskvara(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlytaskvars.mat');
%         nosponta(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_nospontmotor.mat');
%         noopa(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_noopmotor.mat');
%         notaskvara(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_notaskvars.mat');

        fullMEb(counter,:,:,:) = getBetas(animals{i},sessiondates{i}{j},'biased_allaudio_detection_fullmodel.mat',{'Move'},[]);
        lfirstaudb(counter,:,:,:) = getBetas(animals{i},sessiondates{i}{j},'biased_allaudio_detection_fullmodel.mat',{'lfirstAudStim'},1:10);
%         opb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlyopmotor.mat');
%         taskvarb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlytaskvars.mat');
%         nospontb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_nospontmotor.mat');
%         noopb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_noopmotor.mat');
%         notaskvarb(counter,:,:,:) = getRSquaredOverTime(animals{i},sessiondates{i}{j},'biased_allaudio_detection_notaskvars.mat');

        counter = counter + 1;
        fprintf('\ncounter is %i\n',counter);
    end
end

% dsponta = fulla-nosponta;
% dspontb = fullb-nospontb;
% dtaska = fulla-notaskvara;
% dtaskb = fullb-notaskvarb;
% dopa = fulla-noopa;
% dopb = fullb-noopb;
%%
clims = [-.001 .001];
figure
mapImg = imshow(squeeze(mean(fullMEa,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
title('Engaged');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

figure
mapImg = imshow(squeeze(mean(fullMEb,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
title('Disengaged');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

%%

clims = [-.001 .001];
figure
mapImg = imshow(squeeze(mean(lfirstauda,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
title('Engaged');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

figure
mapImg = imshow(squeeze(mean(lfirstaudb,[1 4],'omitnan')), clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
title('Disengaged');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';