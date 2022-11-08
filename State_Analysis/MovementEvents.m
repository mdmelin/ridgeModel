% Look at total whisking
clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions
%cPath = 'V:\StateProjectCentralRepo\Widefield_Sessions';

animals = {'mSM63','mSM64','mSM65','mSM66'}; glmFile = 'allaudio_detection.mat'; cPath = 'X:\Widefield';

%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'allaudio_detection.mat'; cPath = 'Y:\Widefield'%32 not working for some reason
%animals = {'CSP22','CSP23','CSP38'}; glmFile = 'alldisc.mat'; cPath = 'Y:\Widefield' %CSP32 missing transparams
%animals = {'CSP22','CSP38'}; glmFile = 'alldisc.mat'; cPath = 'Y:\Widefield' %CSP32 missing transparams

method = 'cutoff';
mintrialnum = 20; %the minimum number of trials per state to be included in plotting
dualcase = true;
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

%%
amean = {};
bmean = {};
count = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        animals{i}
        sessiondates{i}{j}
        [out, labels] = ridgeModel_returnWhisks(cPath,animals{i},sessiondates{i}{j},glmFile,"attentive",[],false);
        [out2, labels2] = ridgeModel_returnWhisks(cPath,animals{i},sessiondates{i}{j},glmFile,"biased",[],false);
        if length(labels) > 0
            labelssave = labels;
        end
        for k = 1:length(labels)
            amean{count,k}= sum(out{k},'all') / size(out{k},1);
            bmean{count,k} = sum(out2{k},'all') / size(out2{k},1);
        end
        count = count + 1;
    end
end
%% plotting
amean_new = cell2mat(amean); %[sessions, bodyparts]
bmean_new = cell2mat(bmean); %[sessions, bodyparts]
nparts = size(amean_new,2);
labels = {'whisking events/trial SDU > .5','whisking events/trial SDU > 2','nose events/trial SDU > .5', ...
    'nose events/trial SDU > 2','piezo events/trial SDU > .5','piezo motion events/trial SDU > .5', ...
    'piezo motion events/trial SDU > 2','face events/trial SDU > .5','face events/trial SDU > 2'};

for i = 1:nparts
    figure; hold on; title(labels{i});
    plot([1 2],[amean_new(:,i) bmean_new(:,i)],'b-x');
    xlim([0 3]); xticks([1 2]); xticklabels({'Engaged','Disengaged'});
    ylabel('Average events/trial');
    [~,b(i)] = ttest(amean_new(:,i),bmean_new(:,i));
end


