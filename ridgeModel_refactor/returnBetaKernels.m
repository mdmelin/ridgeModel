function [regLabels, alignmentFrames, betaOut, U] = returnBetaKernels(mouse,rec,modelfile)
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
    betaOut{i} = meanbetas(find(regIdx == i),:);
    alignmentFrames{i} = find(regZeroFrames(find(regIdx == i))); %will be empty if there is no alignment frames
end

end