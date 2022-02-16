parpool('local',16);
%% 
close all;
mouse = 'mSM63';
frames = {1:31, ...
    31:45, ...
    45:60, ...
    60:71}; %need to modify these to proper timeperiods in trial
recs = {'04-Jul-2018','05-Jul-2018','09-Jul-2018','17-Jul-2018','18-Jul-2018','19-Jul-2018','20-Jul-2018'};
recs1 = recs;
recs2 = {'09-Jul-2018','10-Jul-2018'}; %for mSM65
recs3 = {'27-Jun-2018','28-Jun-2018','29-Jun-2018','30-Jun-2018','02-Jul-2018','03-Jul-2018','04-Jul-2018','05-Jul-2018'};%for mSM66

%% compare r handle betas across sessions - sanity check
betac = 1.5e-3;
frames = {1:10, 10:15}; %need to modify these to proper timeperiods in trial
for i = 1:length(recs)
    plotBetas(mouse,recs{i},'forchaoqun_withstate.mat',{'rGrab'},frames,[-betac betac]);
end

%% compare whisk betas across sessions - sanity check, lack of somatosensory
betac = 1.5e-3;
frames = {1:10, 10:15,15:40,70:90}; %need to modify these to proper timeperiods in trial
for i = 1:length(recs)
    plotBetas(mouse,recs{i},'forchaoqun_withstate.mat',{'nose'},frames,[-betac betac]);
end

%% compare stimulus betas across sessions - sanity check, weird
betac = 3e-4;
frames = {1:10};
for i = 1:length(recs)
    plotBetas(mouse,recs{i},'forchaoqun_withstate.mat',{'rAudStim'},frames,[-betac betac]);
end

%% plot state betas
betac = 1e-3;
frames = {1:31, ...
    31:45, ...
    45:60, ...
    60:71}; %need to modify these to proper timeperiods in trial
for i = 1:length(recs)
    plotBetas(mouse,recs{i},'forchaoqun_withstate.mat',{'attentive'},frames,[-betac betac]);
end



%% Plot CVRsquared maps for various models
mouse = 'mSM63';
frames = {1:31, ...
    31:45, ...
    45:60, ...
    60:71}; %need to modify these to proper timeperiods in trial
rec = '05-Jul-2018';
plotRSquared(mouse,rec,'allaudio_onlystate.mat',frames,[0 .15]);

%% Plot CVRsquared maps for single variable models - reward and state seem kinda similar
recs = {'16-Jul-2018','17-Jul-2018','18-Jul-2018','19-Jul-2018','20-Jul-2018'};
for i = 1:length(recs)
    %plotRSquared(mouse,recs{i},'allaudio_onlyreward.mat',frames,[0 .05]);
    plotRSquared(mouse,recs{i},'forchaoqun_onlystate.mat',frames,[0 .05]);
end


%% check with shuffled regressors

parfor i = 1:length(recs)
    lgrab(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlylGrab.mat');
    state(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlystate.mat');
    choice(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlychoice.mat');
    reward(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlyreward.mat');
    audstim(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlyllaudStim.mat');
    time(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlytime.mat');
    llick(i) = getRSquaredNew(mouse,recs{i},'allaudio_onlyllick.mat');

end






