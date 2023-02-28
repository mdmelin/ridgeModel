function [Vm, betas, lambdas, cMap, cMovie] =  ridgeModel_crossValidate(fullR,U,Vc,frames,ridgeFolds)
% maybe make Vc zero mean in this function instead of the other
% one?
Vm = zeros(size(Vc),'single'); %pre-allocate reconstructed V
randIdx = randperm(size(Vc,2)); %generate randum number index
foldCnt = floor(size(Vc,2) / ridgeFolds);
betas = cell(1,ridgeFolds);

for iFolds = 1:ridgeFolds
    dataIdx = true(1,size(Vc,2));

    if ridgeFolds > 1
        dataIdx(randIdx(((iFolds - 1)*foldCnt) + (1:foldCnt))) = false; %index for training data
        if iFolds == 1
            [lambdas, betas{iFolds}] = ridgeMML(Vc(:,dataIdx)', fullR(dataIdx,:), true); %get beta weights and ridge penalty for task only model
        else
            [~, betas{iFolds}] = ridgeMML(Vc(:,dataIdx)', fullR(dataIdx,:), true, lambdas); %get beta weights for task only model. ridge value should be the same as in the first run.
        end
        Vm(:,~dataIdx) = (fullR(~dataIdx,:) * betas{iFolds})'; %predict remaining data

        if rem(iFolds,ridgeFolds/5) == 0
            fprintf(1, 'Current fold is %d out of %d\n', iFolds, ridgeFolds);
        end
    else
        [lambdas, betas{iFolds}] = ridgeMML(Vc', fullR, true); %get beta weights for task-only model.
        Vm = (fullR * betas{iFolds})'; %predict remaining data
        disp('Ridgefold is <= 1, fit to complete dataset instead');
    end
end

% computed all predicted variance
Vc = reshape(Vc,size(Vc,1),[]);
Vm = reshape(Vm,size(Vm,1),[]);
if length(size(U)) == 3
    U = arrayShrink(U, squeeze(isnan(U(:,:,1))));
end
covVc = cov(Vc');  % S x S
covVm = cov(Vm');  % S x S
cCovV = bsxfun(@minus, Vm, mean(Vm,2)) * Vc' / (size(Vc, 2) - 1);  % S x S
covP = sum((U * cCovV) .* U, 2)';  % 1 x P
varP1 = sum((U * covVc) .* U, 2)';  % 1 x P
varP2 = sum((U * covVm) .* U, 2)';  % 1 x P
stdPxPy = varP1 .^ 0.5 .* varP2 .^ 0.5; % 1 x P
cMap = gather((covP ./ stdPxPy)') .^ 2;

% movie for predicted variance
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

fprintf('Run finished. Mean R^2: %f... Median R^2: %f\n', mean(cMap(:)), median(cMap(:)));
end