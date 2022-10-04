% look at how design matrix collinearities shift with state

clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions
cPath = 'X:\Widefield';
animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'allaudio_detection.mat'; %32 not working for some reason
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; %CSP32 missing transparams

sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

cmin = 0; cmax = .2;
cmin2 = -.1; cmax2 = .1;
%%
counter = 1
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        [Alabels,Aidx,Ra] = ridgeModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,"attentive",[],true);
        [Blabels,Bidx,Rb] = ridgeModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,"biased",[],true);

        if isempty(Ra) || isempty(Rb)
            continue
        else
            counter = counter+1;
            templabels = Alabels;
        end

        Acorr = corrcoef(Ra);
        Bcorr = corrcoef(Rb);

        for k = 1:length(Alabels)
            for l = 1:length(Alabels)
                grab = Acorr(find(Aidx==k),find(Aidx==l));
                Acorrsmall(k,l) = mean(grab,'all','omitnan');
            end
        end

        for k = 1:length(Blabels)
            for l = 1:length(Blabels)
                grab = Bcorr(find(Bidx==k),find(Bidx==l));
                Bcorrsmall(k,l) = mean(grab,'all','omitnan');
            end
        end
        figure;
        subplot(1,3,1)
        nt = num2str(size(Ra,1)/75); %hard code for trial length
        imagesc(Acorrsmall,[cmin cmax]); title(['Engaged ' animals{i} ' ' sessiondates{i}{j} ': ' nt ' trials']); colorbar;
        colormap(gcf,'inferno');xticks(1:1:length(Alabels));xticklabels(Alabels);yticks(1:1:length(Alabels));yticklabels(Alabels);

        subplot(1,3,2)
        nt = num2str(size(Rb,1)/75); %hard code for trial length
        imagesc(Bcorrsmall,[cmin cmax]); title(['Disengaged ' animals{i} ' ' sessiondates{i}{j} ': ' nt ' trials']); colorbar;
        colormap(gcf,'inferno');xticks(1:1:length(Blabels));xticklabels(Blabels);yticks(1:1:length(Blabels));yticklabels(Blabels);

        subplot(1,3,3)
        imagesc(Acorrsmall - Bcorrsmall,[cmin2 cmax2]); title(['Difference ' animals{i} ' ' sessiondates{i}{j} ': ' nt ' trials']); colorbar;
        colormap(gcf,'colormap_blueblackred');xticks(1:1:length(Blabels));xticklabels(Blabels);yticks(1:1:length(Blabels));yticklabels(Blabels);

        A(:,:,counter) = Acorrsmall;
        B(:,:,counter) = Bcorrsmall;
        diff(:,:,counter) = Acorrsmall - Bcorrsmall;
    end
end

A = mean(A,3);
B = mean(B,3);
diff = mean(diff,3);

figure;
subplot(1,3,1)
nt = num2str(size(Ra,1)/75); %hard code for trial length
imagesc(A,[cmin cmax]); title(['Engaged avg']); colorbar;
colormap(gcf,'inferno');xticks(1:1:length(templabels));xticklabels(templabels);yticks(1:1:length(templabels));yticklabels(templabels);

subplot(1,3,2)
nt = num2str(size(Rb,1)/75); %hard code for trial length
imagesc(B,[cmin cmax]); title(['Disengaged avg']); colorbar;
colormap(gcf,'inferno');xticks(1:1:length(templabels));xticklabels(templabels);yticks(1:1:length(templabels));yticklabels(templabels);

subplot(1,3,3)
imagesc(diff,[cmin2 cmax2]); title(['Difference']); colorbar;
colormap(gcf,'colormap_blueblackred');xticks(1:1:length(templabels));xticklabels(templabels);yticks(1:1:length(templabels));yticklabels(templabels);

