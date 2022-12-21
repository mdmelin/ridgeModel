clc;clear all;close all;
%% Get the animals and sessions
addpath('C:\Data\churchland\ridgeModel\Max_Analysis')

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'};
glmFile = 'allaudio_detection.mat';
method = 'cutoff';

mintrialnum = 20; %the minimum number of trials per state to be included in plotting
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data


%% Toy example showing that the shuffle drops R2 to zero
% for i = 1:length(animals)
%     for j = 1:length(sessiondates{i})
%         fprintf('\nRunning for %s, %s.\n\n',animals{i},sessiondates{i}{j});
%         runRidge_fullAndShuffle(cPath,animals{1},sessiondates{1}{1},glmFile);
%     end
% end


%% Retrain models over different states
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fprintf('\nRunning for %s, %s.\n\n',animals{i},sessiondates{i}{j});
        runRidge_overStates(cPath,animals{i},sessiondates{i}{j},glmFile);
    end
end
%% IN THE FUTURE, TEST WITH DOING REWARD EQUALIZATION LATER (LINE 150 IN RETURN DESIGN MATRIX CODE)

%% Now plot those results

counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fulla(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'fullA.mat');
        sponta(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'spontA.mat');
        opa(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'operantA.mat');
        taskvara(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'taskA.mat');
        nosponta(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'nospontA.mat');
        noopa(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'nooperantA.mat');
        notaskvara(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'notaskA.mat');

        fullb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'fullB.mat');
        spontb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'spontB.mat');
        opb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'operantB.mat');
        taskvarb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'taskB.mat');
        nospontb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'nospontB.mat');
        noopb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'nooperantB.mat');
        notaskvarb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'notaskB.mat');

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


%exportgraphics(gcf,'C:\Data\churchland\PowerpointsPostersPresentations\SFN2022/FridayUpdate\encodingmodel\fullcvr.pdf');

%% now shuffle the state labels
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fprintf('\nRunning for %s, %s.\n\n',animals{i},sessiondates{i}{j});
        runRidge_overStates_shuffletrials(cPath,animals{i},sessiondates{i}{j},glmFile); %shuffle state labels randomly
    end
end

%%
runRidge_overStates_shuffletrials(cPath,animals{4},sessiondates{4}{5},glmFile); %shuffle state labels randomly

%% plot that
counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fulla(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SfullA.mat');
        sponta(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SspontA.mat');
        opa(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SoperantA.mat');
        taskvara(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'StaskA.mat');
        nosponta(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SnospontA.mat');
        noopa(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SnooperantA.mat');
        notaskvara(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SnotaskA.mat');

        fullb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SfullB.mat');
        spontb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SspontB.mat');
        opb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SoperantB.mat');
        taskvarb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'StaskB.mat');
        nospontb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SnospontB.mat');
        noopb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SnooperantB.mat');
        notaskvarb(counter,:) = returnVarianceMovie(animals{i},sessiondates{i}{j},'SnotaskB.mat');

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
