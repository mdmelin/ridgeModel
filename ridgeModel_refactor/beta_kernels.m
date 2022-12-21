clc;clear all;close all;
%% Get the animals and sessions
addpath('C:\Data\churchland\ridgeModel\Max_Analysis')

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'};
glmFile = 'allaudio_detection.mat';
method = 'cutoff';

mintrialnum = 20; %the minimum number of trials per state to be included in plotting
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

%% Retrain models over different states
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        fprintf('\nRunning for %s, %s.\n\n',animals{i},sessiondates{i}{j});
        runRidge_overStates(cPath,animals{i},sessiondates{i}{j},glmFile);
    end
end
%% IN THE FUTURE, TEST WITH DOING REWARD EQUALIZATION LATER (LINE 150 IN RETURN DESIGN MATRIX CODE)


%% now look at some beta kernels for one session

REG = 'lGrab';
PREFRAMES = 5;
POSTFRAMES = 10;
clims = [-.001 .001];
cmap = 'colormap_blueblackred';

[regLabels, regZeroFrames, kernels, U] = returnBetaKernels(animals{1},sessiondates{1}{1},'fullA.mat');
transParams = loadTransParams(cPath, animals{1}, sessiondates{1}{1});
regind = find(strcmpi(regLabels,REG));
regbetas = kernels{regind};
reconstructed1 = unSVDalign2allen(regbetas',U,transParams,[],false);
reconstructed1(isnan(reconstructed1)) = 0;

[regLabels, regZeroFrames, kernels, U] = returnBetaKernels(animals{1},sessiondates{1}{1},'fullB.mat');
transParams = loadTransParams(cPath, animals{1}, sessiondates{1}{1});
regind = find(strcmpi(regLabels,REG));
regbetas = kernels{regind};
reconstructed2 = unSVDalign2allen(regbetas',U,transParams,[],false);
reconstructed2(isnan(reconstructed2)) = 0;

combo = horzcat(reconstructed1(:,:,1:end-4),reconstructed2(:,:,:));
sliceViewer(combo,'Colormap',colormap(cmap),'DisplayRange',clims);



% for i = 1:size(reconstructed,3)
%     figure
%     plotHeatmap(reconstructed(:,:,i),clims,['frame ' num2str(i)],'Beta weight','colormap_blueblackred',[]);
% end




