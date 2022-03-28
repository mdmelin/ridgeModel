mSM63recs = {'09-Jul-2018','13-Jul-2018','16-Jul-2018','17-Jul-2018','18-Jul-2018','19-Jul-2018','20-Jul-2018'}; %mSM63
mSM64recs = {'24-Jul-2018','27-Jul-2018'}; %,,'25-Jul-2018' only has one state ,'26-Jul-2018' also not in
mSM65recs = {'05-Jul-2018','28-Jun-2018','29-Jun-2018','02-Jul-2018'}; %for mSM65, maybe put , back in
mSM66recs = {'27-Jun-2018','28-Jun-2018','29-Jun-2018','30-Jun-2018','02-Jul-2018','04-Jul-2018','05-Jul-2018','11-Jul-2018','16-Jul-2018'};%for mSM66 add , back in
%^these sessions are basically all of the audio discrimination sessions from these mice
addpath('C:\Data\churchland\ridgeModel\rateDisc');
addpath('C:\Data\churchland\ridgeModel\smallStuff');
mSM63labels = cell(1,length(mSM63recs));
mSM63labels(:) = {'mSM63'};
mSM64labels = cell(1,length(mSM64recs));
mSM64labels(:) = {'mSM64'};
mSM65labels = cell(1,length(mSM65recs));
mSM65labels(:) = {'mSM65'};
mSM66labels = cell(1,length(mSM66recs));
mSM66labels(:) = {'mSM66'};

encodingrecs = [mSM63recs,mSM64recs,mSM65recs,mSM66recs];
animals = [mSM63labels,mSM64labels,mSM65labels,mSM66labels];
cPath = 'X:/Widefield';
glmFile = 'allaudio.mat';

% THIS CODE IS FOR TESTING OUT DECODES WITH DIFFERENT STATES

%% Plot decoder - choice in attentive state
for i = 1:length(animals)
    fprintf('\n%s, %s\n ',animals{i},encodingrecs{i});
    [Mdl{i},accuracy(i,:),betas(:,:,:,i),Vc(i)] = logisticModel_choicestate(cPath,animals{i},encodingrecs{i},glmFile,10);
end


segframes = Vc(1).segFrames; clear Vc;
cols = {'r','b','g'};
figure
stdshade(accuracy,.2,cols{1},[],6,[1],[]); %plot average accuracy
%stdshade(accuracyshuff,.2,cols{2},[],6,[1],[]); %plot average accuracy
xline(segframes);
ylim([.4 1]);
yline(.5);
trialperiod = 5;

segframes = [1 segframes];
avginds = segframes(trialperiod):segframes(trialperiod+1);
meanbetas = squeeze(mean(betas,4,'omitnan')); %betas are [xpix,ypix,frames,animals]
periodbetas = meanbetas(:,:,avginds);
trialperiodmean = squeeze(mean(periodbetas,3,'omitnan'));

clims = [-.001 .001];
figure
mapImg = imshow(trialperiodmean, clims);
colormap(mapImg.Parent,'colormap_blueblackred'); axis image; title('Response period decoder weights');
set(mapImg,'AlphaData',~isnan(mapImg.CData)); %make NaNs transparent.
hcb = colorbar;
hcb.Title.String = 'Mean beta weight';