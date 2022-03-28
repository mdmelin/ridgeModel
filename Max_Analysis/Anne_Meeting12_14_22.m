%% First thing: The GLM-HMM Results and Chaoqun's TIV data


%% train the encoding models
mSM63recs = {'09-Jul-2018','13-Jul-2018','16-Jul-2018','17-Jul-2018','18-Jul-2018','19-Jul-2018','20-Jul-2018'}; %mSM63
mSM64recs = {'24-Jul-2018','27-Jul-2018'}; %,,'25-Jul-2018' only has one state ,'26-Jul-2018' also not in
mSM65recs = {'05-Jul-2018','28-Jun-2018','29-Jun-2018','02-Jul-2018'}; %for mSM65, maybe put , back in
mSM66recs = {'27-Jun-2018','28-Jun-2018','29-Jun-2018','30-Jun-2018','02-Jul-2018','04-Jul-2018','05-Jul-2018','11-Jul-2018','16-Jul-2018'};%for mSM66 add , back in
%^these sessions are basically all of the audio discrimination sessions from these mice
addpath('C:\Data\churchland\ridgeModel\rateDisc');
addpath('C:\Data\churchland\ridgeModel\smallStuff');
mSM63labels = cell(1,length(mSM63recs));
mSM63labels(:) = {'mSM63'};
mSM64labels = cell(1,length(mSM64recs));
mSM64labels(:) = {'mSM64'};
mSM65labels = cell(1,length(mSM65recs));
mSM65labels(:) = {'mSM65'};
mSM66labels = cell(1,length(mSM66recs));
mSM66labels(:) = {'mSM66'};

