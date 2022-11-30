% This code is for viewing average beta weights over the desired window of
% frames. Takes the full beta matrix in SVD space and allows for
% reconstructon and export


function alignedmat = getBetas(mouse,rec,modelfile,myLabel,subframes)
load('C:\Data\churchland\ridgeModel\widefield\allenDorsalMapSM.mat','dorsalMaps'); %Get allen atlas
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallstuff');


%%
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];

try
    load([datapath modelfile]);
catch
    fprintf('\nThe encoding model file does not exist!');
    alignedmat = NaN;
    return
end


load([datapath 'rsVc.mat']); %to get spatial components


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

modelfile = strrep(modelfile,'_','\_'); %need to escape underscore when plotting
plottitle = [mouse ' ' rec ': ' sprintf('%s',modelfile) ' ... ' myLabel{1} ' regressor'];

%%

%regInd = ismember(regIdx(~rejIdx), find(ismember(fullLabels,myLabel))); %get the indices of desired regressor
regInd = fullLabelInds == find(ismember(fullLabels,myLabel));

for i = 1:length(fullBeta)
    betas(:,:,i) = fullBeta{i}(regInd,:); %extract desired betas
end
meanbeta = nanmean(betas,3); %compute mean beta over 10 fold crossval
betareconstructed = svdFrameReconstruct(U, meanbeta'); %recover from SVD space
mask = squeeze(isnan(U(:,:,1)));
allenMask = dorsalMaps.allenMask;

if ~isempty(subframes)
    fprintf('\nsubselecting beta frames');
    betareconstructed = betareconstructed(:,:,subframes);
end
betalength = size(betareconstructed,3);
fprintf('\nThere are %i frames for this regressor',betalength);



alignedmat = alignAllenTransIm(betareconstructed,opts3.transParams); %align to allen atlas
alignedmat = alignedmat(:, 1:size(allenMask,2),:);
edgemap = dorsalMaps.edgeMapScaled(1:size(alignedmat,1),:); %allen edge map

for i = 1:size(alignedmat,3)
    oneframe = alignedmat(:,:,i);
    oneframe(edgemap == 1) = NaN; %apply allen edge map
    oneframe(allenMask == 1) = NaN; %apply allen mask
    alignedmat(:,:,i) = oneframe;
end

end

