% We know that there is a heatmap difference that is state dependent. So lets
% plot this heatmat, then get some PSTH's, and finally, revisit the results
% of the encoding model.
clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions
cPath = 'X:\Widefield';

%Need to fix the trial lengths for CSP mice!!!!!

animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'allaudio_detection.mat'; %32 not working for some reason
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; %CSP32 missing transparams


method = 'cutoff';
mintrialnum = 20; %the minimum number of trials per state to be included in plotting
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data
%clims = {[-.01 .01],[-.005 .005]};
clims = {[-.01 .01],[-.01 .01]};
%% Plot avg activity map
inds = {NaN,NaN};
for i = 1:length(animals) %try a few different sessions
    fprintf('\nrunning %s\n',animals{i});
    for j = 1:length(sessiondates{i})
        Rec = sessiondates{i}{j};
        [~,a,b] = getStateInds(cPath,animals{i},Rec,method,glmFile,dualcase);
        nt = num2str(length(a));
        if length(a) < mintrialnum %skip if too few trials
            out{i,j,:,:} = [];
        else
            out{i,j,:,:} = plotActivationMap(cPath,animals{i},Rec,{a,b},[animals{i} ' ' Rec ': ' nt ' trials per state'],{'Attentive trials','Bias trials'},clims,true);
        end
    end
end
clear attend bias
loc = 1; %use this to squish animals and sessions into one dimension
for i = 1:length(animals) %iterate thru animals
    for j = 1:length(sessiondates{i})
        if ~isempty(out{i,j})
            for k = 1:5 %iterate thru trial periods

                attend(loc,k,:,:) = out{i,j}{1,k}; %[animals, trial periods, x, y]
                bias(loc,k,:,:) = out{i,j}{2,k};
            end
            loc = loc + 1;
        end

    end
end

attendmean = squeeze(mean(attend,1,'omitnan')); %average over animals/sessions
biasmean = squeeze(mean(bias,1,'omitnan')); %average over animals/sessions
combo = cat(4,attendmean,biasmean);

