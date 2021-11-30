% This code is for viewing average beta weights over the desired window of
% frames. Takes the full beta matrix in SVD space and allows for
% reconstructon and export

% mouse = 'mSM63';
% rec = '09-Jul-2018';
% modelfile = 'orgfullcorr_onlystate.mat'
% myLabel = {'attentive'}; %select desired regressor to plot
% frames = {1:31; ...
%           31:45; ...
%           45:60}; %need to modify these to proper timeperiods in trial
% %c = 2e-3;
% c = 5e-4;
% clims = [-c c]; %colorbar lims

function [out,meanout,betalength] = plotBetas(mouse,rec,modelfile,myLabel,frames,clims)
load('C:\Data\churchland\ridgeModel\widefield\allenDorsalMapSM.mat','dorsalMaps'); %Get allen atlas
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallstuff');

%%
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];
load([datapath modelfile]);
load([datapath 'rsVc.mat']); %to get spatial components
load([datapath 'opts3.mat']); %to get alignment opts

modelfile = strrep(modelfile,'_','\_'); %need to escape underscore when plotting
plottitle = [mouse ' ' rec ': ' sprintf('%s',modelfile) ' ... ' myLabel{1} ' regressor'];

%%

regInd = ismember(regIdx(~rejIdx), find(ismember(fullLabels,myLabel))); %get the indices of desired regressor

for i = 1:length(fullBeta)
    betas = fullBeta{i}(regInd,:); %extract desired betas
end
meanbeta = nanmean(betas,3); %compute mean beta over 10 fold crossval
betareconstructed = svdFrameReconstruct(U, meanbeta'); %recover from SVD space
mask = squeeze(isnan(U(:,:,1)));
allenMask = dorsalMaps.allenMask;
betalength = size(betareconstructed,3);
fprintf('\nThere are %i frames for this regressor',betalength);


for i = 1:length(frames) %iterate thru trial periods
    trialperiodbetas(:,:,i) = nanmean(double(betareconstructed(:,:,frames{i})),3); %MUST CONVERT TO DOUBLE TO MAINTAIN PRECISION
    alignedmat = alignAllenTransIm(trialperiodbetas(:,:,i),opts3.transParams); %align to allen atlas
    alignedmat = alignedmat(:, 1:size(allenMask,2),:);
    edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map
    alignedmat(edgemap == 1) = NaN; %apply allen edge map
    alignedmat(allenMask == 1) = NaN; %apply allen mask
    
    out(:,:,i) = alignedmat;
end

wholetrialmean = nanmean(double(betareconstructed),3);
alignedmat = alignAllenTransIm(wholetrialmean,opts3.transParams); %align to allen atlas
alignedmat = alignedmat(:, 1:size(allenMask,2),:);
edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map
alignedmat(edgemap == 1) = NaN; %apply allen edge map
alignedmat(allenMask == 1) = NaN; %apply allen mask

meanout = alignedmat;
%% plotting
figure('units','normalized','outerposition',[0 0 1 1])
sgtitle(plottitle);
for i = 1:length(frames)
    subplot(1,length(frames)+1,i);
    mapImg = imshow(out(:,:,i), clims);
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title(sprintf('Frame %i to %i',frames{i}(1),frames{i}(end)));
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'Beta';
end

subplot(1,length(frames)+1,i+1);
mapImg = imshow(meanout, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Whole Trial');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Beta';
drawnow;
end

