function [regLabels, regZeroFrames, kernels] = returnBetaKernels(mouse,rec,modelfile)
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];
try
    load([datapath modelfile]);
catch
    fprintf('\nThe encoding model file does not exist!');
    out = NaN;
return
end

meanbetas = mean(cat(3,betas{:}),3);

for i = 1:length(regLabels)
inds = 2;
end

%get kernels here

end