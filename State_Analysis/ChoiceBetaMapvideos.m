addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
clc;clear all;close all;
%% get sessions for mice - parallel
cPath = 'X:\Widefield';animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'alldisc.mat';
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; cPath = 'Y:\Widefield';%CSP32 missing transparams
modality = 'Choice';

sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %delete this
%% train the models
tic
c = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        [~, acc{c}, betas{c}, Vc] = logisticModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,10,'Attentive',modality,false,true); %train the model
        c = c + 1;
    end
end
c = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        [~, accB{c}, betasB{c}, VcB] = logisticModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,10,'Bias',modality,false,true); %train the model
        c = c + 1;
    end
end
toc

%% plot accuracy
count = 1;
clear beta accuracy accuracyB
for i = 1:length(acc)
    if ~isempty(acc{i})
        accuracy(count,:) = acc{i};
        betaA(:,:,:,count) = betas{i}; %betas are [xpix,ypix,frames,animals]
        count = count + 1;
    end
end

count = 1;
for i = 1:length(accB)
    if ~isempty(accB{i})
        accuracyB(count,:) = accB{i};
        betaB(:,:,:,count) = betasB{i};
        count = count + 1;
    end
end

segframes = Vc.segFrames;
segframes = [1 segframes];
cols = {'r','b','g'};

figure
stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
stdshade(accuracyB,.2,cols{2},[],6,[1],[]); %plot average accuracyxline(segframes);

ylim([.4 1]);
yline(.5);
title([modality ' decoder accuracy']);
legend('',[modality ' engaged'],'',[modality ' disengaged']);
%% plot beta videos
clims = [-.001 .001];
%clims = [-.0007 .0007]; trialperiod = 4;
fsize = 9;
framerate = 30;
savepath = 'C:\Data\churchland\ridgeModel\beta';
trialmeanA = mean(betaA,4,'omitnan'); %average over trials
trialmeanB = mean(betaB,4,'omitnan'); %average over trials

v = VideoWriter(savepath);
v.FrameRate = framerate; open(v);
for i = 1:size(trialmeanA,3)
    figure('units','normalized','outerposition',[0 0 1 1])
    subplot(1,3,1);
    plotHeatmap(trialmeanA(:,:,i), clims,[modality ' decode - engaged'],'Beta weight',[], fsize);
    text(15,15,0,['i = ' num2str(i)],'Color','red','FontSize',15);
    subplot(1,3,2)
    plotHeatmap(trialmeanB(:,:,i), clims,[modality ' decode - disengaged'],'Beta weight',[], fsize);
    subplot(1,3,3);
    plotHeatmap(trialmeanA(:,:,i) - trialmeanB(:,:,i), clims,[modality ' decode - delta'],'Beta weight',[], fsize);
    frame = getframe(gcf);
    writeVideo(v,frame);
    close(gcf)
end

v.close