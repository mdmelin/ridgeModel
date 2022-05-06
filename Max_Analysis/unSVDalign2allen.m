function [movie,mask] = unSVDalign2allen(Vc,U,transParams,selectRegion)
%Takes temporal components, spatial components, and alignment parameters to
%undo SVD and align to allen atlas. If selectRegion is not empty, the
%function will also trim the data so that only the desired allen aligned
%region is kept. The output is arrayShrunk to remove NaN's for
%computational efficiency. 
load('C:\Data\churchland\ridgeModel\allenDorsalMapSM.mat');
allenMask = dorsalMaps.allenMask;

alignU = alignAllenTransIm(double(U),transParams); %align to allen atlas
alignU = alignU(:, 1:size(allenMask,2),:);
edgemap = dorsalMaps.edgeMapScaled(1:size(alignU,1),:); %allen edge map
alignU(allenMask == 1) = NaN;
if ~isempty(selectRegion)
    areaMap = dorsalMaps.areaMap(1:size(alignU,1),:);
    alignU = alignU .* repmat(ismember(areaMap,selectRegion),[1,1,200]);
    alignU(alignU == 0) = NaN;
else
    alignU(edgemap == 1) = NaN; %apply allen edge map for visualization
end
figure;imagesc(alignU(:,:,1));title(['Plot of regions that will be extracted for analysis: ',num2str(selectRegion)]);
Vreshape = reshape(Vc,200,[]);
nFrames = size(Vc,2); %Frames per trial
nTrials = size(Vc,3); %total trials
movie = svdFrameReconstruct(alignU, Vreshape); %undo SVD

%uncomment these lines if arrayShrink is desired
mask = squeeze(isnan(movie(:,:,1))); 
movie = arrayShrink(movie,mask,'merge'); %shrink movie for better computation time
movie = reshape(movie,[],nFrames,nTrials);
end



