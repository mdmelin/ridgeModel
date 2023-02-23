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
        runRidge_singleMoveVariables(cPath,animals{i},sessiondates{i}{j},glmPath);
    end
end
diary off

%% get the data
fileprefix = '';
counter = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fulla(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullA.mat']);
        piezoa(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'piezoA.mat']);
        nopiezoa(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nopiezoA.mat']);
        whiska(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'whiskA.mat']);
        nowhiska(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nowhiskA.mat']);
        nosea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'noseA.mat']);
        nonosea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nonoseA.mat']);
        pupila(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'pupilA.mat']);
        nopupila(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nopupilA.mat']);
        facea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'faceA.mat']);
        nofacea(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nofaceA.mat']);
        bodya(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'bodyA.mat']);
        nobodya(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nobodyA.mat']);
        videoa(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'videoA.mat']);
        novideoa(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'novideoA.mat']);

        fullb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'fullB.mat']);
        piezob(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'piezoB.mat']);
        nopiezob(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nopiezoB.mat']);
        whiskb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'whiskB.mat']);
        nowhiskb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nowhiskB.mat']);
        noseb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'noseB.mat']);
        nonoseb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nonoseB.mat']);
        pupilb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'pupilB.mat']);
        nopupilb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nopupilB.mat']);
        faceb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'faceB.mat']);
        nofaceb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nofaceB.mat']);
        bodyb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'bodyB.mat']);
        nobodyb(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'nobodyB.mat']);
        videob(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'videoB.mat']);
        novideob(counter,:) = returnVarianceMovie(cPath, animals{i},sessiondates{i}{j}, [fileprefix 'novideoB.mat']);

        counter = counter + 1;
        fprintf('\ncounter is %i\n',counter);
    end
end

dpiezoa = fulla - nopiezoa;
dwhiska = fulla - nowhiska;
dnosea = fulla - nonosea;
dpupila = fulla - nopupila;
dfacea = fulla - nofacea;
dbodya = fulla - nobodya;
dvideoa = fulla - novideoa;

dpiezob = fullb - nopiezob;
dwhiskb = fullb - nowhiskb;
dnoseb = fullb - nonoseb;
dpupilb = fullb - nopupilb;
dfaceb = fullb - nofaceb;
dbodyb = fullb - nobodyb;
dvideob = fullb - novideob;
%%
Adata = {fulla, piezoa, whiska, nosea, pupila, facea, bodya, videoa, dpiezoa, dwhiska, dnosea, dpupila, dfacea, dbodya, dvideoa};
Bdata = {fullb, piezob, whiskb, noseb, pupilb, faceb, bodyb, videob, dpiezob, dwhiskb, dnoseb, dpupilb, dfaceb, dbodyb, dvideob};
titles = {'full model cvR2','piezo cvR2','whisk cvR2','nose cvR2','pupil cvR2','face cvR2','body cvR2','video cvR2','deltaR2 piezo','deltaR2 whisk','deltaR2 nose','deltaR2 pupil','deltaR2 face','deltaR2 body','deltaR2 video'};
%% plot the data
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

