addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
addpath('C:\Data\churchland\ridgeModel\smallStuff');
clc;clear all;close all;
%% get sessions for mice - parallel
cPath = 'X:\Widefield';
%animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat';
%animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'alldisc.mat'; 
animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; %CSP32 missing transparams
modality = 'State';

sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %delete this

%% Decode desired modality - train the models
% Need to ask simon about segInd parameters for CSP mice to train those
tic
for i = 1:length(animals) % MAKE SURE TO CHANGE ALIGN2BEHAVIOR!!!
    parfor j = 1:length(sessiondates{i})
        logisticModel(cPath,animals{i},sessiondates{i}{j},glmFile,10,modality,false,true); %train the model
        logisticModel(cPath,animals{i},sessiondates{i}{j},glmFile,10,modality,true,true); %train the shuffled distribution
    end
end
toc

%% Decode - look at EMX mice
load('C:\Data\churchland\ridgeModel\segFrames.mat');
cols = {'r','b','g'};

for i = 1:length(animals)
    clear mdldate cvAcc beta_all Vc accuracy accuracyshuff betas cvAcc cvAcc_shuff beta_all;
    parfor j = 1:length(sessiondates{i}) %load models in parallel for speed...
        fprintf('\n%s',sessiondates{i}{j});
        [mdldate{j}, ~, cvAcc{j}, beta_all{j}, Vc{j}] = loadLogisticModel(cPath,animals{i},sessiondates{i}(j),modality,false);
        [~, ~, cvAcc_shuff{j}, ~, ~] = loadLogisticModel(cPath,animals{i},sessiondates{i}(j),modality,true);

    end
    count = 1;
    clear betas
    for j = 1:length(sessiondates{i}) % remove empty data here for better averaging
        if ~isempty(cvAcc{j})
            accuracy(count,:) = cvAcc{j};
            accuracyshuff(count,:) = cvAcc_shuff{j};
            betas(:,:,:,count) = beta_all{j}; %betas are [xpix,ypix,frames,animals]
            toby(count,:) = Vc{j}.segFrames;
            count = count + 1;
            segframes = Vc{j}.segFrames;
        end
    end
    clear Vc
    % plot data for each mouse here over training

    trialperiod = 5 % plot from one trial epoch
    clims = [-.001 .001];

    [~, ~, ~, ~, Vc] = loadLogisticModel(cPath,animals{i},sessiondates{i}(j),'Choice',false); %this is just to get segFrames
    %segframes = Vc(1).segFrames;clear Vc;
    segframes = [1 segframes];

    figure
    stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
    stdshade(accuracyshuff,.2,cols{2},[],6,[1],[]); %plot average accuracy

    xline(segframes);
    ylim([.4 1]);
    yline(.5);
    title([modality ' decoder accuracy']);
    legend('',[modality ' decode'],'',[modality ' shuffled']);


    avginds = segframes(trialperiod):segframes(trialperiod+1);
    betas = betas(:,:,avginds,:); 
    trialmean = mean(betas,4,'omitnan'); %average over trials
    finalmean = mean(trialmean,3,'omitnan'); %average over time

    figure;
    plotHeatmap(finalmean, clims,[modality ' decode'],'Beta weight',[]);

end



%% now look at CSTR mice, for this i need to figure out the trial alignment code first (segFrames)


