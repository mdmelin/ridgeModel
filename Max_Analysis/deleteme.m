regInd = ismember(regIdx(~rejIdx), find(ismember(fullLabels,myLabel))); %get the indices of desired regressor
for i = 1:10
    betas(:,:,i) = fullBeta{i}(regInd,:);
end
meanbetas = nanmean(betas,3);
datapath = ['X:\Widefield' filesep 'mSM63' filesep 'SpatialDisc' filesep '09-Jul-2018' filesep];

load([datapath 'rsVc.mat']);
betareconstructed = svdFrameReconstruct(U, meanbetas');

myval = nanmean(betareconstructed,3)
