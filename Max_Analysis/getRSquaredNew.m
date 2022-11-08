function out = getRSquaredNew(mouse,rec,modelfile)
load('C:\Data\churchland\ridgeModel\widefield\allenDorsalMapSM.mat','dorsalMaps'); %Get allen atlas
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallstuff');

%%
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];

try
    load([datapath modelfile]);
catch
    fprintf('\nThe encoding model file does not exist!');
    out = NaN;
return
end

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


%%
mask = squeeze(isnan(U(:,:,1)));
allenMask = dorsalMaps.allenMask;

shrunkMap = arrayShrink(double(fullMap), mask,'split'); %recreate full frame by restoring 2D from 1D and mask
alignedmat = alignAllenTransIm(double(shrunkMap),opts3.transParams); %align to allen atlas
alignedmat = alignedmat(:, 1:size(allenMask,2),:);
edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map
alignedmat(edgemap == 1) = NaN; %apply allen edge map
alignedmat(allenMask == 1) = NaN; %apply allen mask

out = alignedmat;
out = nanmean(out(:));


end