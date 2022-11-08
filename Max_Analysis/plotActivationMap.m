%This function plots an average activation map for the desired trial periods
function out = plotActivationMap(cPath,Animal,Rec,inds,plttitle,pltlegend,clims,suppress)
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
for i = 1:length(inds) %will iterate thru each trial set and calculate a PSTH for those
    [alVc,~] = align2behavior(cPath,Animal,Rec,inds{i}); %pass trialinds based on the sessiondata file, this function will work out the imaging data
    
    [alignedVc,mask] = unSVDalign2allen(alVc.all,alVc.U,alVc.transParams,[],true); %returns the unSVD'd, allen aligned, arrayShrunk movie (and its mask to undo the arrayshrink
    
    alignedVc = squeeze(mean(alignedVc,3));%average over trials in the trial period
    
    frames = alVc.segFrames; %event frames
    %the following lines grab the event periods and average over time, then
    %z score.
    frames = [1 frames];
    for j = 1:length(frames)-1 %iterate thru trial periods
        movie = alignedVc(:,frames(j):frames(j+1));
        avgmovie = squeeze(mean(double(movie),2,'omitnan'));%avg over time
        %avgmovie = zscore(avgmovie); %z score over pixels
        out{i,j} = arrayShrink(avgmovie,mask,'split');
    end
end

if suppress %suppress plotting
    return
end


%plotting
figure('units','normalized','outerposition',[0 0 1 1])
for i = 1:2
    subplot(3,5,1+(i-1)*5);
    mapImg = imshow(out{i,1}, clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Baseline');
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'SDU activity';
    ylabel(pltlegend{i});
    
    subplot(3,5,2+(i-1)*5);
    mapImg = imshow(out{i,2}, clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Handles');
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'SDU activity';
    
    subplot(3,5,3+(i-1)*5);
    mapImg = imshow(out{i,3}, clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Stimulus');
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'SDU activity';
    
    subplot(3,5,4+(i-1)*5);
    mapImg = imshow(out{i,4}, clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Delay');
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'SDU activity';
    
    subplot(3,5,5+(i-1)*5);
    mapImg = imshow(out{i,5}, clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response');
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'SDU activity';
end
mycmap = load('CustomColormap2.mat');
mycmap = mycmap.CustomColormap2;


subplot(3,5,11);
mapImg = imshow(out{1,1} - out{2,1}, clims{2});
colormap(mapImg.Parent,mycmap); axis image; title('Baseline');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'SDU activity';
ylabel('Difference');

subplot(3,5,12);
mapImg = imshow(out{1,2} - out{2,2}, clims{2});
colormap(mapImg.Parent,mycmap); axis image; title('Handles');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'SDU activity';

subplot(3,5,13);
mapImg = imshow(out{1,3} - out{2,3}, clims{2});
colormap(mapImg.Parent,mycmap); axis image; title('Stimulus');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'SDU activity';

subplot(3,5,14);
mapImg = imshow(out{1,4} - out{2,4}, clims{2});
colormap(mapImg.Parent,mycmap); axis image; title('Delay');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'SDU activity';

subplot(3,5,15);
mapImg = imshow(out{1,5} - out{2,5}, clims{2});
colormap(mapImg.Parent,mycmap); axis image; title('Response');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'SDU activity';
sgtitle(plttitle);

end