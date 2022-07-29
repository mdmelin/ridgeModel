function sessiondates = getAudioSessions(cPath,animals)
parfor i = 1:length(animals)
    [sessiondates{i},modalities{i}] = pythonGetSessionDates(cPath,animals{i});
end

for i = 1:length(animals) %this for loop grabs only audio sessions
    temp = sessiondates{i};
    sessiondates{i} = temp(modalities{i} == 2);
    clear temp;
end
end