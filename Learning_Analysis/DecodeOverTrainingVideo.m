%% get sessions for mice - parallel
clear all;
cPath = 'X:\Widefield';
animals = {'mSM63','mSM64','mSM65','mSM66'};
%animals = {'mSM63','mSM64','mSM65'}; %delete this
%animals = {'CSP22','CSP23','CSP38'};
modality = 'Choice';
glmFile = 'allaudio_detection.mat';
%glmFile = 'allaudio2.mat';

%animals = {'mSM63'}; %first fully self performed session is July 3 for mSM63.

clear dates modalities
parfor i = 1:length(animals)
    [sessiondates{i},modalities{i}] = pythonGetSessionDates(cPath,animals{i});
end

for i = 1:length(animals) %this for loop grabs only audio sessions
    temp = sessiondates{i};
    sessiondates{i} = temp(modalities{i} == 2);
    clear temp;
end
%% Train the models
tic
c = 1;
for i = 1:length(animals)
    for j = 1:length(sessiondates{i})
        [~, acc{i}{j}, betas{i}{j}, Vc] = logisticModel(cPath,animals{i},sessiondates{i}{j},glmFile,10,'Choice',false,true); %train the model
        c = c + 1;
    end
end
c = 1;
toc
%%
%% plot accuracy
count = 1;
clear beta accuracy accuracyB
for i = 1:length(acc)
    if ~isempty(acc{i})
        accuracy(count,:) = acc{i};
        betaA(:,:,:,count) = betas{i}; %betas are [xpix,ypix,frames,animals]
        count = count + 1;
    end
end

count = 1;
for i = 1:length(accB)
    if ~isempty(accB{i})
        accuracyB(count,:) = accB{i};
        betaB(:,:,:,count) = betasB{i};
        count = count + 1;
    end
end

segframes = Vc.segFrames;
segframes = [1 segframes];
cols = {'r','b','g'};

figure
stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
stdshade(accuracyB,.2,cols{2},[],6,[1],[]); %plot average accuracyxline(segframes);

ylim([.4 1]);
yline(.5);
title([modality ' decoder accuracy']);
legend('',[modality ' engaged'],'',[modality ' disengaged']);
