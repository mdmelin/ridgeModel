function saveEncodingModelResults(cPath,animal,rec, filename, Vm, Vc, U, R, betas, lambdas, cMap, cMovie, regIdx, regLabels, rejIdx)
TASK = 'SpatialDisc';

if ~strcmpi(filename(end-3:end),'.mat')
    filename = [filename '.mat'];
end
savepath = [cPath filesep animal filesep TASK filesep rec filesep];

save(savepath, 'Vm', 'Vc', 'U', 'R', 'betas', 'lambdas', 'cMap', 'cMovie', 'regIdx', 'regLabels', 'rejIdx');
end