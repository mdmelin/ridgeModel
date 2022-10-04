
clc;clear all;close all
cPath = 'X:\Widefield';
Animal = 'mSM63';
Recs = {'16-Jul-2018','17-Jul-2018','18-Jul-2018','19-Jul-2018','20-Jul-2018'};
glmFile = 'allaudio.mat';
%% look cortex wide, over left and right stimulus
clims = [-3,3];

for i = 1:length(Recs) %try a few different sessions
    Rec = Recs{i};
    [inds{1},inds{2}] = getStimInds(cPath,Animal,Rec);
    plotActivationMap(cPath,Animal,Rec,inds,['Simulus ' Rec],{'Left trials','Right trials'},clims);
end


%% look cortex-wide, averaging over different trial periods, Lets start with left/right choice PSTH
% It seems like we can see some right M2 activation compared to left choice vs right
% Need to average over mice and trials and run stats to be sure
clims = [-3,3];

for i = 1:length(Recs) %try a few different sessions
    Rec = Recs{i};
    [inds{1},inds{2}] = getChoiceInds(cPath,Animal,Rec);
    plotActivationMap(cPath,Animal,Rec,inds,['Choice ' Rec],{'Left trials','Right trials'},clims);
end

%% now get region specific
%%%%%%%%%%%%%%%%%%%%%%%%
%todo: figure out equalizations,ONLY USE TRIALS WITH A CHOICE (maybe this will fix the imaging truncation problem),fix response
%period problem. ALSO calculate a p value for EVERY pixel in each window.
%Maybe change back plotActivationMap zscoring.
%%%%%%%%%%%%%%%%%%%%%%%%

figureleg = cell(1,14);
figureleg(1,:) = {''};
figureleg{5} = 'Left choice';
figureleg{10} = 'Right choice';

for i = 1:length(Recs)
    Rec = Recs{i};
    [inds{1},inds{2}] = getChoiceInds(cPath,Animal,Rec);
    plotRegionPSTH(cPath,Animal,Rec,inds,4,'Right M1',figureleg); %left M2
    plotRegionPSTH(cPath,Animal,Rec,inds,6,'Right M2',figureleg); %left M2
end

%% Now move on to state
clims = [-3,3];

for i = 1:length(Recs) %try a few different sessions
    Rec = Recs{i};
    [attentiveinds,biasinds] = getStateInds(cPath,Animal,Rec,glmFile);
    attentiveinds = attentiveinds(randperm(length(attentiveinds),length(biasinds))); %grab equal number of attentive trials as bias trials that exist
    inds{1} = attentiveinds;
    inds{2} = biasinds;
    plotActivationMap(cPath,Animal,Rec,inds,['State ' Rec],{'Attentive trials','Bias trials'},clims);
end
%% lets look at M2 trial aligned PSTH's

figureleg = cell(1,14);
figureleg(1,:) = {''};
figureleg{5} = 'Attentive state trials';
figureleg{10} = 'Bias state trials';

for i = 1:length(Recs)
    Rec = Recs{i};
    [~,attentiveinds,biasinds] = getStateInds(cPath,Animal,Rec,glmFile);
    attentiveinds = attentiveinds(randperm(length(attentiveinds),length(biasinds))); %grab equal number of attentive trials as bias trials that exist
    inds{1} = attentiveinds;
    inds{2} = biasinds;
    plotRegionPSTH(cPath,Animal,Rec,inds,4,'Right M1',figureleg); %left M2
    plotRegionPSTH(cPath,Animal,Rec,inds,6,'Right M2',figureleg); %left M2
end
%% Functions





%the following function gets our GLM output and adds NaNs to trials without choices
%for proper alignment (the GLM doesn't have output for trials without
%choice).
function [inds, attendinds,biasinds] = getStateInds(cPath,Animal,Rec,glmFile)
Paradigm = 'SpatialDisc';
glmfile = [cPath filesep Animal filesep 'glm_hmm_models' filesep glmFile]; %Widefield data path

cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
load(glmfile,'posterior_probs','model_training_sessions','state_label_indices'); %load behavior data
model_training_sessions = num2cell(model_training_sessions,2); %convert to a cell for ease

sessionind = find(strcmp(model_training_sessions,Rec));%find the index of the session we want to pull latent states for
postprob_nonan = posterior_probs{sessionind}; %grab the proper session
nochoice = isnan(bhv.ResponseSide); %trials without choice. used for interpolation of latent state on NaN choice trials (GLMHMM doesn't predict for these trials)
counterind = 1;

for i = 1:length(nochoice) %this for loop adds nan's to the latent state array. The nans will ultimatel get discarded later since the encoding model doesn't use trials without choice.
    if ~nochoice(i) %if a choice was made
        postprob_withnan(i,:) = postprob_nonan(counterind,:); %just put the probabilities into the new array
        counterind = counterind + 1;
    else %if no choice was made
        postprob_withnan(i,:) = NaN; %insert a NaN to new array
    end
end
postprobs = postprob_withnan';
stateinds = str2num(state_label_indices); %stateinds tells us what dimension has what state, the first index of stateinds tells us the index of attentive state

postprobs_sorted = postprobs(stateinds,:); %permute the states so theyre in the correct indices


[~,state1hot] = max(postprobs_sorted,[],1);

useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
inds = find(rateDisc_equalizeTrials(useIdx, state1hot == 1, bhv.ResponseSide == 1, inf, true)); %equalize state and L/R choices
attendinds = inds(state1hot(inds) == 1);
biasinds = inds(state1hot(inds) ~= 1);
end


%the following function gets left and right choices, equal numbers,
%counterbalances correct and incorrect as well
function [leftinds,rightinds] = getChoiceInds(cPath,Animal,Rec)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
Paradigm = 'SpatialDisc';
cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
%equalize L/R choices
useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
equalinds = find(rateDisc_equalizeTrials(useIdx, bhv.ResponseSide == 1, bhv.Rewarded, inf, true)); %equalize correct L/R choices and balance correct/incorrects.

leftinds = equalinds(bhv.ResponseSide(equalinds) == 1);
rightinds = equalinds(bhv.ResponseSide(equalinds) == 2);
end

%the following function gets left and right stimulus, equal numbers,
%counterbalances correct and incorrect as well
function [leftinds,rightinds] = getStimInds(cPath,Animal,Rec)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
Paradigm = 'SpatialDisc';
cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
%equalize L/R choices
useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
equalinds = find(rateDisc_equalizeTrials(useIdx, bhv.CorrectSide == 1, bhv.Rewarded, inf, true)); %equalize correct L/R choices and balance correct/incorrects.

leftinds = equalinds(bhv.CorrectSide(equalinds) == 1);
rightinds = equalinds(bhv.CorrectSide(equalinds) == 2);
end


