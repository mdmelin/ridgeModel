%This function plots an average activation map for the desired trial periods
function [handlemovies,stimmovies,delaymovies,responsemovies] = plotActivationMap(cPath,Animal,Rec,inds,plttitle,pltlegend,clims,suppress)
for i = 1:length(inds) %will iterate thru each trial set and calculate a PSTH for those
    [alVc,~] = align2behavior(cPath,Animal,Rec,inds{i}); %pass trialinds based on the sessiondata file, this function will work out the imaging data
    
    [handleout{i},mask] = unSVDalign2allen(alVc.handle,alVc.U,alVc.transParams,[]); %returns the unSVD'd, allen aligned, arrayShrunk movie (and its mask to undo the arrayshrink
    [stimout{i},mask] = unSVDalign2allen(alVc.stim,alVc.U,alVc.transParams,[]);
    [delayout{i},mask] = unSVDalign2allen(alVc.delay,alVc.U,alVc.transParams,[]);
    [responseout{i},mask] = unSVDalign2allen(alVc.response,alVc.U,alVc.transParams,[]);%movie dims are [pixels, frames, trials]
    
    
    handlemovie = squeeze(mean(handleout{i},3));%average over trials in the trial period
    handlemovie = squeeze(mean(handlemovie,2));%average over time
    handlemovie = zscore(handlemovie,[],1); %z score across brain area (pixels
    handlemovies{i} = arrayShrink(handlemovie,mask,'split');
    
    stimmovie = squeeze(mean(stimout{i},3));
    stimmovie = squeeze(mean(stimmovie,2));
    stimmovie = zscore(stimmovie,[],1); %z score across brain area (pixels
    stimmovies{i} = arrayShrink(stimmovie,mask,'split');
    
    delaymovie = squeeze(mean(delayout{i},3));
    delaymovie = squeeze(mean(delaymovie,2));
    delaymovie = zscore(delaymovie,[],1); %z score across brain area (pixels
    delaymovies{i} = arrayShrink(delaymovie,mask,'split');
    
    responsemovie = squeeze(mean(responseout{i},3));
    responsemovie = squeeze(mean(responsemovie,2));
    responsemovie = zscore(responsemovie,[],1); %z score across brain area (pixels
    responsemovies{i} = arrayShrink(responsemovie,mask,'split');
end
if suppress == "True" %suppress plotting
    return
end
%
% temp = squeeze(mean(handleout{1},3)) - squeeze(mean(handleout{2},3));%average over trials then subtract
% temp = squeeze(mean(temp,2));%average over time
% temp = zscore(temp,[],1); %zscore
% handlemovies{3} = arrayShrink(temp,mask,'split');
%
% temp = squeeze(mean(stimout{1},3)) - squeeze(mean(stimout{2},3));%average over trials then subtract
% temp = squeeze(mean(temp,2));%average over time
% temp = zscore(temp,[],1); %zscore
% stimmovies{3} = arrayShrink(temp,mask,'split');
%
% temp = squeeze(mean(delayout{1},3)) - squeeze(mean(delayout{2},3));%average over trials then subtract
% temp = squeeze(mean(temp,2));%average over time
% temp = zscore(temp,[],1); %zscore
% delaymovies{3} = arrayShrink(temp,mask,'split');
%
% temp = squeeze(mean(responseout{1},3)) - squeeze(mean(responseout{2},3));%average over trials then subtract
% temp = squeeze(mean(temp,2));%average over time
% temp = zscore(temp,[],1); %zscore
% responsemovies{3} = arrayShrink(temp,mask,'split');


%plotting
figure('units','normalized','outerposition',[0 0 1 1])
for i = 1:2
    subplot(3,4,1+(i-1)*4);
    mapImg = imshow(handlemovies{i}, clims);
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Handles');
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'SDU activity';
    ylabel(pltlegend{i});
    
    subplot(3,4,2+(i-1)*4);
    mapImg = imshow(stimmovies{i}, clims);
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Stimulus');
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'SDU activity';
    
    subplot(3,4,3+(i-1)*4);
    mapImg = imshow(delaymovies{i}, clims);
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Delay');
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'SDU activity';
    
    subplot(3,4,4+(i-1)*4);
    mapImg = imshow(responsemovies{i}, clims);
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response');
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'SDU activity';
end

subplot(3,4,9);
mapImg = imshow(handlemovies{1} - handlemovies{2}, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Handles');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'SDU activity';
ylabel('Difference');

subplot(3,4,10);
mapImg = imshow(stimmovies{1} - stimmovies{2}, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Stimulus');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'SDU activity';

subplot(3,4,11);
mapImg = imshow(delaymovies{1} - delaymovies{2}, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Delay');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'SDU activity';

subplot(3,4,12);
mapImg = imshow(responsemovies{1} - responsemovies{2}, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'SDU activity';

sgtitle(plttitle);

end