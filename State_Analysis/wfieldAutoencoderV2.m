% lets create another autoencoder, but now just predict average delay period activity
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
addpath('C:\Data\churchland\ridgeModel\rateDisc');

cPath = 'X:/Widefield';
animals = {'mSM63'};
Rec = '17-Jul-2018';
glmfile ='allaudio_detection.mat';
stateEqual = 0; % DELETE THIS WHEN MADE INTO FUNCTION!
region = [];
trialperiod = 4;
%hiddensizes = [200 500 1000 5000 10000 50000];
hiddensizes = [20];
sessiondates = getGLMHMMSessions(cPath,animals,glmfile);

Animal = animals{1};
Rec = sessiondates{1}{2};

if stateEqual %equalize state numbers if desired
    [inds, Ainds,Binds] = getStateInds(cPath,Animal,Rec,'max',glmfile,false);
else
    inds = 1:900;
end

[alVc,~] = align2behavior(cPath,Animal,Rec,inds); %pass trialinds based on the sessiondata file, this function will work out the imaging data

Vc = alVc.all;
U = alVc.U;
frames = alVc.segFrames; frames = [1 frames];
transParams = alVc.transParams;
clear alVc

[movie,mask] = unSVDalign2allen(Vc,U,transParams,region,true);
movie = double(movie);


%% Grab the desired trialperiod
inds2grab = frames(trialperiod):frames(trialperiod+1);
X = movie(:,inds2grab,:); %get proper trailperiod
X = squeeze(mean(X,2,'omitnan')); %average over trialperiod


%% train the autoencoder - check how many latent variables are needed
clear alVc inds mask movie sessiondates transParams U Vc Xtemp
for i = hiddensizes
    i
    numiters = 1400000;
    autoenc = trainAutoencoder(X,i,'MaxEpochs',numiters, ...
        'DecoderTransferFunction','purelin','L2WeightRegularization',0.05, ...
        'UseGPU',false);

    XReconstructed = predict(autoenc,X);
    mseError(i) = immse(X,XReconstructed);

    [R,P] = corrcoef(X,XReconstructed);
    Rkeep(i) = R(1,2);
end

%% plot R2 for different sizes of hidden layer
figure;
imagesc(X);
figure;
imagesc(XReconstructed);

%% train the autoencoder - lets see how latents match state estimate
clear alVc inds mask movie sessiondates transParams U Vc Xtemp

numhidden = 4;
numiters = 1400;

autoenc = trainAutoencoder(X,numhidden,'MaxEpochs',numiters, ...
    'DecoderTransferFunction','purelin','SparsityProportion',0.10, ...
    'UseGPU',false);

XReconstructed = predict(autoenc,X);
mseError(i) = immse(X,XReconstructed);
[R,P] = corrcoef(X,XReconstructed);
Rval = R(1,2);


