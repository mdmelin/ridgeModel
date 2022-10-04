% We know that there is a heatmap difference that is state dependent. So lets
% plot this heatmat, then get some PSTH's, and finally, revisit the results
% of the encoding model.
clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions


%Need to fix the trial lengths for CSP mice!!!!!

cPath = 'X:\Widefield'; animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%cPath = 'Y:\Widefield'; animals = {'CSP22','CSP23','CSP38'}; glmFile = 'allaudio_detection.mat'; %32 not working for some reason
%cPath = 'Y:\Widefield'; animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; %CSP32 missing transparams


method = 'cutoff';
mintrialnum = 25; %the minimum number of trials per state to be included in plotting
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

%% Plot avg activity map
inds = {NaN,NaN};
for i = 1:length(animals) %try a few different sessions
    fprintf('\nrunning %s\n',animals{i});
    for j = 1:length(sessiondates{i})
        Rec = sessiondates{i}{j};
        [~,a,b] = getStateInds(cPath,animals{i},Rec,method,glmFile,dualcase);
        nt = num2str(length(a));
        if length(a) < mintrialnum %skip if too few trials
            out{i,j,:,:} = [];
        else
            out{i,j,:,:} = plotActivationMap(cPath,animals{i},Rec,{a,b},[animals{i} ' ' Rec ': ' nt ' trials per state'],{'Attentive trials','Bias trials'},clims,true);
        end
    end
end
clear attend bias
loc = 1; %use this to squish animals and sessions into one dimension
for i = 1:length(animals) %iterate thru animals
    for j = 1:length(sessiondates{i})
        if ~isempty(out{i,j})
            for k = 1:5 %iterate thru trial periods

                attend(loc,k,:,:) = out{i,j}{1,k}; %[animals, trial periods, x, y]
                bias(loc,k,:,:) = out{i,j}{2,k};
            end
            loc = loc + 1;
        end

    end
end

attendmean = squeeze(mean(attend,1,'omitnan')); %average over animals/sessions
biasmean = squeeze(mean(bias,1,'omitnan')); %average over animals/sessions
combo = cat(4,attendmean,biasmean);

% plotting

figure('units','normalized','outerposition',[0 0 1 1],'PaperSize',[40 40]);
%figure
fsize = 29;
clims = [-.0075 .0075];
subplot(1,2,1);
plotHeatmap(squeeze(attendmean(4,:,:)), clims, 'Engaged Trials', [], [], fsize) %delay period
subplot(1,2,2);
plotHeatmap(squeeze(biasmean(4,:,:)), clims, 'Disengaged Trials', 'dF/F', [], fsize) %delay period

%% load the allen map, select regions to plot
clear z zname
t = load('C:\Data\churchland\ridgeModel\allenDorsalMapSM.mat');
map = t.dorsalMaps.areaMap;
figure
imagesc(map)
[x,y] = getpts;
x=int64(x);y=int64(y);

for i = 1:length(x)
    z(i) = map(y(i),x(i));
    zname{i} = t.dorsalMaps.labelsSplit(z(i));
end
zname = arrayfun(@string, zname);
fprintf('\nRegion to extract: %s',zname);
close

%% plot PSTHs
mintrials = 15; %min trials per state
A = []; B = [];
for i = 1:length(z)
    for j = 1:length(animals)
        for k = 1:length(sessiondates{j})
            [~,inds{1},inds{2}] = getStateInds(cPath,animals{j},sessiondates{j}{k},method,glmFile,dualcase);

            if length(inds{1}) < mintrialnum
                fprintf('\nSkipping!\n');
                continue
            end

            [temp,eventframes,time] = plotRegionPSTH(cPath,animals{j},sessiondates{j}{k},inds,z(i),zname(i),'pltlegend',false,true);
            A = [A,temp{1}]; B = [B,temp{2}]; %[nframes, ntrials]
        end
    end
    figure;hold on; title(zname(i))
    stdshade(A',.2,'red',time,6,eventframes,[]);
    stdshade(B',.2,'blue',time,6,eventframes,[]);
    legend('','','','','','Engaged trials','','','','','','Biased trials');
    xlabel('Time (s)');
    ylabel('\DeltaF/F');
    set(gca,'TickDir','out');
    set(gcf,'Units','inches');screenposition = get(gcf,'Position');
    set(gcf,'PaperPosition',[0 0 screenposition(3:4)],'PaperSize',[screenposition(3:4)]);

    savepath = 'C:\Data\churchland\PowerpointsPostersPresentations\Anne R01 Grant';
    saveas(gcf, [savepath filesep 'emx_' char(zname(i)) '.pdf']);

    exportgraphics(figure(i), [savepath filesep 'output.pdf'], 'Append', true);

end