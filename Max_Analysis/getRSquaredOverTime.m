function out = getRSquaredOverTime(mouse,rec,modelfile)
load('C:\Data\churchland\ridgeModel\allenDorsalMapMM.mat','dorsalMaps'); %Get allen atlas
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
    fprintf('No rsVc file, using Vc instead.')
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

shrunkMap = arrayShrink(double(fullMovie), mask,'split'); %recreate full frame by restoring 2D from 1D and mask
alignedmat = alignAllenTransIm(double(shrunkMap),opts3.transParams); %align to allen atlas
alignedmat = alignedmat(:, 1:size(allenMask,2),:);
edgemap = dorsalMaps.edgeMapScaledMax(1:size(alignedmat,1),:); %allen edge map
for i = 1:size(alignedmat,3)
    oneframe = alignedmat(:,:,i);
    oneframe(edgemap == 1) = NaN; %apply allen edge map
    oneframe(allenMask == 1) = NaN; %apply allen mask
    alignedmat(:,:,i) = oneframe;
end

out = alignedmat;


end