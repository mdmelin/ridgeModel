function transParams = loadTransParams(cPath,mouse,rec)
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];

try
    load([datapath 'opts3.mat']); %to get alignment opts
catch
    try
        load([datapath 'opts2.mat']); %to get alignment opts
        opts3 = opts;
    catch
        load([datapath 'opts.mat']); %to get alignment opts
        opts3 = opts;
    end
end

transParams = opts3.transParams;
end