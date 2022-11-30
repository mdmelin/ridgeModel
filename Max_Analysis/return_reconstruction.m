function [Vm, Vc] = return_reconstruction(mouse,rec,modelfile)
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];load('C:\Data\churchland\ridgeModel\widefield\allenDorsalMapSM.mat','dorsalMaps'); %Get allen atlas
try
    load([datapath modelfile]);
catch
    fprintf('\nThe encoding model file does not exist!');
    out = NaN;
return
end

out = double(fullMovie);
out = mean(out,1);
Vm = 0;Vc = 0;
end