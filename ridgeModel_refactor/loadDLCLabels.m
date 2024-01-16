function [dlc_labels, event_frames] = loadDLCLabels(dpath, animal, rec, camera)
data = load([dpath filesep animal '.mat']);
rec = datetime(rec,'InputFormat','dd-MMM-yyyy');
rec.Format = 'MMM_dd_yyyy';
data = data.(animal).(string(rec));
event_frames = data.aligned_FrameTime;
dlc_labels = data.(camera);

fn = fieldnames(event_frames);
for k=1:numel(fn)
    if( isnumeric(event_frames.(fn{k})) )
        if strcmp(camera,'Lateral')
            temp = event_frames.(fn{k});
            event_frames.(fn{k}) = temp(1,:);
        elseif strcmp(camera,'Bottom')
            temp = event_frames.(fn{k});
            event_frames.(fn{k}) = temp(2,:);
        end
    end
end
end