% This code is for viewing Rsquared over the desired window of
% frames. Takes the rsquared movie and allows for
% reconstructon and export

clear all;
load('C:\Data\churchland\ridgeModel\widefield\allenDorsalMapSM.mat','dorsalMaps'); %Get allen atlas
%% Variabes

mouse = 'mSM63';
rec = '09-Jul-2018';
frames = [];
clims = [-.08 -.03]; %colorbar lims
plottitle = [mouse ' ' rec ': ' 'state only model cvR^2'];

%%
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];
load([datapath 'stateonly_crossval.mat']);
load([datapath 'rsVc.mat']); %to get spatial components
load([datapath 'opts3.mat']); %to get spatial components

mask = squeeze(isnan(U(:,:,1)));
allenMask = dorsalMaps.allenMask;

twodmat = arrayShrink(stateMovie, mask,'split'); %recreate full frame by restoring 2D from 1D and mask
meanCVR = nanmean(twodmat,3);

alignedmat = alignAllenTransIm(meanCVR,opts3.transParams); %align to allen atlas
alignedmat = alignedmat(:, 1:size(allenMask,2),:);
edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map
alignedmat(edgemap == 1) = NaN; %apply allen edge map
alignedmat(allenMask == 1) = NaN; %apply allen mask
%% plotting
mapImg = imshow(alignedmat, clims);
colormap(mapImg.Parent,'inferno'); axis image; title(plottitle);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

