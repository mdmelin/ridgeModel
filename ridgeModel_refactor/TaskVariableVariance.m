clc;clear all;close all;
%% Get the animals and sessions
addpath('C:\Data\churchland\ridgeModel\Max_Analysis')
addpath('C:\Data\churchland\ridgeModel\widefield')

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'};
%cPath = 'Y:\Widefield'; animals = {'CSP22','CSP23','CSP32','CSP38'};

glmPath = 'X:\Widefield\glm_hmm_models\global_model_map.mat';
%glmPath = 'X:\Widefield\glm_hmm_models\global_model_map_csp.mat';
sessiondates = getGlobalGLMHMMSessions(glmPath); %get sessions with GLM-HMM data

%% Retrain models over different states
diary on
%runRidge_overStates(cPath,'CSP22','23-Jun-2020',glmPath);

for i = 1:length(animals)
    parfor j = 1:length(sessiondates{i})
        fprintf('\nRunning for %s, %s.\n\n',animals{i},sessiondates{i}{j});
        runRidge_singleTaskVariables(cPath,animals{i},sessiondates{i}{j},glmPath);
    end
end
diary off

%% get the data
fileprefix = '';
counter = 1;
taskvarlabels = {'time', 'Choice','reward','handleSound','lfirstTacStim','lTacStim','rfirstTacStim','rTacStim','lfirstAudStim','lAudStim','rfirstAudStim','rAudStim','prevReward','prevChoice','nextChoice','water'};

for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fulla(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullA.mat']);
        timea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'timeA.mat']);
        notimea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'notimeA.mat']);
        choicea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'choiceA.mat']);
        nochoicea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nochoiceA.mat']);
        rewarda(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rewardA.mat']);
        norewarda(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norewardA.mat']);
        handlesounda(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'handleSoundA.mat']);
        nohandlesounda(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nohandleSoundA.mat']);
        lfirstAudStima(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'lfirstAudStimA.mat']);
        nolfirstAudStima(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nolfirstAudStimA.mat']);
        lAudStima(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'lAudStimA.mat']);
        nolAudStima(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nolAudStimA.mat']);
        rfirstAudStima(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rfirstAudStimA.mat']);
        norfirstAudStima(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norfirstAudStimA.mat']);
        rAudStima(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rAudStimA.mat']);
        norAudStima(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norAudStimA.mat']);
        prevRewarda(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'prevRewardA.mat']);
        noprevRewarda(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'noprevRewardA.mat']);
        prevChoicea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'prevChoiceA.mat']);
        noprevChoicea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'noprevChoiceA.mat']);
        watera(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'waterA.mat']);
        nowatera(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nowaterA.mat']);

        fullb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullB.mat']);
        timeb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'timeB.mat']);
        notimeb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'notimeB.mat']);
        choiceb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'choiceB.mat']);
        nochoiceb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nochoiceB.mat']);
        rewardb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rewardB.mat']);
        norewardb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norewardB.mat']);
        handlesoundb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'handleSoundB.mat']);
        nohandlesoundb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nohandleSoundB.mat']);
        lfirstAudStimb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'lfirstAudStimB.mat']);
        nolfirstAudStimb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nolfirstAudStimB.mat']);
        lAudStimb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'lAudStimB.mat']);
        nolAudStimb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nolAudStimB.mat']);
        rfirstAudStimb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rfirstAudStimB.mat']);
        norfirstAudStimb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norfirstAudStimB.mat']);
        rAudStimb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rAudStimB.mat']);
        norAudStimb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norAudStimB.mat']);
        prevRewardb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'prevRewardB.mat']);
        noprevRewardb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'noprevRewardB.mat']);
        prevChoiceb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'prevChoiceB.mat']);
        noprevChoiceb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'noprevChoiceB.mat']);
        waterb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'waterB.mat']);
        nowaterb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nowaterB.mat']);


        counter = counter + 1;
        fprintf('\ncounter is %i\n',counter);
    end
end

dtimea = fulla - notimea;
dchoicea = fulla - nochoicea;
drewarda = fulla - norewarda;
dhandlesounda = fulla - nohandlesounda;
dlfirstAudStima = fulla - nolfirstAudStima;
dlAudStima = fulla - nolAudStima;
dprevRewarda = fulla - noprevRewarda;
dprevChoicea = fulla - noprevChoicea;
dwatera = fulla - nowatera;


dtimeb = fullb - notimeb;
dchoiceb = fullb - nochoiceb;
drewardb = fullb - norewardb;
dhandlesoundb = fullb - nohandlesoundb;
dlfirstAudStimb = fullb - nolfirstAudStimb;
dlAudStimb = fullb - nolAudStimb;
dprevRewardb = fullb - noprevRewardb;
dprevChoiceb = fullb - noprevChoiceb;
dwaterb = fullb - nowaterb;

%% plot the data
Adata = {fulla, timea, choicea, rewarda, handlesounda, lfirstAudStima, lAudStima, prevRewarda, prevChoicea, watera, dtimea, dchoicea, drewarda, dhandlesounda, dlfirstAudStima, dlAudStima, dprevRewarda, dprevChoicea, dwatera};
Bdata = {fullb, timeb, choiceb, rewardb, handlesoundb, lfirstAudStimb, lAudStimb, prevRewardb, prevChoiceb, waterb, dtimeb, dchoiceb, drewardb, dhandlesoundb, dlfirstAudStimb, dlAudStimb, dprevRewardb, dprevChoiceb, dwaterb};

titles = {'full model cvR2', 'time','choice cvR2','reward cvR2','handlesound cvR2','lfirstaudstim cvR2','laudstim cvR2','prev reward cvR2','prev choice cvR2','water cvR2','time deltaR2','choice deltaR2','reward deltaR2','handlesound deltaR2','lfirstaudstim deltaR2','laudstim deltaR2','prevreward deltaR2','prevchoice deltaR2','water deltaR2'};

time = linspace(0,5,size(Adata{1},2));
time = time-time(30);

for i = 1:length(Adata)
    figure; hold on;
    title(titles{i})
    stdshade(Adata{i},.2,'red',time,6,[30],[]);
    stdshade(Bdata{i},.2,'blue',time,6,[30],[]);
    %ylabel('cvR^2');
    xlabel('Time from handle grab (s)')
    legend({'','','Engaged','','','Disengaged','','','',''})
end


