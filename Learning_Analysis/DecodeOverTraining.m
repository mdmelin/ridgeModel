% Code for exploring choice/stimulus in early learning vs late learning
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
addpath('C:\Data\churchland\ridgeModel\smallStuff');
%% get sessions for mice - parallel
clear all;
cPath = 'X:\Widefield';
animals = {'mSM63','mSM64','mSM65','mSM66'};
%animals = {'mSM63','mSM64','mSM65'}; %delete this
%animals = {'CSP22','CSP23','CSP38'};
modality = 'Choice';
glmFile = 'allaudio_detection.mat';
%glmFile = 'allaudio2.mat';

%animals = {'mSM63'}; %first fully self performed session is July 3 for mSM63.

clear dates modalities
parfor i = 1:length(animals)
    [sessiondates{i},modalities{i}] = pythonGetSessionDates(cPath,animals{i});
end

for i = 1:length(animals) %this for loop grabs only audio sessions
    temp = sessiondates{i};
    sessiondates{i} = temp(modalities{i} == 2);
    clear temp;
end

%sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %delete this


%======================================================

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
clear accuracy accuracyshuff betas cvAcc cvAcc_shuff beta_all;
load('C:\Data\churchland\ridgeModel\segFrames.mat');
cols = {'r','b','g'};

for i = 1:length(animals)
    clear mdldate cvAcc beta_all Vc
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

    trialperiod = 4 % plot from one trial epoch
    trialsplit = 10 %grab the first and last N sessions
    clims = [-.001 .001];
    
    [~, ~, ~, ~, Vc] = loadLogisticModel(cPath,animals{i},sessiondates{i}(j),'Choice',false); %this is just to get segFrames
    %segframes = Vc(1).segFrames;clear Vc;
    segframes = [1 segframes];

    figure
    stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
    stdshade(accuracy(end-trialsplit+1:end,:),.2,cols{2},[],6,[1],[]); %plot average accuracy
    xline(segframes);
    ylim([.4 1]);
    yline(.5);
    title('Choice decoder accuracy')
    legend('',['First ' num2str(trialsplit) ' sessions'],'',['Last ' num2str(trialsplit) ' sessions']);

    
    avginds = segframes(trialperiod):segframes(trialperiod+1);
    earlybetas = betas(:,:,avginds,1:trialsplit); %Get early and late sessions, and proper trial period. Betas are [xpix,ypix,frames,sessions]
    latebetas = betas(:,:,avginds,end-trialsplit+1:end);
    earlymean = mean(earlybetas,4,'omitnan'); %average over trials
    latemean = mean(latebetas,4,'omitnan');
    earlymean = mean(earlymean,3,'omitnan'); %average over time
    latemean = mean(latemean,3,'omitnan');
    
    figure;
    subplot(1,3,1)
    plotHeatmap(earlymean, clims,'Choice decode - early sessions','Beta weight',[]);
    subplot(1,3,2)
    plotHeatmap(latemean, clims,'Choice decode - late sessions','Beta weight',[]);
    subplot(1,3,3)
    plotHeatmap(latemean - earlymean, clims,'Choice decode - late minus early','Beta weight',[]);

end



%% now look at CSTR mice, for this i need to figure out the trial alignment code first (segFrames)


