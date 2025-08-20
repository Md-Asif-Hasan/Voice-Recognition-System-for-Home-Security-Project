function main()
% Voice Authentication System — End-to-end runner

addpath(genpath('.'));
set_random_seed(42);

% 1) Requirement Definition
cfg = config();
disp(cfg);

% 2) Data Collection (or load existing)
[dataTable, meta] = collect_data(cfg); % returns table: userId, commandId, condition, fs, audio

% 3) Preprocessing
for i = 1:height(dataTable)
    x = dataTable.audio{i};
    fs = dataTable.fs(i);
    x = preprocess_audio(x, fs, cfg);
    dataTable.audio{i} = x;
end

% 4) Feature Extraction
featTable = dataTable;
featTable.features = cell(height(featTable),1);
for i = 1:height(featTable)
    x = featTable.audio{i};
    fs = featTable.fs(i);
    feats = extract_features(x, fs, cfg);
    featTable.features{i} = feats;
end

% 5) Model Training
models = train_models(featTable, cfg);

% Save models
save_models(models, cfg);

% 6) Authentication Pipeline (demo on one sample)
testSample = featTable.features{1};
testUserTrue = featTable.userId(1);
[result, scores] = authenticate(testSample, models, cfg);

% 7) Decision System
[decision, decidedUser, details] = decision_system(scores, cfg);
fprintf('Auth result: %s | predictedUser=%d | trueUser=%d\n', decision, decidedUser, testUserTrue);
disp(details);

% 8) Real-Time Integration (GUI/Simulink stub)
% build_gui(cfg); % uncomment to launch basic UI
simulate_door(decision);

% 9) Testing & Validation
metrics = test_validation(featTable, models, cfg);
disp(metrics);

% 10) Deployment — print profiler hints
timer_profiler(@() authenticate(testSample, models, cfg), 'Authenticate inference');

end
