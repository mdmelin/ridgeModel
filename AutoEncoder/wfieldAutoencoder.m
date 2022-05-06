function [autoenc,mseError,R] = wfieldAutoencoder(cPath,Animal,Rec,region,hiddenSize,stateEqual)
addpath(genpath('C:\Data\churchland\ridgeModel'));

inds = 1:900; %these are the trial indices to grab. I just set it to 1:900 so that it grabs every trial from the session.

if stateEqual %equalize state numbers if desired
    [inds, ~,~] = getStateInds(cPath,Animal,Rec,'allaudio.mat',false);
end

[alVc,~] = align2behavior(cPath,Animal,Rec,inds); %pass trialinds based on the sessiondata file, this function will work out the imaging data

Vc = alVc.all;
U = alVc.U;
transParams = alVc.transParams;

[movie,mask] = unSVDalign2allen(Vc,U,transParams,region);



%%
X = movie(:,45:75,:); %grab STIMULUS window
X = double(reshape(X,size(X,1),[]));

Xnew = [];

for i = 1:size(X,2) %remove nans, makes R calculation easier
    if sum(isnan(X(:,i))) == 0
        Xnew(:,i) = X(:,i);
    end
end
X = Xnew;
%% train the autoencoder
numiters = 1400;
autoenc = trainAutoencoder(X,hiddenSize,'MaxEpochs',numiters, ...
    'DecoderTransferFunction','purelin','SparsityProportion',0.10);

XReconstructed = predict(autoenc,X);
mseError = immse(X,XReconstructed);

[R,P] = corrcoef(X,XReconstructed);
R = R(1,2);
end
