
clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; %CSP32 missing transparams


method = 'cutoff';
mintrialnum = 20; %the minimum number of trials per state to be included in plotting
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

%% rerun encoding model - general variable groups
for i = 1:length(animals)
    parfor j = 1:length(sessiondates{i})
        animals{i}
        sessiondates{i}{j}
        ridgeModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,"attentive",[], false);
        ridgeModel_sepByState(cPath,animals{i},sessiondates{i}{j},glmFile,"biased", [], false);
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

%% figures
figure;
t1 = ones(length(dopa),1);
t2 = t1*2;

subplot(2,3,1); hold on;
scatter(t1,taskvara);
scatter(t2,taskvarb);
title('Task Variables');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});
ylabel('cvR^2')

subplot(2,3,2); hold on;
scatter(t1,opa);
scatter(t2,opb);
title('Operant Movements');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});
ylabel('cvR^2')

subplot(2,3,3); hold on;
scatter(t1,sponta);
scatter(t2,spontb);
title('Spontaneous Movements');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});
ylabel('cvR^2')

subplot(2,3,4); hold on;
scatter(t1,dtaska);
scatter(t2,dtaskb);
title('Task Variables');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});
ylabel('deltaR^2')

subplot(2,3,5); hold on;
scatter(t1,dopa);
scatter(t2,dopb);
title('Operant Movements');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});
ylabel('deltaR^2')

subplot(2,3,6); hold on;
scatter(t1,dsponta);
scatter(t2,dspontb);
title('Spontaneous Movements');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});
ylabel('deltaR^2')

%exportgraphics(gcf,'C:\Data\churchland\PowerpointsPostersPresentations\SFN2022\encoding_model.pdf');

%% rerun encoding model - choice lick, and stim encoding
for i = 1:length(animals)
    parfor j = 1:length(sessiondates{i})
        animals{i}
        sessiondates{i}{j}
        ridgeModel_sepByState2(cPath,animals{i},sessiondates{i}{j},glmFile,"attentive",[], false);
        ridgeModel_sepByState2(cPath,animals{i},sessiondates{i}{j},glmFile,"biased", [], false);
    end
end
%%
counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fulla(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_fullmodel.mat');
        choicea(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_choice.mat');
        nochoicea(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_nochoice.mat');
        subchoicea(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_choiceopmotorspontmotor.mat');
        suba(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_opspontmotor.mat');
        nostima(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_noaudstim.mat');
        stima(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_lfirstaudstim.mat');
        substima(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_audstimopspontmotor.mat');
  
        nolicka(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_nolick.mat');
        licka(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_lick.mat');
        sublicka(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_opspontmotor2.mat');
        subnolicka(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_opspontmotor_nolick.mat');

        
  

        fullb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_fullmodel.mat');
        choiceb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_choice.mat');
        nochoiceb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_nochoice.mat');
        subchoiceb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_choiceopmotorspontmotor.mat');
        subb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_opspontmotor.mat');
        nostimb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_noaudstim.mat');
        stimb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_lfirstaudstim.mat');
        substimb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_audstimopspontmotor.mat');
  
        nolickb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_nolick.mat');
        lickb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_lick.mat');
        sublickb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_opspontmotor2.mat');
        subnolickb(counter) = getRSquaredNew(animals{i},sessiondates{i}{j},'biased_allaudio_detection_opspontmotor_nolick.mat');

        counter = counter + 1;
        fprintf('\ncounter is %i\n',counter);
    end
end
%%
figure;
t1 = ones(length(fulla),1);
t2 = t1*2;

subplot(2,3,1); hold on;
scatter(t1,fulla - nochoicea);
scatter(t2,fullb - nochoiceb);
title('choice deltaR2 - full model');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,2); hold on;
scatter(t1,subchoicea - suba);
scatter(t2,subchoiceb - subb);
title('choice deltaR2 - reduced model');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,3); hold on;
scatter(t1,choicea);
scatter(t2,choiceb);
title('choice cvR2');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,4); hold on;
scatter(t1,fulla - nostima);
scatter(t2,fullb - nostimb);
title('stim deltaR2 - full model');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,5); hold on;
scatter(t1,substima - suba);
scatter(t2,substimb - subb);
title('stim deltaR2 - reduced model');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(2,3,6); hold on;
scatter(t1,stima);
scatter(t2,stimb);
title('stim cvR2');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});


figure;
subplot(1,3,1); hold on;
scatter(t1,fulla - nolicka);
scatter(t2,fullb - nolickb);
title('lick deltaR2 - full model');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(1,3,2); hold on;
scatter(t1,sublicka - subnolicka);
scatter(t2,sublickb - subnolickb);
title('lick deltaR2 - reduced model');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});

subplot(1,3,3); hold on;
scatter(t1,licka);
scatter(t2,lickb);
title('lick cvR2');xlim([0 3]);
xticks([1 2]); xticklabels({'Engaged','Disengaged'});




