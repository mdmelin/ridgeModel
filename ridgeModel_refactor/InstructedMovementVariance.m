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
        runRidge_singleInstructedMovements(cPath,animals{i},sessiondates{i}{j},glmPath);
    end
end
diary off

%% get the data
fileprefix = '';
counter = 1;
opmotorlabels = {'lGrab','lGrabRel','rGrab','rGrabRel','lLick','rLick'};

for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fulla(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullA.mat']);
        lGraba(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'lGrabA.mat']);
        nolGraba(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nolGrabA.mat']);
        rGraba(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rGrabA.mat']);
        norGraba(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norGrabA.mat']);
        lLicka(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'lLickA.mat']);
        nolLicka(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nolLickA.mat']);
        rLicka(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rLickA.mat']);
        norLicka(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norLickA.mat']);

        fullb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullB.mat']);
        lGrabb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'lGrabB.mat']);
        nolGrabb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nolGrabB.mat']);
        rGrabb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rGrabB.mat']);
        norGrabb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norGrabB.mat']);
        lLickb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'lLickB.mat']);
        nolLickb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nolLickB.mat']);
        rLickb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'rLickB.mat']);
        norLickb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'norLickB.mat']);
        
        
        counter = counter + 1;
        fprintf('\ncounter is %i\n',counter);
    end
end

dlGraba = fulla - nolGraba;
drGraba = fulla - norGraba;
dlLicka = fulla - nolLicka;
drLicka = fulla - norLicka;

dlGrabb = fullb - nolGrabb;
drGrabb = fullb - norGrabb;
dlLickb = fullb - nolLickb;
drLickb = fullb - norLickb;


%% plot the data
Adata = {fulla, lGraba, rGraba, lLicka, rLicka, dlGraba, drGraba, dlLicka, drLicka};
Bdata = {fullb, lGrabb, rGrabb, lLickb, rLickb, dlGrabb, drGrabb, dlLickb, drLickb};
titles = {'full model cvR2','left grab cvR2','right grab cvR2','left lick cvR2','right lick cvR2','left grab deltaR2','right grab deltaR2','left lick deltaR2','right lick deltaR2'};

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