encodingrecs = [mSM63recs,mSM64recs,mSM65recs,mSM66recs];
animals = [mSM63labels,mSM64labels,mSM65labels,mSM66labels];
cPath = 'X:/Widefield';
glmFile = 'allaudio.mat';
%%
for i = 1:length(animals)
    animals{i}
    encodingrecs{i}
    %ridgeModel_stateEncoding(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_stateEncodingAligned(cPath,animals{i},encodingrecs{i},glmFile,[]);
end

%% Get average variance explained by state
parfor i = 1:length(encodingrecs)
    state(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlystate.mat');
    choice(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlychoice.mat');
    reward(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlyreward.mat');
end

%% look at variance when state is shuffled
parfor i = 1:length(animals) %train the models
    animals{i}
    encodingrecs{i}
    ridgeModel_stateEncoding(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_stateShuff(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_choiceShuff(cPath,animals{i},encodingrecs{i},glmFile,[]);
end

parfor i = 1:length(encodingrecs)
    state(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlystate.mat');
    stateshuffle(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_stateshuffle.mat');
    choice(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlychoice.mat');
    choiceshuffle(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_choiceshuffle.mat');
end

%% boxplot comparing state to choice and rewardv
x = [choice;reward;state]';
figure;
set(gca,'FontSize',18);
hold on;
cols = {'.r' '.b' '.g' '.c'};
plot(NaN,NaN,cols{1});
plot(NaN,NaN,cols{2});
plot(NaN,NaN,cols{3});
plot(NaN,NaN,cols{4});

boxplot(x);
ylim([0,.2]);
ylabel('cvR^2');
title('Average cvR^2 across cortex for different task variables');
xticklabels({'Choice','Reward','Engaged state'});

animalinds{1} = 1:length(mSM63recs);
animalinds{2} = animalinds{1}(end)+1 : animalinds{1}(end)+1+length(mSM64recs)-1;
animalinds{3} = animalinds{2}(end)+1 : animalinds{2}(end)+1+length(mSM65recs)-1;
animalinds{4} = animalinds{3}(end)+1 : animalinds{3}(end)+1+length(mSM66recs)-1;
for i = 1:4 %iterate thru animals
    
    x1 = ones(length(animalinds{i}),1);
    x2 = x1+1;
    x3 = x2+1;
    
    scatter(x1,choice(animalinds{i}),200,cols{i});
    scatter(x2,reward(animalinds{i}),200,cols{i});
    scatter(x3,state(animalinds{i}),200,cols{i});
end
legend('mSM63','mSM64','mSM65','mSM66');

%% Plot some individual variance maps - and compute or average
parfor i = 1:length(animals)
    variancemap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_onlystate.mat',[0 .2],"True");
    full_variancemap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_withstate.mat',[0 .2],"True");
    nostate_variancemap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_nostate.mat',[0 .2],"True");
end

%% Plot some averaged variance maps
meanvariance = squeeze(mean(variancemap,'omitnan'));

figure('units','normalized','outerposition',[0 0 1 1])
mapImg = imshow(meanvariance, [0 .2]);
colormap(mapImg.Parent,'inferno'); axis image; title('State single variable encoding model','FontSize',24);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Average cvR^2';
hcb.FontSize = 20

%% do the same for leave one out analysis
deltavariance = full_variancemap - nostate_variancemap;
meanvariance = squeeze(mean(deltavariance,'omitnan'));

figure;
mapImg = imshow(abs(meanvariance), [0 .0025]);
%mapImg = imshow(meanvariance, [-.001 .0001]);
colormap(mapImg.Parent,'inferno'); axis image; title('abs(deltaR) - state');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

figure;
mapImg = imshow(meanvariance, [-.001 .001]);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('deltaR - state');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';


%% Plot some individual activity maps
clear inds;
for i = 1:length(animals) %try a few different sessions
    Rec = encodingrecs{i};
    [~,inds{1},inds{2}] = getStateInds(cPath,animals{i},Rec,glmFile);
    plotActivationMap(cPath,animals{i},Rec,inds,['State ' Rec],{'Attentive trials','Bias trials'},[-.01 .01],"False");
end
%% Get data for some averaged activity maps
for i = 1:length(animals) %try a few different sessions
    Rec = encodingrecs{i};
    [~,inds{1},inds{2}] = getStateInds(cPath,animals{i},Rec,glmFile);
    out{i,:,:} = plotActivationMap(cPath,animals{i},Rec,inds,['State ' Rec],{'Attentive trials','Bias trials'},[-3 3],'True');
end
clear attend bias
for i = 1:length(out) %iterate thru animals
    for j = 1:5 %iterate thru trial periods
        attend(i,j,:,:) = out{i}{1,j}; %[animals, trial periods, x, y]
        bias(i,j,:,:) = out{i}{2,j};
    end
end

attendmean = squeeze(mean(attend,1,'omitnan')); %average over animals/sessions
biasmean = squeeze(mean(bias,1,'omitnan')); %average over animals/sessions
combo = cat(4,attendmean,biasmean);
%% plotting those
pltlegend = {'Engaged trials','Bias trials'};
fsize = 29
set(gca,'FontSize',fsize)
%plttitle = 'Activity map averaged over sessions';
plttitle = '';
clims = [-.01 .01];
figure('units','normalized','outerposition',[0 0 1 1],'PaperSize',[40 40])
%figure
for i = 1:2
    subplot(3,5,1+(i-1)*5);
    mapImg = imshow(squeeze(combo(1,:,:,i)), clims);
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
    if i == 1
        title('Baseline','FontSize',fsize);
    end
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    %hcb = colorbar;
    %hcb.Title.String = 'dF/F';
    ylabel(pltlegend{i},'FontSize',fsize);
    
    subplot(3,5,2+(i-1)*5);
    mapImg = imshow(squeeze(combo(2,:,:,i)), clims);
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
    if i == 1
        title('Trial Initiation','FontSize',fsize);
    end
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    %hcb = colorbar;
    %hcb.Title.String = 'dF/F';
    
    subplot(3,5,3+(i-1)*5);
    mapImg = imshow(squeeze(combo(3,:,:,i)), clims);
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
    if i == 1
        title('Stimulus','FontSize',fsize);
    end
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    %hcb = colorbar;
    %hcb.Title.String = 'dF/F';
    
    subplot(3,5,4+(i-1)*5);
    mapImg = imshow(squeeze(combo(4,:,:,i)), clims);
    colormap(mapImg.Parent,'colormap_blueblackred'); axis image;
    if i == 1
        title('Delay','FontSize',fsize);
    end
    set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
    %hcb = colorbar;
    %hcb.Title.String = 'dF/F';
    
    subplot(3,5,5+(i-1)*5);
    mapImg = imshow(squeeze(combo(5,:,:,i)), clims);
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
clims = [-.001 .001];
subplot(3,5,11);
mapImg = imshow(squeeze(combo(1,:,:,1) - combo(1,:,:,2)), clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Baseline');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
%hcb = colorbar;
%hcb.Title.String = 'dF/F';
ylabel('Difference','FontSize',fsize);

subplot(3,5,12);
mapImg = imshow(squeeze(combo(2,:,:,1) - combo(2,:,:,2)), clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Trial Initiation');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
%hcb = colorbar;
%hcb.Title.String = 'dF/F';

subplot(3,5,13);
mapImg = imshow(squeeze(combo(3,:,:,1) - combo(3,:,:,2)), clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Stimulus');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
%hcb = colorbar;
%hcb.Title.String = 'dF/F';

subplot(3,5,14);
mapImg = imshow(squeeze(combo(4,:,:,1) - combo(4,:,:,2)), clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Delay');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
%hcb = colorbar;
%hcb.Title.String = 'dF/F';

subplot(3,5,15);
mapImg = imshow(squeeze(combo(5,:,:,1) - combo(5,:,:,2)), clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; %title('Response');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'dF/F';
hcb.Position = hcb.Position + [0.01 0 0 0];
hcb.FontSize = fsize;
sgtitle(plttitle);

%% beta maps - full model

betac = 5e-4;
frames = {1:2};
clear out meanout
parfor i = 1:length(animals) %try a few different sessions
%parfor i = 1:4 %try a few different sessions
    [~,handle(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_allvarsaligned.mat',{'handleAttentive'},frames,[-betac betac],"True");
    [~,stim(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_allvarsaligned.mat',{'stimAttentive'},frames,[-betac betac],"True");
    [~,delay(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_allvarsaligned.mat',{'delayAttentive'},frames,[-betac betac],"True");
    [~,response(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_allvarsaligned.mat',{'responseAttentive'},frames,[-betac betac],"True");
end

meanhandle = mean(handle,3,'omitnan');
meanstim = mean(stim,3,'omitnan');
meandelay = mean(delay,3,'omitnan');
meanresponse = mean(response,3,'omitnan');

figure;
fsize = 15;
set(gca','FontSize',fsize);
clims = [-5e-4 5e-4];

subplot(1,4,1);
mapImg = imshow(meanhandle, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Trial Initiation','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.

subplot(1,4,2);
mapImg = imshow(meanstim, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Stimulus','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.

subplot(1,4,3);
mapImg = imshow(meandelay, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Delay','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.

subplot(1,4,4);
mapImg = imshow(meanresponse, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Beta weight';
hcb.Position = hcb.Position + [0.06 0 0 0];
hcb.FontSize = fsize;

%% beta maps - single variable model

betac = 5e-4;
frames = {1:2};
clear out meanout
parfor i = 1:length(animals) %try a few different sessions
%parfor i = 1:4 %try a few different sessions
    [~,handle(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_handlestate.mat',{'handleAttentive'},frames,[-betac betac],"True");
%    [~,handle(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_onlystate.mat',{'attentive'},frames,[-betac betac],"True");
    [~,stim(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_stimstate.mat',{'stimAttentive'},frames,[-betac betac],"True");
    [~,delay(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_delaystate.mat',{'delayAttentive'},frames,[-betac betac],"True");
    [~,response(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_responsestate.mat',{'responseAttentive'},frames,[-betac betac],"True");
end

meanhandle = mean(handle,3,'omitnan');
meanstim = mean(stim,3,'omitnan');
meandelay = mean(delay,3,'omitnan');
meanresponse = mean(response,3,'omitnan');

figure;
fsize = 15;
set(gca','FontSize',fsize);
clims = [-5e-3 5e-3];

subplot(1,4,1);
mapImg = imshow(meanhandle, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Trial Initiation','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.

subplot(1,4,2);
mapImg = imshow(meanstim, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Stimulus','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.

subplot(1,4,3);
mapImg = imshow(meandelay, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Delay','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.

subplot(1,4,4);
mapImg = imshow(meanresponse, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Beta weight';
hcb.Position = hcb.Position + [0.06 0 0 0];
hcb.FontSize = fsize;



%% beta maps - handle grab for sanity

betac = 5e-4;
frames = {22:23};
clear out meanout
parfor i = 1:length(animals) %try a few different sessions
%parfor i = 1:4 %try a few different sessions
    [~,handle(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_allvarsaligned.mat',{'lGrab'},frames,[-betac betac],"True");
    [~,handle2(:,:,i),~] = plotBetas(animals{i},encodingrecs{i},'allaudio_allvarsaligned.mat',{'rGrab'},frames,[-betac betac],"True");
    [nose(:,:,i),~,~] = plotBetas(animals{i},encodingrecs{i},'allaudio_allvarsaligned.mat',{'nose'},frames,[-betac betac],"True");
end

meanhandle = mean(handle,3,'omitnan');
meanhandle2 = mean(handle2,3,'omitnan');
meannose = mean(nose,3,'omitnan');

figure;
fsize = 15;
set(gca','FontSize',fsize);
clims = [-1e-4 1e-4];

subplot(1,3,1);
mapImg = imshow(meanhandle, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Left Handle Grab','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Beta weight';
hcb.Position = hcb.Position + [0.06 0 0 0];
hcb.FontSize = fsize;

subplot(1,3,2);
mapImg = imshow(meanhandle2, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Right Handle Grab','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Beta weight';
hcb.Position = hcb.Position + [0.06 0 0 0];
hcb.FontSize = fsize;

clims = [-2e-4 2e-4];
subplot(1,3,3);
mapImg = imshow(meannose, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Sniffing','FontSize',fsize);
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Beta weight';
hcb.Position = hcb.Position + [0.06 0 0 0];
hcb.FontSize = fsize;

%% Plot some scatter plots of average activity in different regions
load('C:\Data\churchland\ridgeModel\allenDorsalMapSM.mat');
uniqueanimals = unique(animals);
animalrecs = {mSM63recs, mSM64recs, mSM65recs, mSM66recs};
cols = {'r','b','g','c'};
labels = {'baseline','initiation','stimulus','delay','response'};

taskvar = "State";
region = 5;
trialperiod = 3;


fprintf('\nRunning region %i, (%s) for %s variable in %s period. \n',region,dorsalMaps.labels{region},convertStringsToChars(taskvar),labels{trialperiod});
figure;hold on;
for i = 1:length(uniqueanimals)
    scatterAnimal(cPath,uniqueanimals{i},animalrecs{i},glmFile,region,cols{i},taskvar,trialperiod);
end
legend('mSM63','mSM64','mSM65','mSM66','');
refline(1,0);
titlestring = ['Average activity for ' dorsalMaps.labels{region} ...
    '. Task variable: ' convertStringsToChars(taskvar) '. Trial period: ' labels{trialperiod}];
title(titlestring);
xlabel('Engaged trials');
ylabel('Bias trials');


%% Plot some PSTH's for some regions
%try 7,9,11: primary somatosensory area, mouth, nose, unassigned
load('C:\Data\churchland\ridgeModel\allenDorsalMapSM.mat');
figureleg = cell(1,14);
figureleg(1,:) = {''};
figureleg{5} = 'Attentive state';
figureleg{10} = 'Biased state';

region = 5
for i = 1:4
    Rec = encodingrecs{i};
    [~,inds{1},inds{2}] = getStateInds(cPath,animals{i},Rec,glmFile);
    %    plotRegionPSTH(cPath,animals{i},Rec,inds,7,dorsalMaps.labels(7),figureleg);
    %     plotRegionPSTH(cPath,animals{i},Rec,inds,13,dorsalMaps.labels(13),figureleg);
    plotRegionPSTH(cPath,animals{i},Rec,inds,region,dorsalMaps.labels(region),figureleg,"False");
    %     plotRegionPSTH(cPath,animals{i},Rec,inds,19,dorsalMaps.labels(19),figureleg);
end

%% Average PSTH over sessions

region = 5

dorsalMaps.labels(region)
for i = 1:length(animals)
    Rec = encodingrecs{i}
    [~,inds{1},inds{2}] = getStateInds(cPath,animals{i},Rec,glmFile);
    [movies(i,:),eventframes] = plotRegionPSTH(cPath,animals{i},Rec,inds,region,dorsalMaps.labels(region),figureleg,"True");
end

attend = [movies{:,1}];
bias = [movies{:,2}];

%plot
figure;
cols = {'r','b','g'};

stdshade(attend',.2,cols{1},[],6,[1],[]); %plot trial averaged activity
hold on;
stdshade(bias',.2,cols{2},[],6,[1],[]); %plot trial averaged activity

xline(eventframes);
title(plttitle);
ylabel('dF/F');
xline(eventframes);
legend(pltlegend);


%% Plot decoder - choice
parfor i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [Mdl{i},accuracy(i,:),betas(:,:,:,i),Vc(i)] = logisticModel_choice(cPath,animals{i},encodingrecs{i},10);
end
parfor i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [~,accuracyshuff(i,:),~,~] = logisticModel_choiceshuff(cPath,animals{i},encodingrecs{i},10);
end

segframes = Vc(1).segFrames; clear Vc;
cols = {'r','b','g'};
figure
stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
stdshade(accuracyshuff,.2,cols{2},[],6,[1],[]); %plot average accuracy
xline(segframes);
ylim([.4 1]);
yline(.5);
trialperiod = 5;

segframes = [1 segframes];
avginds = segframes(trialperiod):segframes(trialperiod+1);
meanbetas = squeeze(mean(betas,4,'omitnan')); %betas are [xpix,ypix,frames,animals]
periodbetas = meanbetas(:,:,avginds);
trialperiodmean = squeeze(mean(periodbetas,3,'omitnan'));

clims = [-.0005 .0005];
figure
mapImg = imshow(trialperiodmean, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response period decoder weights');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Mean beta weight';

%% state
parfor i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [Mdl{i},accuracy(i,:),betas(:,:,:,i),Vc(i)] = logisticModel_state(cPath,animals{i},encodingrecs{i},glmFile,10);
end
parfor i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [~,accuracyshuff(i,:),~,~] = logisticModel_stateshuff(cPath,animals{i},encodingrecs{i},glmFile,10);
end

segframes = Vc(1).segFrames; clear Vc;
cols = {'r','b','g'};
figure
stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
stdshade(accuracyshuff,.2,cols{2},[],6,[1],[]); %plot average accuracy
xline(segframes);
ylim([.4 1]);

trialperiod = 5;

segframes = [1 segframes];
avginds = segframes(trialperiod):segframes(trialperiod+1);
meanbetas = squeeze(mean(betas,4,'omitnan')); %betas are [xpix,ypix,frames,animals]
periodbetas = meanbetas(:,:,avginds);
trialperiodmean = squeeze(mean(periodbetas,3,'omitnan'));

clims = [-.0005 .0005];
figure
mapImg = imshow(trialperiodmean, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response period decoder weights');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Mean beta weight';

%% Plot p values over pixels


%% Encoding model separated by state
for i = 1:length(encodingrecs)
    fulla(i) = getRSquaredNew(animals{i},encodingrecs{i},'attentive_allaudio_fullmodel.mat');
    sponta(i) = getRSquaredNew(animals{i},encodingrecs{i},'attentive_allaudio_onlyspontmotor.mat');
    opa(i) = getRSquaredNew(animals{i},encodingrecs{i},'attentive_allaudio_onlyopmotor.mat');
    taskvara(i) = getRSquaredNew(animals{i},encodingrecs{i},'attentive_allaudio_onlytaskvars.mat');
    nosponta(i) = getRSquaredNew(animals{i},encodingrecs{i},'attentive_allaudio_nospontmotor.mat');
    noopa(i) = getRSquaredNew(animals{i},encodingrecs{i},'attentive_allaudio_noopmotor.mat');
    notaskvara(i) = getRSquaredNew(animals{i},encodingrecs{i},'attentive_allaudio_notaskvars.mat');
    
    fullb(i) = getRSquaredNew(animals{i},encodingrecs{i},'biased_allaudio_fullmodel.mat');
    spontb(i) = getRSquaredNew(animals{i},encodingrecs{i},'biased_allaudio_onlyspontmotor.mat');
    opb(i) = getRSquaredNew(animals{i},encodingrecs{i},'biased_allaudio_onlyopmotor.mat');
    taskvarb(i) = getRSquaredNew(animals{i},encodingrecs{i},'biased_allaudio_onlytaskvars.mat');
    nospontb(i) = getRSquaredNew(animals{i},encodingrecs{i},'biased_allaudio_nospontmotor.mat');
    noopb(i) = getRSquaredNew(animals{i},encodingrecs{i},'biased_allaudio_noopmotor.mat');
    notaskvarb(i) = getRSquaredNew(animals{i},encodingrecs{i},'biased_allaudio_notaskvars.mat');
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
[a,b] = ttest(dopa,dopb)

[a,b] = ttest(dtaska,dtaskb)
[a,b] = ttest(dsponta,dspontb) %maybe?
[a,b] = ttest(dopa,dopb)

%% Get some maps
for i = 1:length(animals)
    afullmap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'attentive_allaudio_fullmodel.mat',[0 .2],"True");
    anotaskmap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'attentive_allaudio_notaskvars.mat',[0 .2],"True");
    anospontmap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'attentive_allaudio_nospontmotor.mat',[0 .2],"True");
    
    bfullmap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'biased_allaudio_fullmodel.mat',[0 .2],"True");
    bnotaskmap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'biased_allaudio_notaskvars.mat',[0 .2],"True");
    bnospontmap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'biased_allaudio_nospontmotor.mat',[0 .2],"True");
end

% Plot some averaged variance maps
afullavg = squeeze(mean(afullmap,1,'omitnan'));
bfullavg = squeeze(mean(bfullmap,1,'omitnan'));

adtaskavg = squeeze(mean(afullmap - anotaskmap,1,'omitnan'));
adspontavg = squeeze(mean(afullmap - anospontmap,1,'omitnan'));
bdtaskavg = squeeze(mean(bfullmap - bnotaskmap,1,'omitnan'));
bdspontavg = squeeze(mean(bfullmap - bnospontmap,1,'omitnan'));

figure;
subplot(1,3,1)
mapImg = imshow(adspontavg, [0 .3]);
colormap(mapImg.Parent,'inferno'); axis image; title('deltaR2 - attentive trials');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,2)
mapImg = imshow(bdspontavg, [0 .3]);
colormap(mapImg.Parent,'inferno'); axis image; title('deltaR2 - biased trials');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

subplot(1,3,3)
mapImg = imshow(adspontavg - bdspontavg, [-.05 .05]);
colormap(mapImg.Parent,'inferno'); axis image; title('deltaR2 - difference');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';


%% Functions

