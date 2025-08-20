function metrics = test_validation(featTable, models, cfg)
% Test against impostors, accents, noise conditions.
% Here we do a simple k-fold speaker-command classification test.

labels = arrayfun(@(u,c) sprintf('U%d_C%d', u,c), featTable.userId, featTable.commandId, 'uni', 0)';
X = cell2mat(cellfun(@(v) v(:), featTable.features, 'uni', 0));

cv = cvpartition(numel(labels),'KFold',5);
accs = zeros(cv.NumTestSets,1);

for k = 1:cv.NumTestSets
    tr = training(cv,k); te = test(cv,k);
    Xtr = X(:,tr)'; Ytr = labels(tr);
    Xte = X(:,te)';  Yte = labels(te);

    % Refit a fast model (KNN) for evaluation
    mdl = fitcknn(Xtr, Ytr, 'NumNeighbors', cfg.knn.k, 'Standardize', true);
    yhat = predict(mdl, Xte);
    accs(k) = mean(yhat==Yte);
end

metrics.kfoldAccMean = mean(accs);
metrics.kfoldAccStd = std(accs);

% FAR/FRR estimation via threshold over confidence using current authenticate+decision
% Build probe set and compute decisions
N = min(100, height(featTable));
allowTrue = 0; allowFalse = 0; denyTrue = 0; denyFalse = 0;

for i = 1:N
    f = featTable.features{i};
    trueLbl = sprintf('U%d_C%d', featTable.userId(i), featTable.commandId(i));
    [~, scores] = authenticate(f, models, cfg);
    [decision, ~, details] = decision_system(scores, cfg);
    isGenuine = strcmp(details.label, trueLbl);
    if strcmp(decision,'ALLOW')
        if isGenuine, allowTrue = allowTrue + 1; else, allowFalse = allowFalse + 1; end
    else
        if isGenuine, denyFalse = denyFalse + 1; else, denyTrue = denyTrue + 1; end
    end
end

FAR = allowFalse / max(1,(allowFalse+denyTrue));
FRR = denyFalse / max(1,(allowTrue+denyFalse));

metrics.FAR = FAR;
metrics.FRR = FRR;
metrics.EERapprox = (FAR+FRR)/2;

fprintf('[Validation] Acc=%.2f±%.2f | FAR=%.3f FRR=%.3f EER≈%.3f\n', ...
    100*metrics.kfoldAccMean, 100*metrics.kfoldAccStd, FAR, FRR, metrics.EERapprox);
end
