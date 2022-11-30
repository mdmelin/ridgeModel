clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% Get the animals and sessions

%%
recs = {'03-Jul-2018','04-Jul-2018','06-Jul-2018'};
filenames = {'X:\mSM63_DLC_Jul03_2018.mat','X:\mSM63_DLC_Jul04_2018.mat','X:\mSM63_DLC_Jul06_2018.mat'};
epoch = 'delay';
smooth = false;
shuffle = false;
load('X:\labelNames.mat');
Laterl_labels

label = 'Whisker_2';
%label = 'Nosetip';
epoch = 'response';


allme = []; allstate = [];
for i = 1:length(recs)
    [x,y,correct] = get_pupil(recs{i},filenames{i}, epoch);
    [x,y,correct] = get_DLC_position(recs{i},filenames{i}, epoch, label);
    correct = smoothdata(correct,2,'movmean',30);
    correct = correct(1:length(x));
    xmean = mean(x,2,'omitnan');
    ymean = mean(y,2,'omitnan');

    xmeansub = x - xmean;
    ymeansub = y - ymean;

    xm = abs(mean(xmeansub,1,'omitnan'));
    ym = abs(mean(xmeansub,1,'omitnan'));

    figure
    scatter(correct,xm);
    title('correct vs mean subtracted distance')

    xvar = var(xmeansub,[],1,'includenan');
    
    figure
    scatter(correct,xvar)
    title('correct vs variance');

end


%%
function [x,y,correct] = get_pupil(rec, filename, epoch)
[inds, attendinds,biasinds,~, postprobs_sorted, correct] = getStateInds('X:/Widefield','mSM63',rec,'cutoff','allaudio_detection.mat',true);
load('X:\labelNames.mat');
load(filename);
alllabels = DLC_Lateral.(epoch);
% This isn't perfect, the trial numbers don't quite match
for i = 1:size(alllabels,1)
    left = [alllabels(i,:,12); alllabels(i,:,13)]; %THESE ARE NOT THE PUPIL LABELS, they are the eye labels
    right = [alllabels(i,:,14); alllabels(i,:,15)];
    up = [alllabels(i,:,16); alllabels(i,:,17)];
    down = [alllabels(i,:,18); alllabels(i,:,19)];


    figure;hold on;
    scatter(down(1,:),down(2,:))
    scatter(up(1,:),up(2,:))
    scatter(left(1,:),left(2,:))
    scatter(right(1,:),right(2,:))
end
end


function [x,y,correct] = get_DLC_position(rec, filename, epoch, label)
[inds, attendinds,biasinds,~, postprobs_sorted, correct] = getStateInds('X:/Widefield','mSM63',rec,'cutoff','allaudio_detection.mat',true);
load('X:\labelNames.mat');
load(filename);
alllabels = DLC_Lateral.(epoch);
labelind = find(label == Laterl_labels);
% This isn't perfect, the trial numbers don't quite match
for i = 1:size(alllabels,1)
    x(:,i) = alllabels(i,:,labelind);
    y(:,i) = alllabels(i,:,labelind + 1);
end

end