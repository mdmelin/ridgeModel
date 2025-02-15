addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
clc;clear all;close all;
%% get sessions for mice - parallel
cPath = 'X:\Widefield';animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
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
clear beta accuracy accuracyB betaA betaB
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

cols = {'r','b','g'};
time = (0:1:size(accuracy,2)-1) ./ 30; %IMPORTANT, FS IS 15 FOR CSTR MICE
figure
stdshade(accuracy,.2,cols{1},time,6,segframes,[]); %plot average accuracy
stdshade(accuracyB,.2,cols{2},time,6,segframes,[]); %plot average accuracyxline(segframes);

ylim([.4 1]);
yline(.5);
ylabel('Cross Validated Accuracy')
set(gca,'TickDir','out')
ylabel('Accuracy');
xlabel('Time (s)');
title([modality ' decoder accuracy']);
legend('','','','','','Engaged trials','','','','','','Disengaged trials');
%% plot betas
segframes = Vc.segFrames;
segframes = [1 segframes]
mycmap = load('CustomColormap2.mat');
mycmap = mycmap.CustomColormap2;

%clims = [-.001 .001]; trialperiod = 5; % plot from one trial epoch
clims = [-.0007 .0007]; trialperiod = 4;
fsize = 9;

avginds = segframes(trialperiod):segframes(trialperiod+1);
subbetaA = betaA(:,:,avginds,:);
subbetaB = betaB(:,:,avginds,:);

trialmeanA = mean(subbetaA,4,'omitnan'); %average over trials
finalmeanA = mean(trialmeanA,3,'omitnan'); %average over time
trialmeanB = mean(subbetaB,4,'omitnan'); %average over trials
finalmeanB = mean(trialmeanB,3,'omitnan'); %average over time

figure;
subplot(1,3,1);
plotHeatmap(finalmeanA, clims,['Engaged trials'],'Beta weight',[], fsize);
subplot(1,3,2)
plotHeatmap(finalmeanB, clims,['Disengaged trials'],'Beta weight',[], fsize);
subplot(1,3,3);
plotHeatmap(finalmeanA - finalmeanB, clims,['Difference'],'Beta weight',mycmap, fsize);

