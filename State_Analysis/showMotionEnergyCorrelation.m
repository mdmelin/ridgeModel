% Look at delay period movements
clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions
%cPath = 'V:\StateProjectCentralRepo\Widefield_Sessions';

animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat'; cPath = 'X:\Widefield';

%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'allaudio_detection.mat'; cPath = 'Y:\Widefield'%32 not working for some reason
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; cPath = 'Y:\Widefield' %CSP32 missing transparams
%animals = {'CSP22','CSP38'}; glmFile = 'alldisc.mat'; cPath = 'Y:\Widefield' %CSP32 missing transparams

method = 'cutoff';
mintrials = 20; %the minimum number of trials per state to be included in plotting
dualcase = 'reward';
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data
correctSmoothWindow = 30;


%% Plot correlations between pixel motion energy and performance
count = 1;
for i = 1:length(sessiondates)
    for j = 1:length(sessiondates{i})
        [inds, attendinds,biasinds,~, postprobs_sorted, correct] = getStateInds('X:/Widefield',animals{i},sessiondates{i}{j},'cutoff','allaudio_detection.mat',dualcase);
        correct = smoothdata(correct,2,'movmean',correctSmoothWindow);

        [~,maxstate] = max(postprobs_sorted,[],1);


        fprintf('\nRunning %s, %s\n',animals{i},sessiondates{i}{j});
        [vidA,bhvA,goodtrialsA] = alignvideo2behavior(cPath,animals{i},sessiondates{i}{j},1:length(correct),1); %[x,y,z,frames,trials]



        segFrames = [1 vidA.segFrames];
        clim1 = [-1 1]; figure;
        titles = {'Baseline','Initiation','Stimulus','Delay','Response'};

        for trialperiod = 1:5
            print(num2str(trialperiod))
            frames = vidA.cam(:,:,segFrames(trialperiod):segFrames(trialperiod+1)-1,:); % [x,y,frames,trials]

            motionEnergy = abs(diff(frames,[],3));

            motionEnergyAvg = squeeze(mean(motionEnergy,3,'omitnan')); %average over time
            clear motionEnergy
            for xpos = 1:size(motionEnergyAvg,1)
                for ypos = 1:size(motionEnergyAvg,2)
            [rtemp,ptemp] = corrcoef(squeeze(motionEnergyAvg(xpos,ypos,:)),correct,'rows','pairwise');
                R(xpos,ypos) = rtemp(1,2);
                P(xpos,ypos) = ptemp(1,2);
                end
            end

            subplot(1,5,trialperiod);
            imagesc(R,clim1);
            colormap(gca,'colormap_blueblackred')
            colorbar;
            title(titles(trialperiod));
            axis('square');
            set(gca,'XTick',[], 'YTick', [])
         
       
            %exportgraphics(gcf,['C:\Data\churchland\PowerpointsPostersPresentations\SFN2022\MotionEnergy_visualization\' num2str(count) '.pdf']);


        end
        count = count + 1;
    end
end

