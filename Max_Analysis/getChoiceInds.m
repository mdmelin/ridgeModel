function [equalinds,leftinds,rightinds] = getChoiceInds(cPath,Animal,Rec)
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