%% mSM63
%diary mSM63allaudioDiarywithJitter

cPath = 'X:/Widefield';
Animal = 'mSM63'
glmFile = 'allaudio.mat'

Recs = {'04-Jul-2018','05-Jul-2018','09-Jul-2018','17-Jul-2018','18-Jul-2018','19-Jul-2018','20-Jul-2018'};
for i = 1:length(Recs)
    ridgeModel_stateEncoding(cPath,Animal,Recs{i},glmFile,[]);
end
diary off

%% State variance search

cPath = 'X:/Widefield';
Animal = 'mSM63'
glmFile = 'forchaoqun.mat'


Rec = '04-Jul-2018'
ridgeModel_stateVarianceSearch(cPath,Animal,Rec,glmFile,[]);
Rec = '05-Jul-2018'
ridgeModel_stateVarianceSearch(cPath,Animal,Rec,glmFile,[]);
Rec = '09-Jul-2018'
ridgeModel_stateVarianceSearch(cPath,Animal,Rec,glmFile,[]);
Rec = '17-Jul-2018'
ridgeModel_stateVarianceSearch(cPath,Animal,Rec,glmFile,[]);
Rec = '18-Jul-2018' %%%%%%
ridgeModel_stateVarianceSearch(cPath,Animal,Rec,glmFile,[]);
Rec = '19-Jul-2018'
ridgeModel_stateVarianceSearch(cPath,Animal,Rec,glmFile,[]);
Rec = '20-Jul-2018' %%%%%
ridgeModel_stateVarianceSearch(cPath,Animal,Rec,glmFile,[]);
%% mSM65
%diary mSM63allaudioDiarywithJitter

cPath = 'X:/Widefield';
Animal = 'mSM65'
glmFile = 'forchaoqun_subsetofsessions.mat'


% Rec = '05-Jun-2018' missing opts file
% ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '09-Jul-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '10-Jul-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
% Rec = '11-Jul-2018' Unable to perform assignment because the size of the left side is 1-by-1 and the size of the right side is 1-by-3.
% ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);

diary off

%% mSM66
%diary mSM63allaudioDiarywithJitter

cPath = 'X:/Widefield';
Animal = 'mSM66'
glmFile = 'forchaoqun.mat'


Rec = '27-Jun-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '28-Jun-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '29-Jun-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '30-Jun-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '02-Jul-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
% Rec = '03-Jul-2018' doesnt work, i think not enough trials
% ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '04-Jul-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '05-Jul-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);

diary off
%% run for sessions with close to 50:50 state split

cPath = 'X:/Widefield';
Animal = 'mSM63'
glmFile = 'forchaoqun.mat'


Rec = '11-Jul-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '17-Jul-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '20-Jul-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '29-Jun-2018'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);

%% run for sessions with close to 50:50 state split, CSP23

cPath = 'X:/Widefield';
Animal = 'CSP23'
glmFile = 'forchaoqun.mat'


% Rec = '11-Jul-2020' no opts file
% ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '17-Jul-2020'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '20-Jul-2020'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);
Rec = '29-Jun-2020'
ridgeModel_stateEncoding(cPath,Animal,Rec,glmFile,[]);

%% test random shuffle

cPath = 'X:/Widefield';
Animal = 'mSM63'
glmFile = 'forchaoqun.mat'
Recs = {'16-Jul-2018','17-Jul-2018','18-Jul-2018','19-Jul-2018','20-Jul-2018'};

for i = 1:length(Recs)
    ridgeModel_deleteme(cPath,Animal,Recs{i},glmFile,[]);
end
for i = 1:length(Recs)
    ridgeModel_deleteme2(cPath,Animal,Recs{i},glmFile,[]);
end
%% delete this - from above
mouse = Animal;
for i = 1:length(Recs)
    attentiveR2(i) = getRSquaredNew(mouse,Recs{i},'forchaoqun_onlystate.mat');
    choiceR2(i) = getRSquaredNew(mouse,Recs{i},'forchaoqun_onlychoice.mat');
    rewardR2(i) = getRSquaredNew(mouse,Recs{i},'forchaoqun_onlyreward.mat');
    shuffR2(i) = getRSquaredNew(mouse,Recs{i},'forchaoqun_onlyRAND.mat');
end
