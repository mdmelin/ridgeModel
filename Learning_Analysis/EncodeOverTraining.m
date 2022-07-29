addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% get sessions for mice
cPath = 'X:\Widefield';
%cPath = 'V:\StateProjectCentralRepo\Widefield_Sessions';
%animals = {'mSM63','mSM64','mSM65','mSM66','CSP22','CSP23','CSP32','CSP38'};
%animals = {'mSM63','mSM64','mSM65','mSM66'};
animals = {'CSP22','CSP23','CSP38'}; % ,'CSP32' not working

sessiondates = getAudioSessions(cPath,animals);

%% train encoding models
tic
for i = 1:length(animals)
    parfor j = 1:length(sessiondates{i})
        ridgeModel_vanillaAligned(cPath,animals{i},sessiondates{i}{j},[],[],false);
    end
end
time1 = toc
%% EMX Encoding model variance for early learning and late learning (and maybe state?)
clear full spont op task noop nospont notask
animals = {'mSM63','mSM64','mSM65','mSM66'};
sessiondates = getAudioSessions(cPath,animals);
for i = 1:length(animals)
    parfor j = 1:length(sessiondates{i})
        full(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'allvars.mat');
        spont(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'spontmotor.mat');
        op(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'opmotor.mat');
        task(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'taskvars.mat');
        nospont(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'nospontmotor.mat');
        noop(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'noopmotor.mat');
        notask(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'notaskvars.mat');
    end
end
full(full==0) = nan;spont(spont==0) = nan;op(op==0) = nan;task(task==0) = nan;
nospont(nospont==0) = nan;noop(noop==0) = nan;notask(notask==0) = nan;
figure;

%% CSTR Encoding model variance for early learning and late learning (and maybe state?)
animals = {'CSP22','CSP23','CSP38'}; % ,'CSP32' not working
sessiondates = getAudioSessions(cPath,animals);
clear full spont op task noop nospont notask
for i = 1:length(animals)
    parfor j = 1:length(sessiondates{i})
        full(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'allvars.mat');
        spont(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'spontmotor.mat');
        op(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'opmotor.mat');
        task(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'taskvars.mat');
        nospont(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'nospontmotor.mat');
        noop(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'noopmotor.mat');
        notask(i,j) = getRSquaredNew(animals{i},sessiondates{i}{j},'notaskvars.mat');
    end
end
full(full==0) = nan;spont(spont==0) = nan;op(op==0) = nan;task(task==0) = nan;
nospont(nospont==0) = nan;noop(noop==0) = nan;notask(notask==0) = nan;

%% now plot Rsquared maps and d
animals = {'CSP23'}; % ,'CSP32' not working
sessiondates = getAudioSessions(cPath,animals);
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        plotRSquared(animals{i},sessiondates{i}{j},{'allvars.mat','notaskvars.mat'},'colormap_blueblackred',[-.06 .06],false);
    end
end

