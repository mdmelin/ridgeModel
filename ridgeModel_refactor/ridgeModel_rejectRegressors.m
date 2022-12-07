function [R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(fullR,regLabels,regIdx,regZeroFrames)

MIN_ENTRIES = 10;

rejIdx = false(1,size(fullR,2));

%reject empty regressors
rejIdx = nansum(abs(fullR)) < MIN_ENTRIES; %for analog regressors with less than min entries
fprintf(1, 'Rejected %d of %d total regressors for emptiness (less than %d entries).\n', sum(rejIdx),length(rejIdx), MIN_ENTRIES);
regIdx2 = regIdx(~rejIdx);

%reject rank deficient regressors
[~, fullQRR] = qr(bsxfun(@rdivide,fullR(:,~rejIdx),sqrt(sum(fullR(:,~rejIdx).^2))),0); %orthogonalize design matrix
%figure; plot(abs(diag(fullQRR))); ylim([0 1.1]); title('Regressor orthogonality'); drawnow; %this shows how orthogonal individual regressors are to the rest of the matrix
if sum(abs(diag(fullQRR)) > max(size(fullR(:,~rejIdx))) * eps(fullQRR(1))) < size(fullR(:,~rejIdx),2) %check if design matrix is full rank
    temp = ~(abs(diag(fullQRR)) > max(size(fullR(:,~rejIdx))) * eps(fullQRR(1))); %reject regressors that cause rank-defficint matrix
    rejIdx(~rejIdx) = temp;
    deficientLabels = unique(regLabels(regIdx2(temp)));
    fprintf('WARNING: %s is at least partially deficient. \n', deficientLabels{:});
end
fprintf(1, 'Rejected %d of %d total regressors for rank deficiency.\n', sum(temp),length(rejIdx));


fullR(:,rejIdx) = []; %clear empty and rank deficient regressors if requested
regIdx = regIdx2(~temp); %clear rank deficient regressors

regLabelsOld = regLabels;
regLabels = regLabels(unique(regIdx));

temp = []; count = 1;
for i = unique(regIdx) %remove the skiped indices for discared reginds
    temp(regIdx == i) = count;
    count = count+1;
end
regIdx = temp;

%print out the regressors that were fully discarded
discardLabels = regLabelsOld(~ismember(regLabelsOld,regLabels));
if length(discardLabels) > 0
    fprintf('Fully discarded regressor: %s \n', discardLabels{:});
else
    fprintf('\nNo regressors were FULLY discarded\n');
end
regZeroFrames = regZeroFrames(~rejIdx);
R = fullR;
% regMarkers = [1 diff(regIdx)]; %marks the indices where regressors begin
% figure; hold on;plot(regMarkers); plot(rejIdx); legend('regMarkers','rejIdx');

% the following code doesn't work because the analog regressors don't have
% an alignment frame by nature
% savedAlignmentFrameLabels = regLabels(regIdx(find(regZeroFrames)));%check if the alignment event frames got rejected
% rejectedAlignmentFrameLabels = regLabels(~ismember(regLabels, savedAlignmentFrameLabels));
% fprintf('WARNING: The alignment frame for %s was rejected. \n', rejectedAlignmentFrameLabels{:});

end