% plotting
pltlegend = {'Engaged trials','Bias trials'};
fsize = 29;
set(gca,'FontSize',fsize)
%plttitle = 'Activity map averaged over sessions';
plttitle = '';
figure('units','normalized','outerposition',[0 0 1 1],'PaperSize',[40 40])
%figure
for i = 1:2
    subplot(3,5,1+(i-1)*5);
    mapImg = imshow(squeeze(combo(1,:,:,i)), clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
    if i == 1
        title('Baseline','FontSize',fsize);
    end
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    %hcb = colorbar;
    %hcb.Title.String = 'dF/F';
    ylabel(pltlegend{i},'FontSize',fsize);

    subplot(3,5,2+(i-1)*5);
    mapImg = imshow(squeeze(combo(2,:,:,i)), clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
    if i == 1
        title('Trial Initiation','FontSize',fsize);
    end
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    %hcb = colorbar;
    %hcb.Title.String = 'dF/F';

    subplot(3,5,3+(i-1)*5);
    mapImg = imshow(squeeze(combo(3,:,:,i)), clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
    if i == 1
        title('Stimulus','FontSize',fsize);
    end
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    %hcb = colorbar;
    %hcb.Title.String = 'dF/F';

    subplot(3,5,4+(i-1)*5);
    mapImg = imshow(squeeze(combo(4,:,:,i)), clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
    if i == 1
        title('Delay','FontSize',fsize);
    end
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    %hcb = colorbar;
    %hcb.Title.String = 'dF/F';

    subplot(3,5,5+(i-1)*5);
    mapImg = imshow(squeeze(combo(5,:,:,i)), clims{1});
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
    if i == 1
        title('Response','FontSize',fsize);
    end
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    hcb = colorbar;
    hcb.Title.String = 'dF/F';
    hcb.Position = hcb.Position + [0.02 0 0 0];
    hcb.FontSize = fsize;
end

subplot(3,5,11);
mapImg = imshow(squeeze(combo(1,:,:,1) - combo(1,:,:,2)), clims{2});
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Baseline');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
%hcb = colorbar;
%hcb.Title.String = 'dF/F';
ylabel('Difference','FontSize',fsize);

subplot(3,5,12);
mapImg = imshow(squeeze(combo(2,:,:,1) - combo(2,:,:,2)), clims{2});
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Trial Initiation');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
%hcb = colorbar;
%hcb.Title.String = 'dF/F';

subplot(3,5,13);
mapImg = imshow(squeeze(combo(3,:,:,1) - combo(3,:,:,2)), clims{2});
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Stimulus');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
%hcb = colorbar;
%hcb.Title.String = 'dF/F';

subplot(3,5,14);
mapImg = imshow(squeeze(combo(4,:,:,1) - combo(4,:,:,2)), clims{2});
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Delay');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
%hcb = colorbar;
%hcb.Title.String = 'dF/F';

subplot(3,5,15);
mapImg = imshow(squeeze(combo(5,:,:,1) - combo(5,:,:,2)), clims{2});
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Response');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'dF/F';
hcb.Position = hcb.Position + [0.01 0 0 0];
hcb.FontSize = fsize;
sgtitle(plttitle);

%% load the allen map, select regions to plot
clear z zname
t = load('C:\Data\churchland\ridgeModel\allenDorsalMapSM.mat');
map = t.dorsalMaps.areaMap;
figure
imagesc(map)
[x,y] = getpts;
x=int64(x);y=int64(y);

for i = 1:length(x)
    z(i) = map(y(i),x(i));
    zname{i} = t.dorsalMaps.labelsSplit(z(i));
end
zname = arrayfun(@string, zname);
fprintf('\nRegion to extract: %s',zname);
close

%% plot PSTHs

for i = 1:length(z)
    A = []; B = [];
    for j = 1:length(animals)
        for k = 1:length(sessiondates{j})
            [~,inds{1},inds{2}] = getStateInds(cPath,animals{j},sessiondates{j}{k},method,glmFile,dualcase);

            if length(inds{1}) < mintrialnum
                fprintf('\nSkipping!\n');
                continue
            end

            [temp,eventframes] = plotRegionPSTH(cPath,animals{j},sessiondates{j}{k},inds,z(i),zname(i),'pltlegend',false,true);
            A = [A,temp{1}]; B = [B,temp{2}]; %[nframes, ntrials]
        end
    end
    figure;hold on; title(zname(i))
    stdshade(A',.2,'red',[],6,eventframes,[]);
    stdshade(B',.2,'blue',[],6,eventframes,[]);
    legend('','','','','','Engaged trials','','','','','','Biased trials');
end

%% rerun encoding models

for i = 1:length(animals) %try a few different sessions
    parfor j = 1:length(sessiondates{i})
        ridgeModel_stateEncodingAligned(cPath,animals{i},sessiondates{i}{j},glmFile,[],[],true)
    end
end

%% Generate figure: "state is collinear with something"
counter = 1;
clim = [0 .2];
for i = 1:length(animals) %try a few different sessions
    for j = 1:length(sessiondates{i})
        state(counter,:,:) = plotRSquared(animals{i},sessiondates{i}{j},'allaudio_detection_full.mat',[],clim,true);
        stateshuffle(counter,:,:) = plotRSquared(animals{i},sessiondates{i}{j},'allaudio_detection_fullnostate.mat',[],clim,true);
        counter = counter+1;
    end
end
statediff = nanmean(state - stateshuffle,[2 3]);

%% rerun encoding model - sepbystate
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        animals{i}
        sessiondates{i}{j}
        ridgeModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,"attentive",[]);
        ridgeModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,"biased",[]);
    end
end

%%
counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fulla(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_fullmodel.mat');
        sponta(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlyspontmotor.mat');
        opa(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlyopmotor.mat');
        taskvara(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlytaskvars.mat');
        nosponta(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_nospontmotor.mat');
        noopa(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_noopmotor.mat');
        notaskvara(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_notaskvars.mat');

        fullb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_fullmodel.mat');
        spontb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlyspontmotor.mat');
        opb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlyopmotor.mat');
        taskvarb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlytaskvars.mat');
        nospontb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_nospontmotor.mat');
        noopb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_noopmotor.mat');
        notaskvarb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_notaskvars.mat');

        counter = counter + 1;
        fprintf('\ncounter is %i\n',counter);
    end
end

dsponta = fulla-nosponta;
dspontb = fullb-nospontb;
dtaska = fulla-notaskvara;
dtaskb = fullb-notaskvarb;
dopa = fulla-noopa;
dopb = fullb-noopb;

[a,b] = ttest(fulla,fullb)

[a,b] = ttest(taskvara,taskvarb) %maybe?
[a,b] = ttest(sponta,spontb)
[a,b] = ttest(opa,opb)

[a,b] = ttest(dtaska,dtaskb)
[a,b] = ttest(dsponta,dspontb) %maybe?
[a,b] = ttest(dopa,dopb)

%% figures
figure;
t1 = ones(length(dopa),1);
t2 = t1*2;

subplot(2,3,1); hold on;
scatter(t1,taskvara);
scatter(t2,taskvarb);
title('cvR2 - task variables');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,2); hold on;
scatter(t1,opa);
scatter(t2,opb);
title('cvR2 - operant movements');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,3); hold on;
scatter(t1,sponta);
scatter(t2,spontb);
title('cvR2 - task independent movements');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,4); hold on;
scatter(t1,dtaska);
scatter(t2,dtaskb);
title('deltaR2 - task variables');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,5); hold on;
scatter(t1,dopa);
scatter(t2,dopb);
title('deltaR2 - operant movements');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,6); hold on;
scatter(t1,dsponta);
scatter(t2,dspontb);
title('deltaR2 - task independent movements');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});






