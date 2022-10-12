%return array of session dates and the performance for each day
function [dates,modalities] = pythonGetSessionDates(cPath,Animal)
[dates,modalities] = pyrunfile("C:\Data\churchland\glm-hmm\glm_helperfuncs\datahandling.py",["session_dates","modalities"],dpath=cPath,mouse=Animal);
dates2 = string(cell(dates));
clear dates;
for i = 1:length(dates2)
    dates{i} = char(dates2(i));
end
modalities = cell2mat(cell(modalities));
end