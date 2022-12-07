function runRidge_fullAndShuffle(cPath,animal,rec,glmFile)
%TODO: move trial selection outside of first function
%TODO: separate out video alignment and imaging alignment in python
NFOLDS = 10;
REJECT_EMPTY_REGRESSORS = true;
REJECT_RANK_DEFICIENT = true;
FILENAME = 'deleteme';

[regLabelsFull,regIdxFull,fullR,regZeroFramesFull,zeromeanVc,U] = ridgeModel_returnDesignMatrix(cPath,animal,rec,glmFile,'attentive',[]);

%run without regressor rejection
[~, ~, ~, cMap, ~] = ridgeModel_crossValidate(fullR,U,zeromeanVc,75,NFOLDS); %need to adjust kernel zero points if they get discarded, or maybe make them nans

%run with regressor rejection
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(fullR,regLabelsFull,regIdxFull,regZeroFramesFull);
[Vm, betas, lambdas, cMap2, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVc,75,NFOLDS); %need to adjust kernel zero points if they get discarded, or maybe make them nans

%run after shuffling all regressors
shuffleLabels = regLabelsFull;
shuffledR = shuffleDesignMatrix(regLabelsFull,regIdxFull,fullR,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(shuffledR,regLabelsFull,regIdxFull,regZeroFramesFull);
[Vm, betas, lambdas, cMap2, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVc,75,NFOLDS); %need to adjust kernel zero points if they get discarded, or maybe make them nans

%ridgeModel_saveResults(cPath,animal,rec, FILENAME, Vm, zeromeanVc, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

end


%run with full shuffle