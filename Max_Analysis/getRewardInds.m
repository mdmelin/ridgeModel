function [equalinds,leftinds,rightinds] = getRewardInds(cPath,Animal,Rec)
addpath('C:\Data\churchland\ridgeModel\rateDisc');
Paradigm = 'SpatialDisc';
cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
%equalize rewarded and nonrewarded
useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
equalinds = find(rateDisc_equalizeTrials(useIdx, bhv.Rewarded, bhv.ResponseSide == 1, inf, true)); %equalize correct L/R choices and balance correct/incorrects.

leftinds = equalinds(bhv.Rewarded(equalinds) == 1); %rewarded trials
rightinds = equalinds(bhv.Rewarded(equalinds) == 0); %nonrewarded trials
end