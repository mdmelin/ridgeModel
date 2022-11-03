function [newFrames,segFrames1] = realignBhvVideo2(cPath, Animal, Rec, goodtrials, camnum, segIdx, opts)
% code to re-align Vc so each trial is aligned to different task episodes.
% Alignment is done to baseline, handle, stimulus and delay period.
% 'segFrames' defines how many frames per task episodes should be in the
% newVc output. SegFrames should be cumulative, so say 'baseline should be
% from trial 1 to segFrames(1), handle data should be from segFrames(1) to
% segFrames(2) and so on...



%% check if we already have alignment done
vidPath  = [cPath filesep Animal filesep 'video' filesep Rec filesep];
savepath = [vidPath filesep 'alignedvideo_' num2str(camnum) '.mat'];

Behavior_alignVideoFrames(cPath, Animal, Rec,opts.preStim);
f = dir([vidPath filesep '*cameraTimes.mat']);
f = load([f.folder filesep f.name]);

%%
rejCnt1 = 0;
h = waitbar(0,'Running behavior video alignment');
for iTrials = 1 : length(goodtrials) %get number of trials in full session
    currenttrial = goodtrials(iTrials);
    waitbar(iTrials/length(goodtrials),h);

    if camnum == 1
        v1 = dir([vidPath filesep 'cam1' filesep sprintf('*Video_%04d_1.mp4',currenttrial)]);
    elseif camnum == 2
        v1 = dir([vidPath filesep 'cam2' filesep sprintf('*Video_%04d_2.mp4',currenttrial)]);
    end
    v1 = VideoReader([v1.folder filesep v1.name]);
    fs1 = v1.FrameRate;
    v1 = read(v1);
    for i = 1:size(v1,4)
        v2(:,:,i) = rgb2gray(v1(:,:,:,i))';
    end
    v1 = v2; clear v2;

    segFrames1 = cumsum(floor(segIdx * fs1));
    newV1 = nan(size(v1,1),size(v1,2),segFrames1(end),'single'); %[x,y,frames], change to uint8 if needing to imshow

    clear cIdx1
    cIdx1(1) = f.handlesIn(camnum,currenttrial); %handles in
    cIdx1(2) = f.stimOn(camnum,currenttrial); %stim onset
    cIdx1(3) = f.stimOff(camnum,currenttrial); %time of last stimulus event
    cIdx1(4) = f.spoutsIn(camnum,currenttrial);%spouts in
    cIdx1(end + 1) = size(v1,3);

    if cIdx1(1) > 0 %in very rare cases there might be something wrong with handle time. don't use those trials.
        if segFrames1(1) >= cIdx1(1)
            newV1(:,:, segFrames1(1) - cIdx1(1) + 1 : segFrames1(1)) = v1(:,:, 1 : cIdx1(1)); % baseline
        elseif segFrames1(1) < cIdx1(1)
            newV1(:,:, 1 : segFrames1(1)) = v1(:,:, cIdx1(1) - segFrames1(1) + 1 : cIdx1(1)); % baseline
        end
        %the problem is this line. double check it.
        newV1(:,:, segFrames1(1) + 1 : segFrames1(1) + (diff(cIdx1(1:2)))) = v1(:,:, cIdx1(1) + 1 : cIdx1(2)); %handle period
        newV1(:,:, segFrames1(2) + 1 : segFrames1(2) + (diff(cIdx1(2:3)))) = v1(:,:, cIdx1(2) + 1 : cIdx1(3)); %stimulus period

        maxDiff = min([segFrames1(3) + (diff(cIdx1(3:4))) segFrames1(5)]) - segFrames1(3); %maximal possible delay duration
        newV1(:,:, segFrames1(3) + 1 : segFrames1(3) + maxDiff) = v1(:,:, cIdx1(3) + 1 : cIdx1(3) + maxDiff); %delay period
        if segFrames1(4) + (diff(cIdx1(4:5))) > segFrames1(5)
            newV1(:,:, segFrames1(4) + 1 : segFrames1(5)) = v1(:,:, cIdx1(4) + 1 : cIdx1(4) + (segFrames1(5) - segFrames1(4))); %response period
        else
            newV1(:,:, segFrames1(4) + 1 : segFrames1(4) + (diff(cIdx1(4:5)))) = v1(:,:, cIdx1(4) + 1 : cIdx1(5)); %response period
        end
    else
        rejCnt1 = rejCnt1 + 1;
    end
    newV1 = newV1(:,:,1:segFrames1(end)); %experimental code
    newFrames(:,:,:,iTrials) = newV1;
    %stim2spout(iTrials) = cIdx1(4) - cIdx1(2);
    %delay2spout(iTrials) = cIdx1(4) - cIdx1(2);
end

if rejCnt1 > 0
    warning(['!!! Couldnt use ' num2str(rejCnt1) ' trials because of broken handle initialization time !!!'])
end
close(h);
%save(savepath,'newFrames','segFrames1','-v7.3');
%recursively call after doing processing
%[newFrames,segFrames1] = realignBhvVideo2(cPath, Animal, Rec, goodtrials, camnum, segIdx, opts);
end