function [out] = plotRSquared(mouse,rec,modelfile,cmap,clims,suppress)
load('C:\Data\churchland\ridgeModel\widefield\allenDorsalMapSM.mat','dorsalMaps'); %Get allen atlas
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallstuff');

%%
if length(modelfile) > 1 && ~ischar(modelfile)
    calcDelta = true;
else
    calcDelta = false;
end
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];

try
    load([datapath 'rsVc.mat']); %to get spatial components
catch
    load([datapath 'Vc.mat']); %to get spatial components
end

try
    load([datapath 'opts3.mat']); %to get alignment opts
catch
    try
        load([datapath 'opts2.mat']); %to get alignment opts
        opts3 = opts;
    catch
        load([datapath 'opts.mat']); %to get alignment opts
        opts3 = opts;
    end
end

mask = squeeze(isnan(U(:,:,1)));
allenMask = dorsalMaps.allenMask;

if calcDelta %if calculating deltaRsquared
    load([datapath modelfile{1}]);
    rsquared = arrayShrink(double(fullMap).^2, mask,'split'); %recreate full frame by restoring 2D from 1D and mask
    alignedmat1 = alignAllenTransIm(double(rsquared),opts3.transParams); %align to allen atlas
    alignedmat1 = alignedmat1(:, 1:size(allenMask,2),:);
    edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat1,1),:); %allen edge map
    alignedmat1(edgemap == 1) = NaN; %apply allen edge map
    alignedmat1(allenMask == 1) = NaN; %apply allen mask

    load([datapath modelfile{2}]);
    rsquared = arrayShrink(double(fullMap).^2, mask,'split'); %recreate full frame by restoring 2D from 1D and mask
    alignedmat2 = alignAllenTransIm(double(rsquared),opts3.transParams); %align to allen atlas
    alignedmat2 = alignedmat2(:, 1:size(allenMask,2),:);
    edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat2,1),:); %allen edge map
    alignedmat2(edgemap == 1) = NaN; %apply allen edge map
    alignedmat2(allenMask == 1) = NaN; %apply allen mask

    alignedmat = alignedmat1 - alignedmat2;
else % if not calculating deltaRsquared
    try
    load([datapath modelfile]);
    catch
        fprintf('\nThe encoding model file does not exist!');
        out = NaN;
        return
    end
    rsquared = arrayShrink(double(fullMap).^2, mask,'split'); %recreate full frame by restoring 2D from 1D and mask
    alignedmat = alignAllenTransIm(double(rsquared),opts3.transParams); %align to allen atlas
    alignedmat = alignedmat(:, 1:size(allenMask,2),:);
    edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map
    alignedmat(edgemap == 1) = NaN; %apply allen edge map
    alignedmat(allenMask == 1) = NaN; %apply allen mask
end

modelfile = strrep(modelfile,'_','\_'); %need to escape underscore when plotting

if calcDelta
    plottitle = [mouse ' ' rec ': ' modelfile{1} ' MINUS ' modelfile{2} ' ... ' 'deltaR^2'];
else
    plottitle = [mouse ' ' rec ': ' sprintf('%s',modelfile) ' ... ' 'cvR^2'];
end

if suppress
    out = alignedmat;
    return
end

if isempty(cmap)
    cmap = 'inferno'
end

%% plotting
%figure('units','normalized','outerposition',[0 0 1 1])
figure;
title([mouse ' ' rec]);
mapImg = imshow(alignedmat, clims);
colormap(mapImg.Parent,cmap); axis image; title(plottitle);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

% subplot(1,length(frames)+2,i+2);
% mapImg = imshow(toby, clims);
% colormap(mapImg.Parent,'inferno'); axis image; title('cMap');
% set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
% hcb = colorbar;
% hcb.Title.String = 'cvR^2';

out = alignedmat;
drawnow;
end