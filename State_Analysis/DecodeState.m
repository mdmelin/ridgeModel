addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
addpath('C:\Data\churchland\ridgeModel\smallStuff');
clc;clear all;close all;
%% get sessions for mice - parallel
cPath = 'X:\Widefield';
animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'alldisc.mat';
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; cPath = 'Y:\Widefield';%CSP32 missing transparams
modality = 'State';

sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %delete this

%% Decode desired modality - train the models
tic
c = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        [~, acc{i}{j}, betas{i}{j}, Vc] = logisticModel(cPath,animals{i},sessiondates{i}{j},glmFile,50,10,modality,false,true); %train the model
        [~, acc_shuff{i}{j}, ~, ~] = logisticModel(cPath,animals{i},sessiondates{i}{j},glmFile,50,10,modality,true,true); %train the shuffled model
        c = c + 1;
        if ~isempty(Vc)
            Vcsave = Vc;
        end
    end
end
c = 1;
toc

%% plot 
load('C:\Data\churchland\ridgeModel\segFrames.mat');
cols = {'r','b','g'};
for i = 1:length(animals) %plot individual animals
    count = 1; clear betas_out
    for j = 1:length(sessiondates{i}) % remove empty data here for better averaging
        if ~isempty(acc{i}{j})
            accuracy(count,:) = acc{i}{j};
            accuracyshuff(count,:) = acc_shuff{i}{j};
            betas_out(:,:,:,count) = betas{i}{j}; %betas are [xpix,ypix,frames,animals]
            count = count + 1;
        end
    end

    % plot data for each mouse here over training
    trialperiod = 5 % plot from one trial epoch
    clims = [-.001 .001];

    segframes = Vcsave(1).segFrames;
    segframes = [1 segframes];

    figure
    stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
    stdshade(accuracyshuff,.2,cols{2},[],6,[1],[]); %plot average accuracy

    xline(segframes);
    ylim([.4 1]);
    yline(.5);
    title([modality ' decoder accuracy']);
    legend('',[modality ' decode'],'',[modality ' shuffled']);


    avginds = segframes(trialperiod):segframes(trialperiod+1);
    betas_out = betas_out(:,:,avginds,:);
    trialmean = mean(betas_out,4,'omitnan'); %average over trials
    finalmean = mean(trialmean,3,'omitnan'); %average over time

    figure;
    plotHeatmap(finalmean, clims,[modality ' decode'],'Beta weight',[],24);

end
%% Plotting, but averaged over all sessions
cols = {'r','b','g'};

count = 1; clear betas_out
for i = 1:length(animals) 
    for j = 1:length(sessiondates{i}) % remove empty data here for better averaging
        if ~isempty(acc{i}{j})
            accuracy(count,:) = acc{i}{j};
            accuracyshuff(count,:) = acc_shuff{i}{j};
            betas_out(:,:,:,count) = betas{i}{j}; %betas are [xpix,ypix,frames,animals]
            count = count + 1;
        end
    end
end

segframes = Vcsave(1).segFrames;

figure
stdshade(accuracy,.2,cols{1},[],6,segframes,[]); %plot average accuracy
stdshade(accuracyshuff,.2,cols{2},[],6,segframes,[]); %plot average accuracy

xline(segframes);
ylim([.4 1]);
yline(.5);
title([modality ' decoder accuracy']);
legend('','','','','','Accuracy','','','','','','Shuffled');

segframes = [1 segframes];

clims = [-.001 .001]; trialperiod = 5 % plot from response
%clims = [-.0007 .0007]; trialperiod = 4 % plot from delay
%clims = [-.0007 .0007]; trialperiod = 2 % plot from initiation

avginds = segframes(trialperiod):segframes(trialperiod+1);
betas_out = betas_out(:,:,avginds,:);
trialmean = mean(betas_out,4,'omitnan'); %average over trials
finalmean = mean(trialmean,3,'omitnan'); %average over time

figure;
plotHeatmap(finalmean, clims,[modality ' decode'],'Beta weight',[],24);



