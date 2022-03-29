%% Decode choice
tic
count = 1; clear Mdl accuracy accuracyshuff betas Vc;
for i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [sessMdl,sessaccuracy,sessbetas,sessVc] = logisticModel(cPath,animals{i},encodingrecs{i},glmFile,10,"Choice","False");
    [~,sessaccuracyshuff,~,~] = logisticModel(cPath,animals{i},encodingrecs{i},glmFile,10,"Choice","True");
    
    if ~isempty(sessMdl) %get the sessions with sufficient trials for plotting (output from sessions without sufficient trials are empty)
        Mdl{count} = sessMdl;
        accuracy(count,:) = sessaccuracy;
        accuracyshuff(count,:) = sessaccuracyshuff;
        betas(:,:,:,count) = sessbetas;
        Vc(count) = sessVc;
        count = count + 1;
    end
end
toc
segframes = Vc(1).segFrames; clear Vc;
cols = {'r','b','g'};
figure
stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
stdshade(accuracyshuff,.2,cols{2},[],6,[1],[]); %plot average accuracy
xline(segframes);
ylim([.4 1]);
yline(.5);
trialperiod = 5;

segframes = [1 segframes];
avginds = segframes(trialperiod):segframes(trialperiod+1);
meanbetas = squeeze(mean(betas,4,'omitnan')); %betas are [xpix,ypix,frames,animals]
periodbetas = meanbetas(:,:,avginds);
trialperiodmean = squeeze(mean(periodbetas,3,'omitnan'));

clims = [-.0005 .0005];
figure
mapImg = imshow(trialperiodmean, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response period decoder weights');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Mean beta weight';

%% Decode state
tic
count = 1; clear Mdl accuracy accuracyshuff betas Vc;
for i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [sessMdl,sessaccuracy,sessbetas,sessVc] = logisticModel(cPath,animals{i},encodingrecs{i},glmFile,25,"State","False");
    [~,sessaccuracyshuff,~,~] = logisticModel(cPath,animals{i},encodingrecs{i},glmFile,25,"State","True");
    
    if ~isempty(sessMdl) %get the sessions with sufficient trials for plotting (output from sessions without sufficient trials are empty)
        Mdl{count} = sessMdl;
        accuracy(count,:) = sessaccuracy;
        accuracyshuff(count,:) = sessaccuracyshuff;
        betas(:,:,:,count) = sessbetas;
        Vc(count) = sessVc;
        count = count + 1;
    end
end
toc
segframes = Vc(1).segFrames; clear Vc;
cols = {'r','b','g'};
figure
stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
stdshade(accuracyshuff,.2,cols{2},[],6,[1],[]); %plot average accuracy
xline(segframes);
ylim([.4 1]);
yline(.5);
trialperiod = 5;

segframes = [1 segframes];
avginds = segframes(trialperiod):segframes(trialperiod+1);
meanbetas = squeeze(mean(betas,4,'omitnan')); %betas are [xpix,ypix,frames,animals]
periodbetas = meanbetas(:,:,avginds);
trialperiodmean = squeeze(mean(periodbetas,3,'omitnan'));

clims = [-.0005 .0005];
figure
mapImg = imshow(trialperiodmean, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response period decoder weights');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Mean beta weight';

%% Decode choice over different states

tic
count1 = 1;count2 = 1; clear attentive_accuracy bias_accuracy attentive_betas bias_betas;
for i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [aMdl,aaccuracy,abetas,aVc] = logisticModel_sepByState(cPath,animals{i},encodingrecs{i},glmFile,10,"Attentive","Choice","False");
    [bMdl,baccuracy,bbetas,bVc] = logisticModel_sepByState(cPath,animals{i},encodingrecs{i},glmFile,10,"Bias","Choice","False");
    
    if ~isempty(aMdl) %get the sessions with sufficient trials for plotting (output from sessions without sufficient trials are empty)
        attentive_Mdl{count1} = aMdl;
        attentive_accuracy(count1,:) = aaccuracy;
        attentive_betas(:,:,:,count1) = abetas;
        attentive_Vc(count1) = aVc;
        
        count1 = count1 + 1;
    end
    
    if ~isempty(bMdl)
        bias_Mdl{count2} = bMdl;
        bias_accuracy(count2,:) = baccuracy;
        bias_betas(:,:,:,count2) = bbetas;
        bias_Vc(count2) = bVc;
        
        count2 = count2 + 1;
    end
end
toc

segframes = attentive_Vc(1).segFrames; clear Vc;
cols = {'r','b','g'};
figure
stdshade(attentive_accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
stdshade(bias_accuracy,.2,cols{2},[],6,[1],[]); %plot average accuracy
xline(segframes);
ylim([.4 1]);
yline(.5);
legend('','Engaged','','Biased','','','','','','');

segframes = [1 segframes];
%avginds = segframes(5):segframes(6); %response period
%avginds = segframes(4):segframes(5); %delay period
avginds = 87:97; %late delay period
a_meanbetas = squeeze(mean(attentive_betas,4,'omitnan')); %betas are [xpix,ypix,frames,animals]
b_meanbetas = squeeze(mean(bias_betas,4,'omitnan')); %betas are [xpix,ypix,frames,animals]

a_periodbetas = a_meanbetas(:,:,avginds);
b_periodbetas = b_meanbetas(:,:,avginds);

a_trialperiodmean = squeeze(mean(a_periodbetas,3,'omitnan'));
b_trialperiodmean = squeeze(mean(b_periodbetas,3,'omitnan'));

clims = [-.0005 .0005];

figure
mapImg = imshow(a_trialperiodmean, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Engaged - Late delay period decoder weights');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Mean beta weight';

figure
mapImg = imshow(b_trialperiodmean, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Disengaged - Late delay period decoder weights');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Mean beta weight';

figure
mapImg = imshow(a_trialperiodmean - b_trialperiodmean, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Difference - Late delay period decoder weights');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Mean beta weight';



