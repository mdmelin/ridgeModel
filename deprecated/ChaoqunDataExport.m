clc;clear all;close all

cPath = 'X:/Widefield'; % change this to server path
Animal = 'mSM66';
Rec = '18-Jul-2018';
inds = 1:900; %these are the trial indices to grab. I just set it to 1:900 so that it grabs every trial from the session.
alignedframes = align_frames(cPath,Animal,Rec,inds);

addpath('C:\Data\churchland\ridgeModel\rateDisc');

[alVc,~] = align2behavior(cPath,Animal,Rec,inds); %pass trialinds based on the sessiondata file, this function will work out the imaging data
