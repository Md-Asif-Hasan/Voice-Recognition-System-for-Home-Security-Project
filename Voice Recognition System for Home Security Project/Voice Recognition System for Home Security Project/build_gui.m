function build_gui(cfg)
% Minimal GUI to record, authenticate, and simulate lock

h.f = figure('Name','Voice Access','Position',[100 100 360 240]);
uicontrol(h.f,'Style','text','Position',[20 190 320 20], 'String','Say: "open door" or "close door"');
h.recordBtn = uicontrol(h.f,'Style','pushbutton','String','Record & Authenticate','Position',[80 130 200 40], ...
    'Callback',@(s,e) onRecordAuthenticate(cfg));
h.status = uicontrol(h.f,'Style','text','Position',[20 80 320 20],'String','Status: idle');
h.result = uicontrol(h.f,'Style','text','Position',[20 50 320 20],'String','Result: -');
guidata(h.f, h);
end

function onRecordAuthenticate(cfg)
h = guidata(gcf);
set(h.status,'String','Recording...');

fs = cfg.fs; dur = 2.0;
recObj = audiorecorder(fs,16,1);
recordblocking(recObj, dur);
x = getaudiodata(recObj);

x = preprocess_audio(x, fs, cfg);
f = extract_features(x, fs, cfg);

models = load_models(cfg);
[res, scores] = authenticate(f, models, cfg);
[decision, userId, details] = decision_system(scores, cfg);
simulate_door(decision);

set(h.status,'String','Done.');
set(h.result,'String',sprintf('Decision: %s | User %d | Cmd %d | Conf %.2f', ...
    decision, userId, details.commandId, details.confidence));
end
