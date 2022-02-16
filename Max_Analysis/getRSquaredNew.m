function out = getRSquaredNew(mouse,rec,modelfile)
load('C:\Data\churchland\ridgeModel\widefield\allenDorsalMapSM.mat','dorsalMaps'); %Get allen atlas
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallstuff');

%%
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];
load([datapath modelfile]);
load([datapath 'rsVc.mat']); %to get spatial components
load([datapath 'opts3.mat']); %to get alignment opts


%%
mask = squeeze(isnan(U(:,:,1)));
allenMask = dorsalMaps.allenMask;

shrunkMap = arrayShrink(double(fullMap).^2, mask,'split'); %recreate full frame by restoring 2D from 1D and mask
alignedmat = alignAllenTransIm(double(shrunkMap),opts3.transParams); %align to allen atlas
alignedmat = alignedmat(:, 1:size(allenMask,2),:);
edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map
alignedmat(edgemap == 1) = NaN; %apply allen edge map
alignedmat(allenMask == 1) = NaN; %apply allen mask

out = alignedmat;
out = nanmean(out(:));


end