close all;
mouse = 'mSM63';
% rec = '09-Jul-2018';
rec = '17-Jul-2018';
frames = {1:31; ...
          31:45; ...
          45:60; ...
          60:71}; %need to modify these to proper timeperiods in trial

%% Get cvRsquared histograms
modelfiles = {'orgfullcorr_simon.mat','orgfullcorr.mat','orgfullcorr_withstate.mat','orgfullcorr_onlychoice.mat','orgfullcorr_onlystate.mat','orgfullcorr_onlyreward.mat'};
histogramRSquared(mouse,rec,modelfiles);

%% Plot some CVRsquared for various models
plotRSquared(mouse,rec,'orgfullcorr_simon.mat',frames,[0 .8]);
plotRSquared(mouse,rec,'orgfullcorr.mat',frames,[0 .8]);
plotRSquared(mouse,rec,'orgfullcorr_withstate.mat',frames,[0 .8]);
[x,y] = plotRSquared(mouse,rec,'test_onlystate.mat',frames,[0 .1]);
[x2,y2] = plotRSquared(mouse,rec,'orgfullcorr_onlychoice.mat',frames,[0 .1]);
[x3,y3] = plotRSquared(mouse,rec,'orgfullcorr_onlyreward.mat',frames,[0 .25]);

%% Plot some stimulus betas
betac = 3e-4;
plotBetas(mouse,rec,'orgfullcorr_simon.mat',{'rAudStim'},{1:10},[-betac betac]);
plotBetas(mouse,rec,'orgfullcorr.mat',{'rAudStim'},{1:10},[-betac betac]);
plotBetas(mouse,rec,'orgfullcorr_withstate.mat',{'rAudStim'},{1:10},[-betac betac]);
betac = 5e-3;
plotBetas(mouse,rec,'orgfullcorr_onlyreward.mat',{'reward'},frames,[-betac betac]);

%% Plot some attentive state betas

betac = 1e-3;      
plotBetas(mouse,rec,'orgfullcorr_withstate.mat',{'attentive'},frames,[-betac betac]);
plotBetas(mouse,rec,'orgfullcorr_withstate.mat',{'time'},frames,[-betac betac]);
betac = 5e-3;
plotBetas(mouse,rec,'orgfullcorr_onlystate.mat',{'attentive'},frames,[-betac betac]);
plotBetas(mouse,rec,'orgfullcorr_onlychoice.mat',{'Choice'},frames,[-betac betac]);

%% compare across sessions
betac = 1e-3;
rec = '04-Jul-2018';
plotBetas(mouse,rec,'orgfullcorr.mat',{'reward'},frames,[-betac betac]);
rec = '05-Jul-2018';
plotBetas(mouse,rec,'orgfullcorr.mat',{'reward'},frames,[-betac betac]);

%% check with jitter added
modelfiles = {'orgfullcorr.mat','test_withstate.mat'};
histogramRSquared(mouse,rec,modelfiles,[0 .5]);
modelfiles = {'orgfullcorr_onlystate.mat','test_onlystate.mat','orgfullcorr_onlychoice.mat'};
histogramRSquared(mouse,rec,modelfiles,[0 .05]);

plotRSquared(mouse,rec,'test_onlystate.mat',frames,[0 .15]);
plotRSquared(mouse,rec,'test_withstate.mat',frames,[0 .9]);

betac = 1e-3;      
plotBetas(mouse,rec,'test_withstate.mat',{'attentive'},frames,[-betac betac]);
betac = 10e-3;
plotBetas(mouse,rec,'test_onlystate.mat',{'attentive'},frames,[-betac betac]);




