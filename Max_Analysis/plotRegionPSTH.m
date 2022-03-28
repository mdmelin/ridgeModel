%This function plots an aligned PSTH for the selected brain area
function [movies,eventframes] = plotRegionPSTH(cPath,Animal,Rec,inds,selectRegion,plttitle,pltlegend,suppress)
for i = 1:length(inds) %will iterate thru each trial set and calculate a PSTH for those
    [alVc,bhv] = align2behavior(cPath,Animal,Rec,inds{i}); %pass trialinds based on the sessiondata file, this function will work out the imaging data
    [movie,mask] = unSVDalign2allen(alVc.all,alVc.U,alVc.transParams,selectRegion); %returns the unSVD'd, allen aligned, arrayShrunk movie (and its mask to undo the arrayshrink
    %movie dims are [pixels, frames, trials]
    
    movie = squeeze(mean(movie,1)); %average over the desired pixels
    movies{i} = movie; %no z scoring
    %movies{i} = zscore(movie,[],1); %z score across frames in the trial
end
eventframes = alVc.segFrames;
if suppress == 'True'
    return
end
%now make some indices NaN's for plotting
naninds = alVc.segFrames-1; %specifys values to ignore when plotting
%plot
figure;
cols = {'r','b','g'};
for i = 1:length(inds)
    stdshade(movies{i}',.2,cols{i},[],6,naninds,[]); %plot trial averaged activity
    hold on;
end
xline(alVc.segFrames);
title(plttitle);
ylabel('SDU''s');
legend(pltlegend);
end