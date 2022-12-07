function runRidge_overStates(cPath,animal,rec,glmFile)
%trains the ridge model for one session over several conditions of design
%matrix shuffling

%TODO: move trial selection outside of first function
%TODO: separate out video alignment and imaging alignment in python

NFOLDS = 10;
REJECT_EMPTY_REGRESSORS = true;
REJECT_RANK_DEFICIENT = true;


%get the design matrices
[regLabelsAll,regIdxAll,RA,regZeroFramesAll,zeromeanVcA,U] = ridgeModel_returnDesignMatrix(cPath,animal,rec,glmFile,'attentive',[]);
[~,~,RB,~,zeromeanVcB,~] = ridgeModel_returnDesignMatrix(cPath,animal,rec,glmFile,'biased',[]);

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
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(RA,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS);
ridgeModel_saveResults(cPath,animal,rec, 'fullA', Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

%run disengaged trials with regressor rejection
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(RB,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'fullB', Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

%run with only task variables - shuffle spont and op motor labels
shuffleLabels = regLabelsAll(~ismember(regLabelsAll, taskvarlabels)); 

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'taskA', Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'taskB', Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

%run with only operant variables
shuffleLabels = regLabelsAll(~ismember(regLabelsAll, opmotorlabels)); 

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'operantA', Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'operantB', Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

%run with only spontaneous motor variables
shuffleLabels = regLabelsAll(~ismember(regLabelsAll, spontmotorlabels)); 

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'spontA', Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'spontB', Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);


%run without task variables - shuffle task variables only
shuffleLabels = regLabelsAll(ismember(regLabelsAll, taskvarlabels)); 

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'notaskA', Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'notaskB', Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

%run without operant variables
shuffleLabels = regLabelsAll(ismember(regLabelsAll, opmotorlabels)); 

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'nooperantA', Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'nooperantB', Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

%run without spontaneous motor variables
shuffleLabels = regLabelsAll(ismember(regLabelsAll, spontmotorlabels)); 

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RA,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcA,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'nospontA', Vm, zeromeanVcA, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);

R = shuffleDesignMatrix(regLabelsAll,regIdxAll,RB,shuffleLabels);
[R, regLabels, regIdx, regZeroFrames, rejIdx] = ridgeModel_rejectRegressors(R,regLabelsAll,regIdxAll,regZeroFramesAll);
[Vm, betas, lambdas, cMap, cMovie] = ridgeModel_crossValidate(R,U,zeromeanVcB,75,NFOLDS); 
ridgeModel_saveResults(cPath,animal,rec, 'nospontB', Vm, zeromeanVcB, U, R, betas, lambdas, cMap, cMovie, rejIdx, regIdx, regLabels, regZeroFrames);


end