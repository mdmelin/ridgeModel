function runRidge_fullAndShuffle(cPath,animal,rec,glmFile)
%TODO: move trial selection outside of first function
%TODO: separate out video alignment and imaging alignment in python
NFOLDS = 10;
REJECT_EMPTY_REGRESSORS = true;
REJECT_RANK_DEFICIENT = true;
FILENAME = 'deleteme';

[regLabelsFull,regIdxFull,fullR,regZeroFrames,zeromeanVc,U] = ridgeModel_returnDesignMatrix(cPath,animal,rec,glmFile,'attentive',[]);

[Vm, betas, R, lambdas, rejIdx, regIdx, regLabels, cMap, cMovie] = ridgeRegressionCrossvalidate(fullR,U,zeromeanVc,regLabelsFull,regIdxFull,75,NFOLDS,REJECT_EMPTY_REGRESSORS,REJECT_RANK_DEFICIENT); %need to adjust kernel zero points if they get discarded, or maybe make them nans

rejectedAlignmentFrameLabels = regLabelsFull(regIdxFull(rejIdx & regZeroFrames));%check if the alignment event frames got rejected
fprintf('WARNING: The alignment frame for %s was rejected. \n', rejectedAlignmentFrameLabels{:});


saveEncodingModelResults(cPath,animals{1},sessiondates{1}{1}, FILENAME, Vm, zeromeanVc, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels);
end
% 
