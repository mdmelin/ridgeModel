function plotHeatmap(image, clims, plttitle, colorbartitle, cmap, fsize)

if isempty(cmap) %default cmap to blueblackred if arg is empty
    cmap = 'colormap_blueblackred';
end

mapImg = imshow(image, clims);
colormap(mapImg.Parent,cmap); axis image; title(plttitle);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.

hcb = colorbar;
hcb.Title.String = colorbartitle;

if isempty(colorbartitle)
    set(colorbar,'visible','off')
end

if ~isempty(fsize)
    set(gca,'FontSize',fsize)
end
end