%% First thing: The GLM-HMM Results and Chaoqun's TIV data


%% train the encoding models
mSM63recs = {'09-Jul-2018','13-Jul-2018','16-Jul-2018','17-Jul-2018','18-Jul-2018','19-Jul-2018','20-Jul-2018'}; %mSM63
mSM64recs = {'24-Jul-2018','26-Jul-2018','27-Jul-2018'}; %,'25-Jul-2018' only has one state
mSM65recs = {'05-Jul-2018'}; %for mSM65, maybe put '28-Jun-2018',,'29-Jun-2018' ,'02-Jul-2018', back in
mSM66recs = {'27-Jun-2018','28-Jun-2018','29-Jun-2018','02-Jul-2018','04-Jul-2018','05-Jul-2018','11-Jul-2018','16-Jul-2018'};%for mSM66 add ,'30-Jun-2018' back in
%^these sessions are basically all of the audio discrimination sessions from these mice

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

for i = 1:length(animals)
    animals{i}
    encodingrecs{i}
    ridgeModel_3stateEncoding(cPath,animals{i},encodingrecs{i},glmFile,[]);
end

%% Get average variance explained by state
for i = 1:length(encodingrecs)
    state(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlystate.mat');
end
%% Plot some individual variance maps
for i = 1:length(animals)
    variancemap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_onlystate.mat',[0 .2],"True");
    full_variancemap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_withstate.mat',[0 .2],"True");
    nostate_variancemap(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_nostate.mat',[0 .2],"True");
end

%% Plot some averaged variance maps
meanvariance = squeeze(mean(variancemap,'omitnan'));

figure;
mapImg = imshow(meanvariance, [0 .2]);
colormap(mapImg.Parent,'inferno'); axis image; title('Mean state variance map - single variable model');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

%% do the same for leave one out analysis
deltavariance = full_variancemap - nostate_variancemap;
meanvariance = squeeze(mean(deltavariance,'omitnan'));

figure;
mapImg = imshow(meanvariance, [0 .2]);
colormap(mapImg.Parent,'inferno'); axis image; title('deltaR - state');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'cvR^2';

%% Plot some individual activity maps
clear inds;
for i = 1:4 %try a few different sessions
    Rec = encodingrecs{i};
    [~,inds{1},inds{2}] = getStateInds(cPath,animals{i},Rec,glmFile);
    plotActivationMap(cPath,animals{i},Rec,inds,['State ' Rec],{'Attentive trials','Bias trials'},[-3 3],"False");
end
%% Plot some averaged activity maps
for i = 1:length(animals) %try a few different sessions
    Rec = encodingrecs{i};
    [~,inds{1},inds{2}] = getStateInds(cPath,animals{i},Rec,glmFile);
    [handle(i,:),stim(i,:),delay(i,:),response(i,:)] = plotActivationMap(cPath,animals{i},Rec,inds,['State ' Rec],{'Attentive trials','Bias trials'},[-3 3],'True');
end

for i = 1:size(handle,1)
    handle2(:,:,i) = handle{i,1}; %attentive trials
    stim2(:,:,i) = stim{i,1};
    delay2(:,:,i) = delay{i,1};
    response2(:,:,i) = response{i,1};
    
    handle3(:,:,i) = handle{i,2}; %bias trials
    stim3(:,:,i) = stim{i,2};
    delay3(:,:,i) = delay{i,2};
    response3(:,:,i) = response{i,2};
end

hmean = mean(handle2,3,'omitnan');
smean = mean(stim2,3,'omitnan');
dmean = mean(delay2,3,'omitnan');
rmean = mean(response2,3,'omitnan');

hmean2 = mean(handle3,3,'omitnan');
smean2 = mean(stim3,3,'omitnan');
dmean2 = mean(delay3,3,'omitnan');
rmean2 = mean(response3,3,'omitnan');

handlemovies = {hmean,hmean2};
stimmovies = {smean,smean2};
delaymovies = {dmean,dmean2};
responsemovies = {rmean,rmean2};

%plotting
figure('units','normalized','outerposition',[0 0 1 1]);
pltlegend = {'Attentive trials','Bias trials'};plttitle = 'Activity map averaged over sessions';
clims = [-3 3];
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
clims = [-.5 .5];
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

%% Plot some PSTH's for some regions
%try 7,9,11: primary somatosensory area, mouth, nose, unassigned

figureleg = cell(1,14);
figureleg(1,:) = {''};
figureleg{5} = 'Attentive state';
figureleg{10} = 'Biased state';

for i = 1:4
    Rec = encodingrecs{i};
    [~,inds{1},inds{2}] = getStateInds(cPath,animals{i},Rec,glmFile);
    %    plotRegionPSTH(cPath,animals{i},Rec,inds,7,dorsalMaps.labels(7),figureleg);
    %     plotRegionPSTH(cPath,animals{i},Rec,inds,13,dorsalMaps.labels(13),figureleg);
    plotRegionPSTH(cPath,animals{i},Rec,inds,15,dorsalMaps.labels(15),figureleg,"False");
    %     plotRegionPSTH(cPath,animals{i},Rec,inds,19,dorsalMaps.labels(19),figureleg);
end

%% Average PSTH over sessions
for i = 1:length(animals)
    Rec = encodingrecs{i}
    [~,inds{1},inds{2}] = getStateInds(cPath,animals{i},Rec,glmFile);
    movies(i,:) = plotRegionPSTH(cPath,animals{i},Rec,inds,15,dorsalMaps.labels(15),figureleg,"True");
end

attend = [movies{:,1}];
bias = [movies{:,2}];

%plot
figure;
cols = {'r','b','g'};

stdshade(attend',.2,cols{1},[],6,[1],[]); %plot trial averaged activity
hold on;
stdshade(bias',.2,cols{2},[],6,[1],[]); %plot trial averaged activity

%xline(alVc.allinds);
title(plttitle);
ylabel('SDU''s');
legend(pltlegend);


%% Plot decoder - choice and state, try on cross validated data! 
for i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [Mdl{i},Yhat{i},accuracy(i,:),~,Vc] = logisticModel_choice(cPath,animals{i},encodingrecs{i},glmFile,15);
end
cols = {'r','b','g'};
figure
stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
xline(Vc.allinds);
ylim([.5 .9]);

meanbetas = mean(betas,3,'omitnan');

clims = [-.02 .02];
figure
mapImg = imshow(meanbetas, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Decoder weights');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Mean beta weight';


for i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [Mdl{i},Yhat{i},accuracy(i,:),~,Vc] = logisticModel_state(cPath,animals{i},encodingrecs{i},glmFile,20);
end
cols = {'r','b','g'};
figure
stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
xline(Vc.allinds);
ylim([.5 .9]);

meanbetas = mean(betas,3,'omitnan');

clims = [-.02 .02];
figure
mapImg = imshow(meanbetas, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Decoder weights');
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

function [inds, attendinds,biasinds] = getStateInds(cPath,Animal,Rec,glmFile)
Paradigm = 'SpatialDisc';
glmfile = [cPath filesep Animal filesep 'glm_hmm_models' filesep glmFile]; %Widefield data path

cPath = [cPath filesep Animal filesep Paradigm filesep Rec filesep]; %Widefield data path
bhvFile = dir([cPath filesep Animal '_' Paradigm '*.mat']);
load([cPath bhvFile(1).name],'SessionData'); %load behavior data
bhv = SessionData;clear SessionData;
load(glmfile,'posterior_probs','model_training_sessions','state_label_indices'); %load behavior data
model_training_sessions = num2cell(model_training_sessions,2); %convert to a cell for ease

sessionind = find(strcmp(model_training_sessions,Rec));%find the index of the session we want to pull latent states for
postprob_nonan = posterior_probs{sessionind}; %grab the proper session
nochoice = isnan(bhv.ResponseSide); %trials without choice. used for interpolation of latent state on NaN choice trials (GLMHMM doesn't predict for these trials)
counterind = 1;

for i = 1:length(nochoice) %this for loop adds nan's to the latent state array. The nans will ultimatel get discarded later since the encoding model doesn't use trials without choice.
    if ~nochoice(i) %if a choice was made
        postprob_withnan(i,:) = postprob_nonan(counterind,:); %just put the probabilities into the new array
        counterind = counterind + 1;
    else %if no choice was made
        postprob_withnan(i,:) = NaN; %insert a NaN to new array
    end
end
postprobs = postprob_withnan';
stateinds = str2num(state_label_indices); %stateinds tells us what dimension has what state, the first index of stateinds tells us the index of attentive state

postprobs_sorted = postprobs(stateinds,:); %permute the states so theyre in the correct indices


[~,state1hot] = max(postprobs_sorted,[],1);

useIdx = ~isnan(bhv.ResponseSide); %only use performed trials
inds = find(rateDisc_equalizeTrials(useIdx, state1hot == 1, bhv.ResponseSide == 1, inf, true)); %equalize state and L/R choices
attendinds = inds(state1hot(inds) == 1);
biasinds = inds(state1hot(inds) ~= 1);
end
