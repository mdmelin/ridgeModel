function histogramRSquared(mouse,rec,modelfiles,lims)
load('C:\Data\churchland\ridgeModel\widefield\allenDorsalMapSM.mat','dorsalMaps'); %Get allen atlas
addpath('C:\Data\churchland\ridgeModel\widefield');
addpath('C:\Data\churchland\ridgeModel\smallstuff');

%%
datapath = ['X:\Widefield' filesep mouse filesep 'SpatialDisc' filesep rec filesep];

load([datapath 'rsVc.mat']); %to get spatial components
load([datapath 'opts3.mat']); %to get alignment opts



%%
figure('units','normalized','outerposition',[0 0 1 1]);
hold on;
for i = 1:length(modelfiles) %iterate thru trial periods
    load([datapath modelfiles{i}]);
    modelfiles{i} = strrep(modelfiles{i},'_','\_'); %need to escape underscore when plotting
    histogram(fullMovie.^2,'BinWidth',.002);
    xlim(lims)
end
title('Variance explained for each pixel and timepoint');
legend(modelfiles);
drawnow;
end
