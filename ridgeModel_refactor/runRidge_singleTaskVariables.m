function runRidge_singleTaskVariables(cPath,animal,rec,glmPath)
%trains the ridge model for one session over several conditions of design
%matrix shuffling

%TODO: move trial selection outside of first function
%TODO: separate out video alignment and imaging alignment in python

NFOLDS = 10;
fileprefix = '';

%get the design matrices
[regLabelsAll,regIdxAll,RA,regZeroFramesAll,zeromeanVcA,U,usedTrialsA] = ridgeModel_returnDesignMatrix(cPath,animal,rec,glmPath,'attentive',[],false);
[~,~,RB,~,zeromeanVcB,~,usedTrialsB] = ridgeModel_returnDesignMatrix(cPath,animal,rec,glmPath,'biased',[],false);

if isempty(RA) || isempty(RB) %skip sessions with too few trials
    return
end
% create some label groups
taskvarlabels = {'time', 'Choice','reward','handleSound','lfirstTacStim','lTacStim','rfirstTacStim','rTacStim','lfirstAudStim','lAudStim','rfirstAudStim','rAudStim','prevReward','prevChoice','nextChoice','water'};
opmotorlabels = {'lGrab','lGrabRel','rGrab','rGrabRel','lLick','rLick'};
spontmotorlabels = {'piezoAnalog','piezoDigital','piezoMoveAnalog','piezoMoveDigital','piezoMoveHiDigital','whiskAnalog','whiskDigital','whiskHiDigital','noseAnalog','noseDigital','noseHiDigital','fastPupilAnalog','fastPupilDigital','fastPupilHiDigital','slowPupil','faceAnalog','faceDigital','faceHiDigital','bodyAnalog','bodyDigital','bodyHiDigital','Move','bhvVideo'};
% make sure theyre in the right order and are included in the model
taskvarlabels = regLabelsAll(sort(find(ismember(regLabelsAll,taskvarlabels))));
opmotorlabels = regLabelsAll(sort(find(ismember(regLabelsAll,opmotorlabels))));
spontmotorlabels = regLabelsAll(sort(find(ismember(regLabelsAll,spontmotorlabels))));

for i = 1:length(taskvarlabels)
    %run single variable
    shuffleLabels = regLabelsAll(~ismember(regLabelsAll, taskvarlabels{i}));

    R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
    [R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
    [R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
    [Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
    ridgeModel_saveResults(cPath,animal,rec, [fileprefix taskvarlabels{i} 'A'], Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames, usedTrialsA);

    R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
    [R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
    [R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
    [Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS);
    ridgeModel_saveResults(cPath,animal,rec, [fileprefix taskvarlabels{i} 'B'], Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames, usedTrialsB);

    %deltaR2
    shuffleLabels = regLabelsAll(ismember(regLabelsAll, taskvarlabels{i}));

    R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
    [R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
    [R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
    [Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
    ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'no' taskvarlabels{i} 'A'], Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames, usedTrialsA);

    R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
    [R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
    [R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
    [Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS);
    ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'no' taskvarlabels{i} 'B'], Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames, usedTrialsB);


end

end