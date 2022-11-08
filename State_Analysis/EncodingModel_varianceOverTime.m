
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
    for j = 1:length(sessiondates{i})
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
        fulla(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_fullmodel.mat');
        sponta(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlyspontmotor.mat');
        opa(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlyopmotor.mat');
        taskvara(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_onlytaskvars.mat');
        nosponta(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_nospontmotor.mat');
        noopa(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_noopmotor.mat');
        notaskvara(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'attentive_allaudio_detection_notaskvars.mat');

        fullb(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'biased_allaudio_detection_fullmodel.mat');
        spontb(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlyspontmotor.mat');
        opb(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlyopmotor.mat');
        taskvarb(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'biased_allaudio_detection_onlytaskvars.mat');
        nospontb(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'biased_allaudio_detection_nospontmotor.mat');
        noopb(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'biased_allaudio_detection_noopmotor.mat');
        notaskvarb(counter,:) = temporary_return_R(animals{i},sessiondates{i}{j},'biased_allaudio_detection_notaskvars.mat');

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

%% plotting 
time = linspace(0,5,size(fulla,2));
time = time-time(30);

figure; hold on;
title('Full Model')
stdshade(fulla,.2,'red',time,6,[30],[]);
stdshade(fullb,.2,'blue',time,6,[30],[]);
ylabel('cvR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Task Variables')
stdshade(taskvara,.2,'red',time,6,[30],[]);
stdshade(taskvarb,.2,'blue',time,6,[30],[]);
ylabel('cvR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Operant Motor Variables')
stdshade(opa,.2,'red',time,6,[30],[]);
stdshade(opb,.2,'blue',time,6,[30],[]);
ylabel('cvR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Spontaneous Motor Variables')
stdshade(sponta,.2,'red',time,6,[30],[]);
stdshade(spontb,.2,'blue',time,6,[30],[]);
ylabel('cvR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})



figure; hold on;
title('Task Variables')
stdshade(dtaska,.2,'red',time,6,[30],[]);
stdshade(dtaskb,.2,'blue',time,6,[30],[]);
ylabel('deltaR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Operant Motor Variables')
stdshade(dopa,.2,'red',time,6,[30],[]);
stdshade(dopb,.2,'blue',time,6,[30],[]);
ylabel('deltaR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Spontaneous Motor Variables')
stdshade(dsponta,.2,'red',time,6,[30],[]);
stdshade(dspontb,.2,'blue',time,6,[30],[]);
ylabel('deltaR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})






%exportgraphics(gcf,'C:\Data\churchland\PowerpointsPostersPresentations\SFN2022\encoding_model.pdf');
%exportgraphics(gcf,'C:\Data\churchland\PowerpointsPostersPresentations\SFN2022/FridayUpdate\encodingmodel\fullcvr.pdf');
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




