clc;clear all;close all;
%% Get the animals and sessions
addpath('C:\Data\churchland\ridgeModel\Max_Analysis')
addpath('C:\Data\churchland\ridgeModel\widefield')

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'};
%cPath = 'Y:\Widefield'; animals = {'CSP22','CSP23','CSP32','CSP38'};

%glmFile = 'allaudio_detection.mat';
glmPath = 'X:\Widefield\glm_hmm_models\global_model_map.mat';
%glmPath = 'X:\Widefield\glm_hmm_models\global_model_map_csp.mat';
%sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data
sessiondates = getGlobalGLMHMMSessions(glmPath); %get sessions with GLM-HMM data

%% Retrain models over different states

%runRidge_overStates(cPath,'CSP22','23-Jun-2020',glmPath);

for i = 1:length(animals)
    parfor j = 1:length(sessiondates{i})
        fprintf('\nRunning for %s, %s.\n\n',animals{i},sessiondates{i}{j});
        runRidge_overStates(cPath,animals{i},sessiondates{i}{j},glmPath);
    end
end


%% get the data
fileprefix = '';
counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})

        if sum(ismember(mouse,'mSM')) == 3 %mSM Mice
            segIdx = [1 0.5 1.00 0.75 .75] %[baseline, handle, stim, delay, response] maximal duration of each segment in seconds, use this for EMX mice
        elseif sum(ismember(mouse,'CSP')) == 3 %CSP Mice
            segIdx = [1 0.5 1.00 0.4 .75] %testing
        end
        fulla(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullA.mat']);
        sponta(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'spontA.mat']);
        opa(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'operantA.mat']);
        taskvara(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'taskA.mat']);
        nosponta(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nospontA.mat']);
        noopa(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nooperantA.mat']);
        notaskvara(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'notaskA.mat']);

        fullb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullB.mat']);
        spontb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'spontB.mat']);
        opb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'operantB.mat']);
        taskvarb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'taskB.mat']);
        nospontb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nospontB.mat']);
        noopb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nooperantB.mat']);
        notaskvarb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'notaskB.mat']);

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
%plot(fulla,'r')
%plot(fullb,'b')
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
title('Instructed Motor Variables')
stdshade(opa,.2,'red',time,6,[30],[]);
stdshade(opb,.2,'blue',time,6,[30],[]);
ylabel('cvR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Uninstructed Motor Variables')
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
title('Instructed Motor Variables')
stdshade(dopa,.2,'red',time,6,[30],[]);
stdshade(dopb,.2,'blue',time,6,[30],[]);
ylabel('deltaR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Uninstructed Motor Variables')
stdshade(dsponta,.2,'red',time,6,[30],[]);
stdshade(dspontb,.2,'blue',time,6,[30],[]);
ylabel('deltaR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

%exportgraphics(gcf,'C:\Data\churchland\PowerpointsPostersPresentations\SFN2022/FridayUpdate\encodingmodel\fullcvr.pdf');

%% get the data - but now with better alignment
fileprefix = '';
NFRAMES = 75;
counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        
        if sum(ismember(animals{i},'mSM')) == 3 %mSM Mice
            segIdx = [1 0.5 1.00 0.75 .75] %[baseline, handle, stim, delay, response] maximal duration of each segment in seconds, use this for EMX mice
        elseif sum(ismember(animals{i},'CSP')) == 3 %CSP Mice
            segIdx = [1 0.5 1.00 0.4 .75] %testing
        end

        fulla(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullA.mat'], segIdx, NFRAMES);
        sponta(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'spontA.mat'], segIdx, NFRAMES);
        opa(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'operantA.mat'], segIdx, NFRAMES);
        taskvara(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'taskA.mat'], segIdx, NFRAMES);
        nosponta(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nospontA.mat'], segIdx, NFRAMES);
        noopa(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nooperantA.mat'], segIdx, NFRAMES);
        notaskvara(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'notaskA.mat'], segIdx, NFRAMES);

        fullb(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullB.mat'], segIdx, NFRAMES);
        spontb(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'spontB.mat'], segIdx, NFRAMES);
        opb(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'operantB.mat'], segIdx, NFRAMES);
        taskvarb(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'taskB.mat'], segIdx, NFRAMES);
        nospontb(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nospontB.mat'], segIdx, NFRAMES);
        noopb(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nooperantB.mat'], segIdx, NFRAMES);
        notaskvarb(counter,:) = returnRealignedVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'notaskB.mat'], segIdx, NFRAMES);

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
time = 1:size(fulla,2);
naninds = cumsum(floor(segIdx * 15));
naninds = naninds(1:end-1);


figure; hold on;
title('Full Model')
%plot(fulla,'r')
%plot(fullb,'b')
stdshade(fulla,.2,'red',time,6,naninds,[]);
stdshade(fullb,.2,'blue',time,6,naninds,[]);
ylabel('cvR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Task Variables')
stdshade(taskvara,.2,'red',time,6,naninds,[]);
stdshade(taskvarb,.2,'blue',time,6,naninds,[]);
ylabel('cvR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Instructed Motor Variables')
stdshade(opa,.2,'red',time,6,naninds,[]);
stdshade(opb,.2,'blue',time,6,naninds,[]);
ylabel('cvR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Uninstructed Motor Variables')
stdshade(sponta,.2,'red',time,6,naninds,[]);
stdshade(spontb,.2,'blue',time,6,naninds,[]);
ylabel('cvR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})



figure; hold on;
title('Task Variables')
stdshade(dtaska,.2,'red',time,6,naninds,[]);
stdshade(dtaskb,.2,'blue',time,6,naninds,[]);
ylabel('deltaR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Instructed Motor Variables')
stdshade(dopa,.2,'red',time,6,naninds,[]);
stdshade(dopb,.2,'blue',time,6,naninds,[]);
ylabel('deltaR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

figure; hold on;
title('Uninstructed Motor Variables')
stdshade(dsponta,.2,'red',time,6,naninds,[]);
stdshade(dspontb,.2,'blue',time,6,naninds,[]);
ylabel('deltaR^2');
xlabel('Time from handle grab (s)')
legend({'','','Engaged','','','Disengaged','','','',''})

