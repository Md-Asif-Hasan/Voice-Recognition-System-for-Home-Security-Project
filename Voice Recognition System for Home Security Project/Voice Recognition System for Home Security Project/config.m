function cfg = config()
% Requirement Definition and general configuration

% Users and commands
cfg.numUsers = 4;
cfg.userIds = 1:cfg.numUsers;

cfg.commands = ["open door","close door"];
cfg.numCommands = numel(cfg.commands);

% Target performance
cfg.targetAccuracy = 0.95;
cfg.maxLatencyMs = 150;

% Data collection
cfg.samplesPerUserPerCommand = 6; % e.g., 3 quiet + 3 noisy
cfg.sampleDurationSec = 2.0;
cfg.fs = 16e3;
cfg.conditions = ["quiet","noisy"];

% Preprocessing
cfg.pre.noiseReduction = true;
cfg.pre.vad = true;
cfg.pre.normalize = true;
cfg.pre.featureScaling = true;

% Feature Extraction
cfg.feat.useMFCC = true;
cfg.feat.mfcc.numCoeffs = 13;
cfg.feat.mfcc.numDeltas = 2; % 0,1,2 for delta/delta-delta
cfg.feat.useLPC = true;
cfg.feat.lpc.order = 12;
cfg.feat.useSpec = false; % optional
cfg.feat.frameLenMs = 25;
cfg.feat.hopLenMs = 10;

% Classifiers (choose one or several; authenticate aggregates)
cfg.model.useSVM = true;
cfg.model.useKNN = true;
cfg.model.useDTW = true;  % template-based per user/command
cfg.model.useNN  = false; % optional small NN

% KNN
cfg.knn.k = 3;

% SVM
cfg.svm.kernel = 'linear'; % 'linear' for speed

% NN
cfg.nn.hiddenSizes = [32];
cfg.nn.maxEpochs = 100;

% Decision thresholds
cfg.decision.method = 'score_margin'; % 'threshold' or 'score_margin'
cfg.decision.threshold = 0.6; % for normalized similarity
cfg.decision.margin = 0.1;

% Storage
cfg.outDir = 'models';
if ~exist(cfg.outDir, 'dir'), mkdir(cfg.outDir); end

end
