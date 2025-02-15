clc;clear all;close all;


recs = {'03-Jul-2018','04-Jul-2018','06-Jul-2018'};
filenames = {'X:\mSM63_DLC_Jul03_2018.mat','X:\mSM63_DLC_Jul04_2018.mat','X:\mSM63_DLC_Jul06_2018.mat'};
epoch = 'delay';
smooth = false;
shuffle = false;



allme = []; allstate = [];
for i = 1:length(recs)
    [me,state,A,B,Rs,Ps] = get_motion_energy(recs{i},filenames{i}, epoch, smooth, shuffle);
    allme = [allme; me];
    allstate = [allstate, state];
end

for i = 1:size(me,2)
    [r,p] = corrcoef(allme(:,i),allstate,'Rows','complete');
    R(i) = r(1,2);
    P(i) = p(1,2);
end
load('X:\labelNames.mat')

%%
function [me_out,state_out,A,B,R,P] = get_motion_energy(rec, filename, epoch, smooth, shuffle)
[inds, attendinds,biasinds,~, postprobs_sorted,correct] = getStateInds('X:/Widefield','mSM63',rec,'cutoff','allaudio_detection.mat','reward');


load('X:\labelNames.mat')
load(filename)
delaylabels = DLC_Lateral.(epoch);

% This isn't perfect, the trial numbers don't quite match
for i = 1:size(delaylabels,1)
    for j = 1:2:27
        x = delaylabels(i,:,j);
        y = delaylabels(i,:,j+1);
        x_me = abs(diff(x));
        y_me = abs(diff(y));
        me = sqrt(x_me.^2 + y_me.^2);
        mean_me(i,(j+1) / 2) = mean(me,'omitnan');
    end
end

p_eng = postprobs_sorted(1,:);
p_eng = p_eng(1:size(mean_me,1));

correct = correct(1:length(p_eng));
correct_smooth = smoothdata(correct,2,'movmean',40);


if shuffle
    p_eng = p_eng(randperm(length(p_eng)));
end
if smooth
    mean_me = smoothdata(mean_me, 1, 'movmean', 10);
end

for i = 1:size(mean_me,2) %the correlation way
    [r,p] = corrcoef(p_eng,mean_me(:,i),'rows','complete');
    R(i) = r(1,2);
    P(i) = p(1,2);
end
%%
for i = 1:size(mean_me,2) %the separation way
    part_me = mean_me(:,i);
    a = part_me(p_eng > .8);
    b = part_me(p_eng < .2);
    a = a(randperm(length(a),length(b))); %subsample
    
    c = part_me(correct);
    d = part_me(~correct);
    c = c(randperm(length(c),length(d))); %subsample

    %figure; hold on;
    %histogram(a,'BinWidth',.1);
    %histogram(b,'BinWidth',.1);

    %plot over different states
    figure; hold on;xlim([0 3]);
    xticks([1 2]); xticklabels({'Engaged','Disengaged'});
    ylabel('Average ME in trial epoch');
    title([Laterl_labels{i} '. P = ' num2str(P(i))]);
    aa = ones(length(a));
    bb = ones(length(b));
    scatter(aa,a);
    scatter(bb.*2,b);

    %plot over correct vs incorrect
    %[t1, t2 ] = ttest2(c,d);
    figure; hold on;xlim([0 3]);
    xticks([1 2]); xticklabels({'Correct','Incorrect'});
    ylabel('Average ME in trial epoch');
    cc = ones(length(c));
    dd = ones(length(d));
    scatter(cc,c);
    scatter(dd.*2,d);

%     figure;hold on
%     scatter(part_me, correct_smooth)
%     title([Laterl_labels{i} ' mean ME vs performance: ' epoch ' window']);

    %exportgraphics(gcf,['C:\Data\churchland\PowerpointsPostersPresentations\SFN2022\FridayUpdate\DLC_Motionenergy' filesep epoch filesep rec '_' Laterl_labels{i} '.pdf'],'ContentType','vector')

    [A(i),B(i)] = ttest2(a,b);
end

me_out = mean_me;
state_out = p_eng;
end





