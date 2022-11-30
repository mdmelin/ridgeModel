% Highlight an allen region (nice to show what region you are plotting).
load('C:\Data\churchland\ridgeModel\allenDorsalMapMM.mat');
mycmap = load('C:\Data\churchland\ridgeModel\smallStuff\CustomColormap2.mat');
mycmap = mycmap.CustomColormap2;

allenmask = dorsalMaps.allenMask;
areamap = dorsalMaps.areaMap;
areamap = areamap(1:size(allenmask,1),:);

labels = dorsalMaps.labelsSplit;

for i = 1:length(labels)
edgemap = dorsalMaps.edgeMapScaledMax(1:size(allenmask,1),:);
edgemap = double(edgemap);
edgemap(edgemap ~= 1) = -5;
edgemap(edgemap == 1) = 20;
edgemap(areamap == i) = 20;
edgemap(allenmask) = NaN;
mapImg = imshow(edgemap, [-20 20]);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
set(mapImg,'AlphaData',~isnan(mapImg.CData));
exportgraphics(gcf,['C:\Data\churchland\PowerpointsPostersPresentations\SFN2022\allenhighlighter' filesep labels{i} '.png']);
close gcf
end
