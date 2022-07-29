clc;clear all;close all;
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
%% get sessions for mice
cPath = 'X:\Widefield';
%animals = {'mSM63','mSM64','mSM65','mSM65'};
animals = {'mSM63','mSM64','mSM65'};
%animals = {'mSM63'};
glmFile = 'allaudio_detection.mat';
%glmFile = 'allaudio2.mat';

%sessiondates = getAudioSessions(cPath,animals); %all data for learning
sessiondates = getGLMHMMSessions(cPath,animals,glmFile); %get sessions with GLM-HMM data

%% Get M2 data
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        [inds, Ainds,Binds] = getStateInds(cPath,animals{i},sessiondates{i}{j},'cutoff',glmFile,false);
       
        if length(Ainds) < 25
            continue
        end
        
        [aVc,~] = align2behavior(cPath,animals{i},sessiondates{i}{j},Ainds); %Align imaging to behavior. Pass trialinds based on the sessiondata file, this function will work out the imaging data
        [bVc,~] = align2behavior(cPath,animals{i},sessiondates{i}{j},Binds); %Align imaging to behavior. Pass trialinds based on the sessiondata file, this function will work out the imaging data
        [Amovie,~] = unSVDalign2allen(aVc.all,aVc.U,aVc.transParams,[5 6],true); %Align imaging to Allen and extract desired region.
        [Bmovie,~] = unSVDalign2allen(bVc.all,bVc.U,bVc.transParams,[5 6],true); %Align imaging to Allen and extract desired region.

        shuffinds = inds(randperm(length(inds))); %get shuffled trial labels here
        half = ceil(length(shuffinds)/2);
        Ashuffinds = shuffinds(1:half);
        Bshuffinds = shuffinds(half+1:end);

        [aVc,~] = align2behavior(cPath,animals{i},sessiondates{i}{j},Ashuffinds); %Align imaging to behavior. Pass trialinds based on the sessiondata file, this function will work out the imaging data
        [bVc,~] = align2behavior(cPath,animals{i},sessiondates{i}{j},Bshuffinds); %Align imaging to behavior. Pass trialinds based on the sessiondata file, this function will work out the imaging data
        [Ashuff,~] = unSVDalign2allen(aVc.all,aVc.U,aVc.transParams,[5 6],true); %Align imaging to Allen and extract desired region.
        [Bshuff,~] = unSVDalign2allen(bVc.all,bVc.U,bVc.transParams,[5 6],true); %Align imaging to Allen and extract desired region.

        events = aVc.segFrames;
        numpixels = size(Amovie,1);
        clear aVc bVC;

        stiminds = events(2):events(3); %get stimulus window
        Amovie = Amovie(:,stiminds,:);
        Bmovie = Bmovie(:,stiminds,:);
        Ashuff = Ashuff(:,stiminds,:);
        Bshuff = Bshuff(:,stiminds,:);


        Atrialavg = mean(Amovie,3,'omitnan'); %trial averaged activity
        Btrialavg = mean(Bmovie,3,'omitnan'); %trial averaged activity
        Anoise = Amovie - Atrialavg; %mean subtracted data
        Bnoise = Bmovie - Btrialavg; %mean subtracted data
        Amovie = reshape(Amovie,numpixels,[]);
        Anoise = reshape(Anoise,numpixels,[]);
        Bmovie = reshape(Bmovie,numpixels,[]);
        Bnoise = reshape(Bnoise,numpixels,[]);

        AtrialavgS = mean(Ashuff,3,'omitnan'); %trial averaged activity
        BtrialavgS = mean(Bshuff,3,'omitnan'); %trial averaged activity
        AnoiseS = Ashuff - AtrialavgS; %mean subtracted data
        BnoiseS = Bshuff - BtrialavgS; %mean subtracted data
        Ashuff = reshape(Ashuff,numpixels,[]);
        AnoiseS = reshape(AnoiseS,numpixels,[]);
        Bshuff = reshape(Bshuff,numpixels,[]);
        BnoiseS = reshape(BnoiseS,numpixels,[]);



        Arawcorr = corr(Amovie','rows','complete');
        Asignalcorr = corr(Atrialavg','rows','complete').^2;
        %AsignalcorrS = corr(AtrialavgS','rows','complete').^2;
        Anoisecorr = corr(Anoise','rows','complete');
        Brawcorr = corr(Bmovie','rows','complete');
        Bsignalcorr = corr(Btrialavg','rows','complete').^2;
        %BsignalcorrS = corr(BtrialavgS','rows','complete').^2;
        Bnoisecorr = corr(Bnoise','rows','complete');
        
        nt = length(Ainds);
        %figure; hold on; histogram(Arawcorr,'BinWidth',.0025); histogram(Brawcorr,'BinWidth',.0025); title([animals{i} ' ' sessiondates{i}{j} ' raw correlations. ' int2str(nt) ' trials per state.']); legend('engaged','disengaged');
        figure; hold on; histogram(Asignalcorr,'BinWidth',.0025); histogram(Bsignalcorr,'BinWidth',.0025); title([animals{i} ' ' sessiondates{i}{j} ' signal correlations. ' int2str(nt) ' trials per state.']); legend('engaged','disengaged');
        %figure; hold on; histogram(AsignalcorrS,'BinWidth',.0025); histogram(BsignalcorrS,'BinWidth',.0025); title([animals{i} ' ' sessiondates{i}{j} ' SHUFFLE signal correlations. ' int2str(nt) ' trials per state.']); legend('engaged','disengaged');
        %figure; hold on; histogram(Anoisecorr,'BinWidth',.0025); histogram(Bnoisecorr,'BinWidth',.0025); title([animals{i} ' ' sessiondates{i}{j} ' noise correlations. ' int2str(nt) ' trials per state.']); legend('engaged','disengaged');
    end
end


