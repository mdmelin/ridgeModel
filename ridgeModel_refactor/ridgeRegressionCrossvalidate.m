function [Vm, betas, fullR, lambdas, rejIdx, cMap, cMovie] =  ridgeRegressionCrossvalidate(fullR,U,Vc,regLabels,regIdx,frames,ridgeFolds,rejectEmpty,rejectRankDeficient)
% maybe make Vc zero mean in this function instead of the other
% one?
MIN_ENTRIES = 10;
rejIdx = false(1,size(fullR,2));
if rejectEmpty %reject empty regressors
    rejIdx = nansum(abs(fullR)) < MIN_ENTRIES; %for analog regressors with less than min entries
    fprintf(1, 'Rejected %d of %d total regressors for emptiness (less than %d entries).\n', sum(rejIdx),length(rejIdx), MIN_ENTRIES);
    regIdx2 = regIdx(~rejIdx);
end

if rejectRankDeficient
    [~, fullQRR] = qr(bsxfun(@rdivide,fullR(:,~rejIdx),sqrt(sum(fullR(:,~rejIdx).^2))),0); %orthogonalize design matrix
    %figure; plot(abs(diag(fullQRR))); ylim([0 1.1]); title('Regressor orthogonality'); drawnow; %this shows how orthogonal individual regressors are to the rest of the matrix
    if sum(abs(diag(fullQRR)) > max(size(fullR(:,~rejIdx))) * eps(fullQRR(1))) < size(fullR(:,~rejIdx),2) %check if design matrix is full rank
        temp = ~(abs(diag(fullQRR)) > max(size(fullR(:,~rejIdx))) * eps(fullQRR(1))); %reject regressors that cause rank-defficint matrix
        rejIdx(~rejIdx) = temp;
        deficientLabels = unique(regLabels(regIdx2(temp)));
        fprintf('WARNING: %s is at least partially deficient. \n', deficientLabels{:});
    end
    fprintf(1, 'Rejected %d of %d total regressors for rank deficiency.\n', sum(temp),length(rejIdx));
end

fullR(:,rejIdx) = []; %clear empty and rank deficient regressors if requested

%print out the regressors that were fully discarded
discardLabels = [];
for i = unique(regIdx)
    regMask = regIdx == i;
    if sum(rejIdx(regMask)) < sum(regMask)
        continue
    end
    discardLabels = [discardLabels regLabels(i)];
end

if length(discardLabels) > 0
    fprintf('Fully discarded regressor: %s because of NaN''s or emptiness \n', discardLabels{:});
else
    fprintf('\nNo regressors were FULLY discarded\n');
end

regMarkers = [1 diff(regIdx)]; %marks the indices where regressors begin
figure; hold on;plot(regMarkers); plot(rejIdx); legend('regMarkers','rejIdx');

%now move on to the regression
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
cMap = gather((covP ./ stdPxPy)');

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
    cMovie(:,iFrames) = gather(covP ./ stdPxPy)';
    clear cData cModel
end

fprintf('Run finished. Mean R^2: %f... Median R^2: %f\n', mean(cMap(:)), median(cMap(:)));
end