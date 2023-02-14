function runRidge_overStates(cPath,animal,rec,glmPath)
%trains the ridge model for one session over several conditions of design
%matrix shuffling

%TODO: move trial selection outside of first function
%TODO: separate out video alignment and imaging alignment in python

NFOLDS = 10;
fileprefix = '';

%get the design matrices
[regLabelsAll,regIdxAll,RA,regZeroFramesAll,zeromeanVcA,U] = ridgeModel_returnDesignMatrix(cPath,animal,rec,glmPath,'attentive',[],false);
[~,~,RB,~,zeromeanVcB,~] = ridgeModel_returnDesignMatrix(cPath,animal,rec,glmPath,'biased',[],false);

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



%run engaged trials with regressor rejection
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(RA,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'fullA'], Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

%run disengaged trials with regressor rejection
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(RB,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'fullB'], Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

%run with only task variables - shuffle spont and op motor labels
shuffleLabels = regLabelsAll(~ismember(regLabelsAll, taskvarlabels));

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'taskA'], Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'taskB'], Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

%run with only operant variables
shuffleLabels = regLabelsAll(~ismember(regLabelsAll, opmotorlabels));

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'operantA'], Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'operantB'], Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

%run with only spontaneous motor variables
shuffleLabels = regLabelsAll(~ismember(regLabelsAll, spontmotorlabels));

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'spontA'], Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'spontB'], Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);


%run without task variables - shuffle task variables only
shuffleLabels = regLabelsAll(ismember(regLabelsAll, taskvarlabels));

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'notaskA'], Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'notaskB'], Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

%run without operant variables
shuffleLabels = regLabelsAll(ismember(regLabelsAll, opmotorlabels));

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'nooperantA'], Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'nooperantB'], Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

%run without spontaneous motor variables
shuffleLabels = regLabelsAll(ismember(regLabelsAll, spontmotorlabels));

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'nospontA'], Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectEmptyRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectDeficientRegressors(R,regLabels,regIdx,regZeroFrames);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, [fileprefix 'nospontB'], Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, regLabels, regIdx, rejIdx, regZeroFrames);


end