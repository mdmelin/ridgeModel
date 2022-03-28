function scatterAnimal(cPath,animal,recs,glmFile,region,color,taskvar,trialperiod)

for i = 1:length(recs)
    if taskvar == "State"
        [inds{1},inds{2},inds{3}] = getStateInds(cPath,animal,recs{i},glmFile);
    elseif taskvar == "Choice"
        [inds{1},inds{2},inds{3}] = getChoiceInds(cPath,animal,recs{i});
    end
    
    [Vc1,bhv1] = align2behavior(cPath,animal,recs{i},inds{2}); %pass trialinds based on the sessiondata file, this function will work out the imaging data
    [Vc2,bhv2] = align2behavior(cPath,animal,recs{i},inds{3}); %pass trialinds based on the sessiondata file, this function will work out the imaging data

    [movie1,mask1] = unSVDalign2allen(Vc1.all,Vc1.U,Vc1.transParams,region); %returns the unSVD'd, allen aligned, arrayShrunk movie (and its mask to undo the arrayshrink
    [movie2,mask2] = unSVDalign2allen(Vc2.all,Vc2.U,Vc2.transParams,region); %returns the unSVD'd, allen aligned, arrayShrunk movie (and its mask to undo the arrayshrink
    movie1 = squeeze(mean(movie1,1,'omitnan')); %average over the desired pixels
    movie2 = squeeze(mean(movie2,1,'omitnan')); %dims are now [frames, trials]
    %movie1 = zscore(movie1,[],1); %zscore over time
    %movie2 = zscore(movie2,[],1); %zscore over time
    
    trialavg1 = squeeze(mean(movie1,2,'omitnan')); %get trialavg, now nframes long
    SEM1 = std(movie1,[],2,'omitnan')/sqrt(size(movie1,2)); %get SEM over trials, now nframes long
    trialavg2 = squeeze(mean(movie2,2,'omitnan')); %get trialavg
    SEM2 = std(movie2,[],2,'omitnan')/sqrt(size(movie2,2)); %get SEM over trials
    
    eventmarkers = [1 Vc1.segFrames];
    frames2grab = eventmarkers(trialperiod):eventmarkers(trialperiod+1); %grab from the trial period: 1 = bline,2 = handlegrab,3 = stim,4 = delay, 5 = response period

    eventavg1(i) = mean(trialavg1(frames2grab));
    eventavg2(i) = mean(trialavg2(frames2grab));
    SEMavg1(i) = mean(SEM1(frames2grab));
    SEMavg2(i) = mean(SEM2(frames2grab));
end

e = errorbar(eventavg1,eventavg2,SEMavg2,SEMavg2,SEMavg1,SEMavg1,'-s', ...
    'MarkerSize',8,'MarkerEdgeColor',color,'LineStyle','none','MarkerFaceColor',color);
e.Color = 'black';
end