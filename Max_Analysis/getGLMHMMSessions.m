function sessiondates = getGLMHMMSessions(cPath,animals,glmfile)
for i = 1:length(animals)
    fpath = [cPath filesep animals{i} filesep 'glm_hmm_models' filesep glmfile];
    dates = load(fpath).model_training_sessions;
    sessiondates{i}  = cellstr(dates);
end
end