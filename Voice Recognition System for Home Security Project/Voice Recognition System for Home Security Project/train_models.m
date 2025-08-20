function models = train_models(featTable, cfg)
% Train SVM/KNN/DTW/NN models for speaker+command classification and verification

% Build labels:
% For closed-set identification: class = (userId,commandId)
% For verification: store per-user templates/statistics as needed
labels = arrayfun(@(u,c) sprintf('U%d_C%d', u,c), featTable.userId, featTable.commandId, 'uni', 0)';

X = cell2mat(cellfun(@(v) v(:), featTable.features, 'uni', 0));
% Dimension reduction for speed (optional)
% [coeff, Xproj] = pca(X','NumComponents',64); X = Xproj';

models = struct();
models.cfg = cfg;

% Split train/val
cv = cvpartition(numel(labels), 'HoldOut', 0.2);
trainIdx = training(cv); testIdx = test(cv);

Xtr = X(:,trainIdx)'; Ytr = labels(trainIdx);
Xte = X(:,testIdx)';  Yte = labels(testIdx);

% SVM
if cfg.model.useSVM
    t = templateLinear('Lambda',1e-4);
    svmMdl = fitcecoc(Xtr, Ytr, 'Learners', t, 'Coding','onevsone', 'Verbose',0);
    models.svm = svmMdl;
    % quick check
    yhat = predict(svmMdl, Xte);
    acc = mean(yhat==Yte);
    fprintf('[SVM] Val Acc: %.2f%% (%d/%d)\n', 100*acc, sum(yhat==Yte), numel(Yte));
end

% KNN
if cfg.model.useKNN
    knnMdl = fitcknn(Xtr, Ytr, 'NumNeighbors', cfg.knn.k, 'Standardize', true);
    models.knn = knnMdl;
    yhat = predict(knnMdl, Xte);
    acc = mean(yhat==Yte);
    fprintf('[KNN] Val Acc: %.2f%%\n', 100*acc);
end

% DTW templates per (user,command): keep raw time-ordered feature vectors before vectorization
% We need time-sequence features; rebuild per-sample sequence using sliding windows
sw = sliding_window_feats(featTable, cfg); % cell array of matrices T x D
models.dtw.templates = containers.Map;
keysList = {};
for i = 1:height(featTable)
    key = sprintf('U%d_C%d', featTable.userId(i), featTable.commandId(i));
    keysList{end+1} = key;
end
uniqKeys = unique(keysList);
for k = 1:numel(uniqKeys)
    key = uniqKeys{k};
    idx = strcmp(keysList, key);
    models.dtw.templates(key) = sw(idx);
end
models.dtw.use = cfg.model.useDTW;

% NN (compact)
if cfg.model.useNN
    Xn = Xtr'; Yn = grp2idx(Ytr)';
    Yn_onehot = full(ind2vec(Yn));
    net = patternnet(cfg.nn.hiddenSizes);
    net.trainParam.showWindow = false;
    net.trainParam.epochs = cfg.nn.maxEpochs;
    net = train(net, Xn, Yn_onehot);
    models.nn.net = net;
    models.nn.labelMap = unique(Ytr);
end

% Store class map
models.classLabels = unique(labels);

end
