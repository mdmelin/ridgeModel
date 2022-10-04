parpool('local',16);
%% 
close all;
mouse = 'mSM63';
frames = {1:31, ...
    31:45, ...
    45:60, ...
    60:71}; %need to modify these to proper timeperiods in trial
recs = {'04-Jul-2018','05-Jul-2018','09-Jul-2018','17-Jul-2018','19-Jul-2018'};
recs1 = recs;
recs2 = {'09-Jul-2018','10-Jul-2018'}; %for mSM65
recs3 = {'27-Jun-2018','28-Jun-2018','29-Jun-2018','30-Jun-2018','02-Jul-2018','04-Jul-2018','05-Jul-2018'};%for mSM66
%% Generate figure: "state is collinear with something"
mouse = 'mSM63';
parfor i = 1:length(recs1)
    fullR2(i) = getRSquaredNew(mouse,recs1{i},'allaudio_withstate.mat');
    nostateR2(i) = getRSquaredNew(mouse,recs1{i},'allaudio_nostate.mat');
end

mouse = 'mSM65';
parfor i = 1:2
    fullR2(i+5) = getRSquaredNew(mouse,recs2{i},'forchaoqun_subsetofsessions_withstate.mat');
    nostateR2(i+5) = getRSquaredNew(mouse,recs2{i},'forchaoqun_subsetofsessions_nostate.mat');
end

mouse = 'mSM66';
parfor i = 1:7
    fullR2(i+7) = getRSquaredNew(mouse,recs3{i},'forchaoqun_withstate.mat');
    nostateR2(i+7) = getRSquaredNew(mouse,recs3{i},'forchaoqun_nostate.mat');
end
figure
labels = {'Full model','Without state'};
boxplot([fullR2',nostateR2'],labels,'PlotStyle','traditional','OutlierSize',.0001);
hold on;
t1 = ones(14,1);
t2 = t1;
t2(:) = 2;
scatter(t1,fullR2);
scatter(t2,nostateR2);
parallelcoords([fullR2',nostateR2']);
title('Leave one out analysis - state regressor');
ylabel('cvR^2');

%% Generate figure: "Is state collinear with video?
mouse = 'mSM63';
parfor i = 1:length(recs1)
    nov(i) = getRSquaredNew(mouse,recs1{i},'allaudio_novideome.mat');
    nos(i) = getRSquaredNew(mouse,recs1{i},'allaudio_novideomestate.mat');
end

mouse = 'mSM65';
parfor i = 1:2
    nov(i+5) = getRSquaredNew(mouse,recs2{i},'forchaoqun_subsetofsessions_novideome.mat');
    nos(i+5) = getRSquaredNew(mouse,recs2{i},'forchaoqun_subsetofsessions_novideomestate.mat');
end

mouse = 'mSM66';
parfor i = 1:7
    nov(i+7) = getRSquaredNew(mouse,recs3{i},'forchaoqun_novideome.mat');
    nos(i+7) = getRSquaredNew(mouse,recs3{i},'forchaoqun_novideomestate.mat');
end

figure
labels = {'No Video, VideoME or State','No Video or VideoMe'};
boxplot([nos',nov'],labels,'PlotStyle','traditional','OutlierSize',.0001);
hold on;
t1 = ones(14,1);
t2 = t1;
t2(:) = 2;
scatter(t1,nos);
scatter(t2,nov);
parallelcoords([nos',nov']);
title('Removing video and videoME');
ylabel('cvR^2');

%% Generate figure: "Is state collinear with any/all movement?"
mouse = 'mSM63';
parfor i = 1:length(recs1)
    nov(i) = getRSquaredNew(mouse,recs1{i},'allaudio_nomotor.mat');
    nos(i) = getRSquaredNew(mouse,recs1{i},'allaudio_nomotorstate.mat');
end

mouse = 'mSM65';
parfor i = 1:2
    nov(i+5) = getRSquaredNew(mouse,recs2{i},'forchaoqun_subsetofsessions_nomotor.mat');
    nos(i+5) = getRSquaredNew(mouse,recs2{i},'forchaoqun_subsetofsessions_nomotorstate.mat');
