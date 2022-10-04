%This function plots an aligned PSTH for the selected brain area
function [movies,eventframes,time] = plotRegionPSTH(cPath,Animal,Rec,inds,selectRegion,plttitle,pltlegend,zscoring,suppress)
for i = 1:length(inds) %will iterate thru each trial set and calculate a PSTH for those
    [alVc,bhv] = align2behavior(cPath,Animal,Rec,inds{i}); %pass trialinds based on the sessiondata file, this function will work out the imaging data
    [movie,mask] = unSVDalign2allen(alVc.all,alVc.U,alVc.transParams,selectRegion,true); %returns the unSVD'd, allen aligned, arrayShrunk movie (and its mask to undo the arrayshrink
    %movie dims are [pixels, frames, trials]
    
    movie = squeeze(mean(movie,1)); %average over the desired pixels
    
    if zscoring
        movies{i} = zscore(movie,[],1); %z score across frames in the trial
    else
        movies{i} = movie;
    end
end
eventframes = alVc.segFrames;

%convert frames to times
zerotime = 2; %select stimulus onset as the time where t=0
%time = NaN(size(movie,1),1);
%time(eventframes(zerotime)) = 0;
postarraytime = (size(movie,1) - eventframes(zerotime)) / alVc.fs;
prearraytime = (eventframes(zerotime)-1) / alVc.fs;
postarray = 0:1/alVc.fs:postarraytime;
prearray = -(prearraytime:-1/alVc.fs:0);
time = [prearray(1:end-1) postarray()];


if suppress
    return
end
%now make some indices NaN's for plotting
naninds = alVc.segFrames-1; %specifys values to ignore when plotting

figure;
cols = {'r','b','g'};
for i = 1:length(inds)
    stdshade(movies{i}',.2,cols{i},time,6,naninds,[]); %plot trial averaged activity
    hold on;
end
xline(alVc.segFrames);
title(plttitle);
ylabel('SDU''s');
legend(pltlegend);
end