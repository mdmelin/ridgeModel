clc;clear all;close all
%% load variables
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

%% Train encoding models
%parpool('local',16);
parfor i = 1:length(animals)
    animals{i}
    encodingrecs{i}
    ridgeModel_stateEncoding(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_stateShuff(cPath,animals{i},encodingrecs{i},glmFile,[]);
end

%% get r squared values
parfor i = 1:length(encodingrecs)
    state(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlystate.mat');
    stateshuffle(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_shuffstate.mat');
    
    choice(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlychoice.mat');
    choiceshuffle(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_shuffchoice.mat');
    
    reward(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlyreward.mat');
    rewardshuffle(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_shuffreward.mat');
    
    prevchoice(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_onlyprevchoice.mat');
    prevchoiceshuffle(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_shuffprevchoice.mat');
end

%% boxplot comparing state to choice and rewardv
x = [state;stateshuffle;choice;choiceshuffle;reward;rewardshuffle;prevchoice;prevchoiceshuffle]';
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
title('Average cvR^2 across cortex for different task variables - single variable');
xticklabels({'State','Stateshuff','Choice','Choiceshuff','Reward','Rewardshuff','Prevchoice','Prevchoiceshuff'});

animalinds{1} = 1:length(mSM63recs);
animalinds{2} = animalinds{1}(end)+1 : animalinds{1}(end)+1+length(mSM64recs)-1;
animalinds{3} = animalinds{2}(end)+1 : animalinds{2}(end)+1+length(mSM65recs)-1;
animalinds{4} = animalinds{3}(end)+1 : animalinds{3}(end)+1+length(mSM66recs)-1;
for i = 1:4 %iterate thru animals
    
    x1 = ones(length(animalinds{i}),1);
    x2 = x1+1;
    x3 = x2+1;
    x4 = x3+1;
    x5 = x4+1;
    x6 = x5+1;
    x7 = x6+1;
    x8 = x7+1;
    
    
    scatter(x1,state(animalinds{i}),200,cols{i});
    scatter(x2,stateshuffle(animalinds{i}),200,cols{i});
    scatter(x3,choice(animalinds{i}),200,cols{i});
    scatter(x4,choiceshuffle(animalinds{i}),200,cols{i});
    scatter(x5,reward(animalinds{i}),200,cols{i});
    scatter(x6,rewardshuffle(animalinds{i}),200,cols{i});
    scatter(x7,prevchoice(animalinds{i}),200,cols{i});
    scatter(x8,prevchoiceshuffle(animalinds{i}),200,cols{i});
end
legend('mSM63','mSM64','mSM65','mSM66');

%% do the same, but pixel by pixel
clim = [0 .2];
parfor i = 1:length(encodingrecs)
    state(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_onlystate.mat',clim,"True");
    stateshuffle(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_shuffstate.mat',clim,"True");
    
    choice(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_onlychoice.mat',clim,"True");
    choiceshuffle(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_shuffchoice.mat',clim,"True");
    
    reward(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_onlyreward.mat',clim,"True");
    rewardshuffle(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_shuffreward.mat',clim,"True");
    
    prevchoice(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_onlyprevchoice.mat',clim,"True");
    prevchoiceshuffle(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_shuffprevchoice.mat',clim,"True");
end

statediff = nanmean(state - stateshuffle,[2 3]);
choicediff = nanmean(choice - choiceshuffle,[2 3]);
rewarddiff = nanmean(reward - rewardshuffle,[2 3]);
prevchoicediff = nanmean(prevchoice - prevchoiceshuffle,[2 3]);

x = [statediff,choicediff,rewarddiff,prevchoicediff];
figure;
set(gca,'FontSize',18);
hold on;
cols = {'.r' '.b' '.g' '.c'};
plot(NaN,NaN,cols{1});
plot(NaN,NaN,cols{2});
plot(NaN,NaN,cols{3});
plot(NaN,NaN,cols{4});

boxplot(x);
ylim([-.1,.1]);
ylabel('cvR^2');
title('Pixel-wise deltaR^2');
xticklabels({'State','Choice','Reward','Prevchoice'});
yline(0);
animalinds{1} = 1:length(mSM63recs);
animalinds{2} = animalinds{1}(end)+1 : animalinds{1}(end)+1+length(mSM64recs)-1;
animalinds{3} = animalinds{2}(end)+1 : animalinds{2}(end)+1+length(mSM65recs)-1;
animalinds{4} = animalinds{3}(end)+1 : animalinds{3}(end)+1+length(mSM66recs)-1;

for i = 1:4 %iterate thru animals
    
    x1 = ones(length(animalinds{i}),1);
    x2 = x1+1;
    x3 = x2+1;
    x4 = x3+1;
    
    scatter(x1,statediff(animalinds{i}),200,cols{i});
    scatter(x2,choicediff(animalinds{i}),200,cols{i});
    scatter(x3, rewarddiff(animalinds{i}),200,cols{i});
    scatter(x4,prevchoicediff(animalinds{i}),200,cols{i});
end
legend('mSM63','mSM64','mSM65','mSM66');
%% Now lets do this shuffle, but with the full model. First train the models
%parpool('local',16);
for i = 1:length(animals)
    animals{i}
    encodingrecs{i}
    ridgeModel_stateEncoding(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_stateShuffFullDeleteme(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_choiceShuffFullDeleteme(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_rewardShuffFullDeleteme(cPath,animals{i},encodingrecs{i},glmFile,[]);
end
%% now plot results
clim = [0 .9];
parfor i = 1:length(encodingrecs)
    full(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_fullmodel.mat',clim,"True");
    stateshuffle(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_fullmodel_stateshuff.mat',clim,"True");
    choiceshuffle(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_fullmodel_choiceshuff.mat',clim,"True");
    rewardshuffle(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_fullmodel_rewardshuff.mat',clim,"True");
end

statediff = nanmean(full - stateshuffle,[2 3]);
choicediff = nanmean(full - choiceshuffle,[2 3]);
rewarddiff = nanmean(full - rewardshuffle,[2 3]);

x = [statediff,choicediff,rewarddiff];
figure;
set(gca,'FontSize',18);
hold on;
cols = {'.r' '.b' '.g' '.c'};
plot(NaN,NaN,cols{1});
plot(NaN,NaN,cols{2});
plot(NaN,NaN,cols{3});
plot(NaN,NaN,cols{4});

boxplot(x);
ylim([-.05,.05]);
ylabel('cvR^2');
title('Pixel-wise deltaR^2 - full model');
xticklabels({'State','Choice','Reward',});
yline(0);
animalinds{1} = 1:length(mSM63recs);
animalinds{2} = animalinds{1}(end)+1 : animalinds{1}(end)+1+length(mSM64recs)-1;
animalinds{3} = animalinds{2}(end)+1 : animalinds{2}(end)+1+length(mSM65recs)-1;
animalinds{4} = animalinds{3}(end)+1 : animalinds{3}(end)+1+length(mSM66recs)-1;

for i = 1:4 %iterate thru animals
    
    x1 = ones(length(animalinds{i}),1);
    x2 = x1+1;
    x3 = x2+1;
    
    scatter(x1,statediff(animalinds{i}),200,cols{i});
    scatter(x2,choicediff(animalinds{i}),200,cols{i});
    scatter(x3, rewarddiff(animalinds{i}),200,cols{i});
end
legend('mSM63','mSM64','mSM65','mSM66');
%% Now check cvR2 for some different trial periods

%% Train aligned encoding models
%parpool('local',16);
clc;clear all;
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

parfor i = 1:length(animals)
    animals{i}
    encodingrecs{i}
    ridgeModel_stateEncodingAligned(cPath,animals{i},encodingrecs{i},glmFile,[]);
end

parfor i = 1:length(animals)
    animals{i}
    encodingrecs{i}
    ridgeModel_handleRewardShuffDeleteme(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_stimRewardShuffDeleteme(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_delayRewardShuffDeleteme(cPath,animals{i},encodingrecs{i},glmFile,[]);
    ridgeModel_responseRewardShuffDeleteme(cPath,animals{i},encodingrecs{i},glmFile,[]);
end



%% plot reward single variable models
clear h s d r h2 s2 d2 r2
clim = [0 .9];
parfor i = 1:length(encodingrecs)
    h(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_handlereward.mat');
    s(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_stimreward.mat');
    d(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_delayreward.mat');
    r(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_responsereward.mat');

    h2(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_handlerewardshuff.mat');
    s2(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_stimrewardshuff.mat');
    d2(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_delayrewardshuff.mat');
    r2(i) = getRSquaredNew(animals{i},encodingrecs{i},'allaudio_responserewardshuff.mat');
end

x = [h;h2;s;s2;d;d2;r;r2]';
figure;
set(gca,'FontSize',18);
hold on;
cols = {'.r' '.b' '.g' '.c'};
plot(NaN,NaN,cols{1});
plot(NaN,NaN,cols{2});
plot(NaN,NaN,cols{3});
plot(NaN,NaN,cols{4});

boxplot(x);
ylim([0,.15]);
ylabel('cvR^2');
title('cvR^2 - REWARD single variable models');
xticklabels({'Handle','Handleshuff','Stim','Stimshuff','Delay','Delayshuff','Response','Responseshuff'});
yline(0);
animalinds{1} = 1:length(mSM63recs);
animalinds{2} = animalinds{1}(end)+1 : animalinds{1}(end)+1+length(mSM64recs)-1;
animalinds{3} = animalinds{2}(end)+1 : animalinds{2}(end)+1+length(mSM65recs)-1;
animalinds{4} = animalinds{3}(end)+1 : animalinds{3}(end)+1+length(mSM66recs)-1;

for i = 1:4 %iterate thru animals
    
    x1 = ones(length(animalinds{i}),1);
    x2 = x1+1;
    x3 = x2+1;
    x4 = x3+1;
    x5 = x4+1;
    x6 = x5+1;
    x7 = x6+1;
    x8 = x7+1;
    
    scatter(x1, h(animalinds{i}),200,cols{i});
    scatter(x2, h2(animalinds{i}),200,cols{i});
    scatter(x3, s(animalinds{i}),200,cols{i});
    scatter(x4, s2(animalinds{i}),200,cols{i});
    scatter(x5, d(animalinds{i}),200,cols{i});
    scatter(x6, d2(animalinds{i}),200,cols{i});
    scatter(x7, r(animalinds{i}),200,cols{i});
    scatter(x8, r2(animalinds{i}),200,cols{i});
end
legend('mSM63','mSM64','mSM65','mSM66');

%% plot reward full model deltar2
clear h s d r h2 s2 d2 r2
clim = [0 .9];
parfor i = 1:length(encodingrecs)
    full(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_cogvarsaligned.mat',clim,"True");

    h2(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_fullhandlerewardshuff.mat',clim,"True");
    s2(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_fullstimrewardshuff.mat',clim,"True");
    d2(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_fulldelayrewardshuff.mat',clim,"True");
    r2(i,:,:) = plotRSquared(animals{i},encodingrecs{i},'allaudio_fullresponserewardshuff.mat',clim,"True");
end

handlediff = nanmean(full - h2,[2 3]);
stimdiff = nanmean(full - s2,[2 3]);
delaydiff = nanmean(full - d2,[2 3]);
responsediff = nanmean(full - r2,[2 3]);

x = [handlediff,stimdiff,delaydiff,responsediff];
figure;
set(gca,'FontSize',18);
hold on;
cols = {'.r' '.b' '.g' '.c'};
plot(NaN,NaN,cols{1});
plot(NaN,NaN,cols{2});
plot(NaN,NaN,cols{3});
plot(NaN,NaN,cols{4});

boxplot(x);
ylim([-.005,.005]);
ylabel('cvR^2');
title('Pixel-wise deltaR^2 - Full model, shuffle REWARD in different periods');
xticklabels({'Handle','Stim','Delay','Response'});
yline(0);
animalinds{1} = 1:length(mSM63recs);
animalinds{2} = animalinds{1}(end)+1 : animalinds{1}(end)+1+length(mSM64recs)-1;
animalinds{3} = animalinds{2}(end)+1 : animalinds{2}(end)+1+length(mSM65recs)-1;
animalinds{4} = animalinds{3}(end)+1 : animalinds{3}(end)+1+length(mSM66recs)-1;

for i = 1:4 %iterate thru animals
    
    x1 = ones(length(animalinds{i}),1);
    x2 = x1+1;
    x3 = x2+1;
    x4 = x3+1;
    
    scatter(x1, handlediff(animalinds{i}),200,cols{i});
    scatter(x2, stimdiff(animalinds{i}),200,cols{i});
    scatter(x3, delaydiff(animalinds{i}),200,cols{i});
    scatter(x4, responsediff(animalinds{i}),200,cols{i});
end
legend('mSM63','mSM64','mSM65','mSM66');


















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

%% Functions

