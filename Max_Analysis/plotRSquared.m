function [out,meanout] = plotRSquared(mouse,rec,modelfile,frames,clims)
load('C:\Data\churchland\ridgeModel\widefield\allenDorsalMapSM.mat','dorsalMaps'); %Get allen atlas
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallstuff');

%%
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];
load([datapath modelfile]);
load([datapath 'rsVc.mat']); %to get spatial components
load([datapath 'opts3.mat']); %to get alignment opts

modelfile = strrep(modelfile,'_','\_'); %need to escape underscore when plotting
plottitle = [mouse ' ' rec ': ' sprintf('%s',modelfile) ' ... ' 'cvR^2'];

%%
mask = squeeze(isnan(U(:,:,1)));
allenMask = dorsalMaps.allenMask;
rsquared = arrayShrink(double(fullMovie).^2, mask,'split'); %recreate full frame by restoring 2D from 1D and mask


for i = 1:length(frames) %iterate thru trial periods
    trialperiodRsquared(:,:,i) = nanmean(double(rsquared(:,:,frames{i})),3);
    alignedmat = alignAllenTransIm(trialperiodRsquared(:,:,i),opts3.transParams); %align to allen atlas
    alignedmat = alignedmat(:, 1:size(allenMask,2),:);
    edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map
    alignedmat(edgemap == 1) = NaN; %apply allen edge map
    alignedmat(allenMask == 1) = NaN; %apply allen mask
    
    out(:,:,i) = alignedmat;
end

wholetrialmean = nanmean(double(rsquared),3);
alignedmat = alignAllenTransIm(wholetrialmean,opts3.transParams); %align to allen atlas
alignedmat = alignedmat(:, 1:size(allenMask,2),:);
edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map
alignedmat(edgemap == 1) = NaN; %apply allen edge map
alignedmat(allenMask == 1) = NaN; %apply allen mask

meanout = alignedmat; clear alignedmat;

shrunkMap = arrayShrink(double(fullMap).^2, mask,'split'); %recreate full frame by restoring 2D from 1D and mask
alignedmat = alignAllenTransIm(double(shrunkMap),opts3.transParams); %align to allen atlas
alignedmat = alignedmat(:, 1:size(allenMask,2),:);
edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map
alignedmat(edgemap == 1) = NaN; %apply allen edge map
alignedmat(allenMask == 1) = NaN; %apply allen mask

toby = alignedmat;

%% plotting
figure('units','normalized','outerposition',[0 0 1 1])
sgtitle(plottitle);
for i = 1:length(frames)
    subplot(1,length(frames)+1,i);
    mapImg = imshow(out(:,:,i), clims);
    colormap(mapImg.Parent,'inferno'); axis image; title(sprintf('Frame %i to %i',frames{i}(1),frames{i}(end)));
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'cVR^2';
end

subplot(1,length(frames)+1,i+1);
mapImg = imshow(meanout, clims);
colormap(mapImg.Parent,'inferno'); axis image; title('Whole Trial');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,length(frames)+2,i+2);
mapImg = imshow(toby, clims);
colormap(mapImg.Parent,'inferno'); axis image; title('cMap');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

drawnow;
end