function plotHeatmap(image, clims, plttitle, colorbartitle, cmap)

if isempty(cmap) %default cmap to blueblackred if arg is empty
    cmap = 'colormap_blueblackred';
end

mapImg = imshow(image, clims);
colormap(mapImg.Parent,cmap); axis image; title(plttitle);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = colorbartitle;
end