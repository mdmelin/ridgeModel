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
%% check alignment
% [vidA,bhvA,goodtrialsA] = alignvideo2behavior(cPath,animals{1},sessiondates{1}{1},10:14); %[x,y,z,frames,trials]
% generateVideo('C:\Data\churchland\temp1',vidA.cam1,2);


%% Now let's look at states
count = 1;
for i = 1:length(sessiondates)
    for j = 1:length(sessiondates{i})
        [inds, attendinds,biasinds,Y, postprobs_sorted, correct] = getStateInds(cPath,animals{i},sessiondates{i}{j},'cutoff',glmFile,dualcase);
        [~,maxstate] = max(postprobs_sorted,[],1);
        correct = smoothdata(correct,2,'movmean',correctSmoothWindow);
        a = find(correct > .85);
        b = find(correct < .75);
        if length(a) > length(b)
        a = a(randperm(length(a),length(b)));
        else
        b = b(randperm(length(b),length(a)));
        end

        if length(a) > mintrials
            fprintf('\nRunning %s, %s\n',animals{i},sessiondates{i}{j});
            [vidA,bhvA,goodtrialsA] = alignvideo2behavior(cPath,animals{i},sessiondates{i}{j},a,1); %[x,y,z,frames,trials]
            [vidB,bhvB,goodtrialsB] = alignvideo2behavior(cPath,animals{i},sessiondates{i}{j},b,1); %[x,y,z,frames,trials]
        else
            continue
        end

        segFrames = [1 vidA.segFrames];
        clim1 = [0 20]; clim2 = [-10 10];figure;
        sgtitle([num2str(animals{i}) ', ' num2str(sessiondates{i}{j}) ': ' num2str(length(a)) ' trials per state.']);
        titles = {'Baseline','Initiation','Stimulus','Delay','Response'};

        for trialperiod = 1:5
            print(num2str(trialperiod))
            A = vidA.cam(:,:,segFrames(trialperiod):segFrames(trialperiod+1)-1,:); % [x,y,frames,trials]
            B = vidB.cam(:,:,segFrames(trialperiod):segFrames(trialperiod+1)-1,:);

            Ame = abs(diff(A,[],3));
            Bme = abs(diff(B,[],3));

            A1avg = mean(Ame,[3 4],'omitnan'); %average over trials and time
            B1avg = mean(Bme,[3 4],'omitnan');

            width = .3;
            %             figure;
            %             histogram(A1avg,'BinWidth',width); hold on;
            %             histogram(B1avg,'BinWidth',width);



            subplot(3,5,trialperiod); title('Hi-performance trials')
            imagesc(A1avg,clim1);
            colormap(gca,'inferno')
            title(titles(trialperiod));
            axis('square');set(gca,'XTick',[], 'YTick', [])
            if trialperiod == 1
                ylabel('High Performance')
            end
            if trialperiod == 5
                cb=colorbar;
                cb.Position = cb.Position + [.07,-.03, .002, .06];
                cb.Label.String = 'Motion Energy';
            end


            subplot(3,5,trialperiod + 5); title('Lo-performance trials')
            imagesc(B1avg,clim1);
            colormap(gca,'inferno')
            axis('square');set(gca,'XTick',[], 'YTick', [])
            if trialperiod == 1
                ylabel('Low Performance')
            end
            if trialperiod == 5
                cb=colorbar;
                cb.Position = cb.Position + [.07,-.03, .002, .06];
                cb.Label.String = 'Motion Energy';
            end

            subplot(3,5,trialperiod + 10); title('Difference')
            imagesc(A1avg - B1avg,clim2);
            colormap(gca,'colormap_blueblackred')
            axis('square');set(gca,'XTick',[], 'YTick', [])
            if trialperiod == 1
                ylabel('Difference')
            end
            if trialperiod == 5
                cb=colorbar;
                cb.Position = cb.Position + [.07,-.03, .002, .06];
                cb.Label.String = 'Motion Energy Difference';
            end
            %exportgraphics(gcf,['C:\Data\churchland\PowerpointsPostersPresentations\SFN2022\MotionEnergy_visualization\' num2str(count) '.pdf']);
            Amean(:,:,trialperiod,count) = A1avg;
            Bmean(:,:,trialperiod,count) = B1avg;




        end
        count = count + 1;
    end
end

diff = Amean - Bmean;
Amean2 = mean(Amean,4);
Bmean2 = mean(Bmean,4);
diffmean = mean(diff,4);

figure;
clim1 = [0 20]; clim2 = [-10 10];figure; sgtitle('Average')
for trialperiod = 1:5

    subplot(3,5,trialperiod); title('Engaged trials')
    imagesc(Amean2(:,:,trialperiod),clim1);
    colormap(gca,'inferno')
    axis('square');set(gca,'XTick',[], 'YTick', [])
    if trialperiod == 1
        ylabel('Biased')
    end
    if trialperiod == 5
        cb=colorbar;
        cb.Position = cb.Position + [.07,-.03, .002, .06];
        cb.Label.String = 'Motion Energy';
    end

    subplot(3,5,trialperiod + 5); title('Biased trials')
    imagesc(Bmean2(:,:,trialperiod),clim1);
    colormap(gca,'inferno')
    axis('square');set(gca,'XTick',[], 'YTick', [])
    if trialperiod == 1
        ylabel('Biased')
    end
    if trialperiod == 5
        cb=colorbar;
        cb.Position = cb.Position + [.07,-.03, .002, .06];
        cb.Label.String = 'Motion Energy';
    end

    subplot(3,5,trialperiod + 10); title('Difference')
    imagesc(diffmean(:,:,trialperiod),clim2);
    colormap(gca,'colormap_blueblackred')
    axis('square');set(gca,'XTick',[], 'YTick', [])
    if trialperiod == 1
        ylabel('Difference')
    end
    if trialperiod == 5
        cb=colorbar;
        cb.Position = cb.Position + [.07,-.03, .002, .06];
        cb.Label.String = 'Motion Energy Difference';
    end
    %exportgraphics(gcf,['C:\Data\churchland\PowerpointsPostersPresentations\SFN2022\MotionEnergy_visualization\avg.pdf']);
end



