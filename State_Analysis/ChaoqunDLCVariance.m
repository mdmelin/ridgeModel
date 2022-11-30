clc;clear all;close all;


recs = {'03-Jul-2018','04-Jul-2018','06-Jul-2018'};
filenames = {'X:\mSM63_DLC_Jul03_2018.mat','X:\mSM63_DLC_Jul04_2018.mat','X:\mSM63_DLC_Jul06_2018.mat'};
SDUlim = 4;
epoch = 'delay';
smooth = true;
shuffle = true; %SHUFFLE IS CURRENTLY BROKEN!!!!



allme = []; allstate = [];
for i = 1:length(recs)
    [me,state,A,B,Rs,Ps] = get_variance(recs{i},filenames{i}, epoch, SDUlim, smooth, shuffle);
    allme = [allme; me];
    allstate = [allstate, state{1}];
end

for i = 1:size(me,2)
    [r,p] = corrcoef(allme(:,i),allstate,'rows','complete');
    R(i) = r(1,2);
    P(i) = p(1,2);
end
load('X:\labelNames.mat')

%%
function [var_out,state_out,A,B,R,P] = get_variance(rec, filename, epoch, SDUlim, smooth, shuffle)
[inds, attendinds,biasinds,~, postprobs_sorted] = getStateInds('X:/Widefield','mSM63',rec,'cutoff','allaudio_detection.mat',true);
load('X:\labelNames.mat')
load(filename)
delaylabels = DLC_Lateral.(epoch);

% This isn't perfect, the trial numbers don't quite match
count = 1;
for i = 1:2:27 %iterate over labels
    for j = 1:size(delaylabels,1) %iterate over trials
        x = delaylabels(j,:,i);
        y = delaylabels(j,:,i+1);
        xvar(j) = var(x,'omitnan');
        yvar(j) = var(y,'omitnan');

    end
    x_z = zscore(xvar,[],'omitnan');
    y_z = zscore(yvar,[],'omitnan');
    remove_mask = x_z < -SDUlim | x_z > SDUlim | y_z < -SDUlim | y_z > SDUlim;
    xvar(remove_mask) = NaN;
    yvar(remove_mask) = NaN;
    fprintf('Removed %i outlier trials with SDU greater than %i.\n', sum(remove_mask),SDUlim);
    allvar(:,count) = mean([xvar ; yvar],'omitnan');
    
    p = postprobs_sorted(1,:);
    p(remove_mask) = NaN;
    p = p(1:size(allvar,1));
    p_eng{count} = p;

    count = count + 1;
end

if shuffle
    p_eng = p_eng(randperm(length(p_eng)));
end
if smooth
    allvar = smoothdata(allvar, 1, 'movmean', 10);
end

for i = 1:size(allvar,2) %the correlation way
    [r,p] = corrcoef(p_eng{i},allvar(:,i),'rows','complete');
    R(i) = r(1,2);
    P(i) = p(1,2);
end
%%
for i = 1:size(allvar,2) %the separation way
    part_var = allvar(:,i);
    a = part_var(p_eng{i} > .8);
    b = part_var(p_eng{i} < .2);
    a = a(randperm(length(a),length(b))); %subsample



%     figure; hold on;xlim([0 3]);
%     xticks([1 2]); xticklabels({'Engaged','Disengaged'});
%     ylabel('Variance in trial epoch');
%     title([Laterl_labels{i} '. P = ' num2str(P(i))]);
%     aa = ones(length(a));
%     bb = ones(length(b));
%     scatter(aa,a);
%     scatter(bb.*2,b);
    %exportgraphics(gcf,['C:\Data\churchland\PowerpointsPostersPresentations\SFN2022\FridayUpdate\DLC_variance' filesep epoch filesep rec '_' Laterl_labels{i} '.pdf'],'ContentType','vector')

    [A(i),B(i)] = ttest2(a,b);
end

var_out = allvar;
state_out = p_eng;
end





