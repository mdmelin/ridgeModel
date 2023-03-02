function cMovie = computeFramewiseVariance(Vc, Vm, U, frames)

if length(size(U)) == 3
    U = arrayShrink(U, squeeze(isnan(U(:,:,1))));
end

cMovie = zeros(size(U,1),frames, 'single');
for iFrames = 1:frames
    frameIdx = iFrames:frames:size(Vc,2); %index for the same frame in each trial
    cData = bsxfun(@minus, Vc(:,frameIdx), mean(Vc(:,frameIdx),2));
    cModel = bsxfun(@minus, Vm(:,frameIdx), mean(Vm(:,frameIdx),2));
    covVc = cov(cData');  % S x S
    covVm = cov(cModel');  % S x S
    cCovV = cModel * cData' / (length(frameIdx) - 1);  % S x S
    covP = sum((U * cCovV) .* U, 2)';  % 1 x P
    varP1 = sum((U * covVc) .* U, 2)';  % 1 x P
    varP2 = sum((U * covVm) .* U, 2)';  % 1 x P
    stdPxPy = varP1 .^ 0.5 .* varP2 .^ 0.5; % 1 x P
    cMovie(:,iFrames) = gather(covP ./ stdPxPy)' .^ 2;
    clear cData cModel
end
end