end

mouse = 'mSM66';
parfor i = 1:7
    nov(i+7) = getRSquaredNew(mouse,recs3{i},'forchaoqun_nomotor.mat');
    nos(i+7) = getRSquaredNew(mouse,recs3{i},'forchaoqun_nomotorstate.mat');
end

figure
labels = {'No uninstructed movements or state','No uninstructed movements'};
boxplot([nos',nov'],labels,'PlotStyle','traditional','OutlierSize',.0001);
hold on;
t1 = ones(14,1);
t2 = t1;
t2(:) = 2;
scatter(t1,nos);
scatter(t2,nov);
parallelcoords([nos',nov']);
title('Removing all uninstructed movements');
ylabel('cvR^2');

%% Generate figure: "Is state collinear with reward?"
mouse = 'mSM63';
parfor i = 1:length(recs1)
    nov(i) = getRSquaredNew(mouse,recs1{i},'allaudio_noreward.mat');
    nos(i) = getRSquaredNew(mouse,recs1{i},'allaudio_norewardstate.mat');
end

mouse = 'mSM65';
parfor i = 1:2
    nov(i+5) = getRSquaredNew(mouse,recs2{i},'forchaoqun_subsetofsessions_noreward.mat');
    nos(i+5) = getRSquaredNew(mouse,recs2{i},'forchaoqun_subsetofsessions_norewardstate.mat');
end

mouse = 'mSM66';
parfor i = 1:7
    nov(i+7) = getRSquaredNew(mouse,recs3{i},'forchaoqun_noreward.mat');
    nos(i+7) = getRSquaredNew(mouse,recs3{i},'forchaoqun_norewardstate.mat');
end

figure
labels = {'No reward or state','No reward'};
boxplot([nos',nov'],labels,'PlotStyle','traditional','OutlierSize',.0001);
hold on;
t1 = ones(14,1);
t2 = t1;
t2(:) = 2;
scatter(t1,nos);
scatter(t2,nov);
parallelcoords([nos',nov']);
title('Removing reward');
ylabel('cvR^2');
%%

%% state shuffles
clear nos nov
mouse = 'mSM63';
parfor i = 1:length(recs)
    nos(i) = getRSquaredNew(mouse,recs{i},'allaudio_withstate.mat');
    
    nov(i) = getRSquaredNew(mouse,recs{i},'allaudio_withstate_shuffle.mat'); %full model with state shuffled
end
figure
labels = {'Full model','Full model - shuffled state labels'};
boxplot([nos',nov'],labels,'PlotStyle','traditional','OutlierSize',.0001);
hold on;
t1 = ones(5,1);
t2 = t1;
t2(:) = 2;
scatter(t1,nos);
scatter(t2,nov);
parallelcoords([nos',nov']);
title('Shuffling state in full model');
ylabel('cvR^2');
%% state shuffles single variable
mouse = 'mSM63';
parfor i = 1:length(recs)
    nos(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlystate.mat');
    
    nov(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlystate_shuffle.mat'); %single variable shuffle
end
figure
labels = {'Single variable model - state','Shuffled single variable model'};
boxplot([nos',nov'],labels,'PlotStyle','traditional','OutlierSize',.0001);
hold on;
t1 = ones(5,1);
t2 = t1;
t2(:) = 2;
scatter(t1,nos);
scatter(t2,nov);
parallelcoords([nos',nov']);
title('Shuffling state in single variable model');
ylabel('cvR^2');
%% state shuffles single variable
mouse = 'mSM63';
parfor i = 1:length(recs)
    nos(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlystate.mat');
    
    nov(i) = getRSquaredNew(mouse,recs{i},'allaudio_statecoinflip.mat'); %single variable shuffle
end
figure
labels = {'Single variable model - state','Shuffled single variable model'};
boxplot([nos',nov'],labels,'PlotStyle','traditional','OutlierSize',.0001);
hold on;
t1 = ones(5,1);
t2 = t1;
t2(:) = 2;
scatter(t1,nos);
scatter(t2,nov);
parallelcoords([nos',nov']);
title('Coin flip shuffle');
ylabel('cvR^2');