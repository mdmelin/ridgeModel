function correct_rate = getCorrectRate(bhv,window)
correct = bhv.CorrectSide == bhv.ResponseSide;
correct_rate = movmean(correct,window);
end