function [mdldate, Mdl, cvAcc, betas, Vc] = loadLogisticModel(cPath,Animal,Rec,modality,shuffle)

loadpath = [cPath filesep Animal filesep 'SpatialDisc' filesep char(Rec) filesep 'logisticDecode_' char(modality) '.mat'];
if shuffle
    loadpath = strrep(loadpath,'.mat','_shuffle.mat');
end
try
    in = load(loadpath);
catch
    fprintf('\nCould not find the logistic model results for this session! Probably weren''t enough trials to train this session.\n');
    Mdl = []; cvAcc = []; betas = []; Vc = []; mdldate = [];
    return
end
Mdl = in.Mdl; cvAcc = in.cvAcc; betas = in.betas_aligned; Vc = in.Vc;mdldate = Rec;
end