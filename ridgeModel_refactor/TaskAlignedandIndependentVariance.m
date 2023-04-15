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

for i = 1:length(animals)
    parfor j = 1:length(sessiondates{i})
        fprintf('\nRunning for %s, %s.\n\n',animals{i},sessiondates{i}{j});
        runRidge_taskIndependentVariance(cPath,animals{i},sessiondates{i}{j},glmPath);
    end
end

%% get the data

fileprefix = '';

allmotorlabels = {{'lGrab','lGrabRel','rGrab','rGrabRel'},{'lLick','rLick'},{'piezoAnalog','piezoDigital','piezoMoveAnalog','piezoMoveDigital','piezoMoveHiDigital'},{'whiskAnalog','whiskDigital','whiskHiDigital'},{'noseAnalog','noseDigital','noseHiDigital'},{'fastPupilAnalog','fastPupilDigital','fastPupilHiDigital','slowPupil'},{'faceAnalog','faceDigital','faceHiDigital'},{'bodyAnalog','bodyDigital','bodyHiDigital'},{'Move','bhvVideo'}};
for i = 1:length(allmotorlabels)
    Afilenames{i} = [fileprefix strjoin(allmotorlabels{i}, '_') 'plustaskA'];
    Bfilenames{i} = [fileprefix strjoin(allmotorlabels{i}, '_') 'plustaskA'];
    singleVarAfilenames{i} = [fileprefix strjoin(allmotorlabels{i}, '_') 'A'];
    singleVarBfilenames{i} = [fileprefix strjoin(allmotorlabels{i}, '_') 'B'];
    figureTitles{i} = strjoin(allmotorlabels{i}, '_');
end

taskIndependentVarianceA = []; taskDependentVarianceA = [];
taskIndependentVarianceB = []; taskDependentVarianceB = [];
for k = 1:length(Afilenames)
    counter = 1;
    for i = 1:length(animals)
        for j = 1:length(sessiondates{i})
            a(counter,:) = returnVariance(cPath, animals{i},sessiondates{i}{j}, Afilenames{k});
            b(counter,:) = returnVariance(cPath, animals{i},sessiondates{i}{j}, Bfilenames{k});
            singleVara(counter,:) = returnVariance(cPath, animals{i},sessiondates{i}{j}, singleVarAfilenames{k});
            singleVarb(counter,:) = returnVariance(cPath, animals{i},sessiondates{i}{j}, singleVarBfilenames{k});
            taska(counter,:) = returnVariance(cPath, animals{i},sessiondates{i}{j}, 'taskA');
            taskb(counter,:) = returnVariance(cPath, animals{i},sessiondates{i}{j}, 'taskB');

            counter = counter + 1;
            fprintf('\ncounter is %i\n',counter);
        end
    end
    taskIndependentVarianceA = [taskIndependentVarianceA, a - taska];
    taskIndependentVarianceB = [taskIndependentVarianceB, b - taskb];
    taskDependentVarianceA = [taskDependentVarianceA, singleVara - (a - taska)];
    taskDependentVarianceB = [taskDependentVarianceB, singleVarb - (b - taskb)];
end

%% plotting

figureTitles = {'handles','licks','piezo','whisk','nose','pupil','face','body','video and videoME'};



onevec = ones(size(taskDependentVarianceA(:,1),1),1);
twovec = onevec.*2;

for i = 1:size(taskDependentVarianceA,2)
    figure; hold on;
    title(figureTitles{i})
    scatter(onevec,taskDependentVarianceA(:,i))
    scatter(twovec,taskDependentVarianceB(:,i))
    parallelcoords([taskDependentVarianceA(:,i),taskDependentVarianceB(:,i)])
    ylabel('Task Dependent Variance')
    xlim([0 3])
    xticks([1 2])
    xticklabels({'Engaged','Disengaged'})

    figure; hold on;
    title(figureTitles{i})
    scatter(onevec,taskIndependentVarianceA(:,i))
    scatter(twovec,taskIndependentVarianceB(:,i))
    parallelcoords([taskIndependentVarianceA(:,i),taskIndependentVarianceB(:,i)])
    ylabel('Task Independent Variance')
    xlim([0 3])
    xticks([1 2])    
    xticklabels({'Engaged','Disengaged'})


end
%% saving
FolderName = ('C:\Users\mmelin\Downloads\f');   % using my directory
FigList = findobj(allchild(0), 'flat', 'Type', 'figure');
for iFig = 1:length(FigList)
    FigHandle = FigList(iFig);
    FigName   = num2str(get(FigHandle, 'Number'));
    set(0, 'CurrentFigure', FigHandle);
    %   saveas(FigHandle, strcat(FigName, '.png'));
    saveas(FigHandle, fullfile(FolderName,strcat(FigName, '.png'))); % specify the full path
end

