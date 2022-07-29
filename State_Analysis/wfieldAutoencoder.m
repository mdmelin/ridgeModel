%function [autoenc,X,Xreconstructed,mseError,R] = wfieldAutoencoder(cPath,Animal,Rec,region,hiddenSize,stateEqual)
addpath('C:\Data\churchland\ridgeModel\Max_Analysis');
addpath('C:\Data\churchland\ridgeModel\rateDisc');

cPath = 'X:/Widefield';
animals = {'mSM63'};
Rec = '17-Jul-2018';
glmfile ='allaudio_detection.mat';
stateEqual = 0; % DELETE THIS WHEN MADE INTO FUNCTION!
region = [5 ];
maxhiddensize = 8;
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
transParams = alVc.transParams;

[movie,mask] = unSVDalign2allen(Vc,U,transParams,region,true);



%%
X = movie; %X = movie(:,45:75,:); %grab STIMULUS window
X = reshape(X,size(X,1),[]);

Xtemp = [];

for i = 1:size(X,2) %remove nans, makes R calculation easier
    if sum(isnan(X(:,i))) == 0
        Xtemp(:,i) = X(:,i);
    end
end
X = Xtemp;
%% train the autoencoder - check how many latent variables are needed
clear alVc inds mask movie sessiondates transParams U Vc Xtemp
for i = 1:maxhiddensize
    i
    numiters = 1400;
    autoenc = trainAutoencoder(X,i,'MaxEpochs',numiters, ...
        'DecoderTransferFunction','purelin','SparsityProportion',0.10, ...
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


%% run encoding for engaged trials
[alVc,~] = align2behavior(cPath,Animal,Rec,Ainds); %pass trialinds based on the sessiondata file, this function will work out the imaging data
Vc = alVc.all;
U = alVc.U;
transParams = alVc.transParams;
[movie,mask] = unSVDalign2allen(Vc,U,transParams,region);
X = movie(:,45:75,:); %grab STIMULUS window
X = reshape(X,size(X,1),[]);
Xnew = [];
for i = 1:size(X,2) %remove nans, makes R calculation easier
    if sum(isnan(X(:,i))) == 0
        Xnew(:,i) = X(:,i);
    end
end
X = Xnew;

a_enc = encode(autoenc,X);

%% run encoding for biased trials
[alVc,~] = align2behavior(cPath,Animal,Rec,Binds); %pass trialinds based on the sessiondata file, this function will work out the imaging data
Vc = alVc.all;
U = alVc.U;
transParams = alVc.transParams;
[movie,mask] = unSVDalign2allen(Vc,U,transParams,region);
X = movie(:,45:75,:); %grab STIMULUS window
X = reshape(X,size(X,1),[]);
Xnew = [];
for i = 1:size(X,2) %remove nans, makes R calculation easier
    if sum(isnan(X(:,i))) == 0
        Xnew(:,i) = X(:,i);
    end
end
X = Xnew;

b_enc = encode(autoenc,X);
%% get correlations of encoding
corra = abs(corrcoef(a_enc'));
corrb = abs(corrcoef(b_enc'));

nbins = 100;
figure;hold on;
histogram(corra,nbins);
histogram(corrb,nbins);
legend('engaged','disengaged');
xlabel('Rsquared');
ylabel('Number of pairs');

%% test with raw neural data - lets do normal correlations first
[alVc,~] = align2behavior(cPath,Animal,Rec,Ainds); %pass trialinds based on the sessiondata file, this function will work out the imaging data
Vc = alVc.all;
U = alVc.U;
transParams = alVc.transParams;
[movie,mask] = unSVDalign2allen(Vc,U,transParams,region);
X = movie(:,45:75,:); %grab STIMULUS window
X = reshape(X,size(X,1),[]);
Xnew = [];
for i = 1:size(X,2) %remove nans, makes R calculation easier
    if sum(isnan(X(:,i))) == 0
        Xnew(:,i) = X(:,i);
    end
end
Xa = Xnew;

[alVc,~] = align2behavior(cPath,Animal,Rec,Binds); %pass trialinds based on the sessiondata file, this function will work out the imaging data
Vc = alVc.all;
U = alVc.U;
transParams = alVc.transParams;
[movie,mask] = unSVDalign2allen(Vc,U,transParams,region);
X = movie(:,45:75,:); %grab STIMULUS window
X = reshape(X,size(X,1),[]);
Xnew = [];
for i = 1:size(X,2) %remove nans, makes R calculation easier
    if sum(isnan(X(:,i))) == 0
        Xnew(:,i) = X(:,i);
    end
end
Xb = Xnew;

corra = corrcoef(Xa').^2;
corrb = corrcoef(Xb').^2;

nbins = 100;
figure;hold on;
histogram(corra,nbins);
histogram(corrb,nbins);
legend('engaged','disengaged');
xlabel('Rsquared');
ylabel('Number of pairs');

%end
