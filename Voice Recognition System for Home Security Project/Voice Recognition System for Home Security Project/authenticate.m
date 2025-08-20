function [result, scores] = authenticate(testFeatures, models, cfg)
% Returns:
% - result: struct with per-model predicted label and confidence
% - scores: struct with per-user similarity/confidence for decision_system

scores = struct();

% Vector form for SVM/KNN/NN
xv = testFeatures(:)';

% SVM
if isfield(models,'svm')
    [yhat, score] = predict(models.svm, xv);
    scores.svm.label = yhat{1};
    if size(score,2) >= 2
        margins = sort(score,2,'descend');
        conf = margins(1) - margins(2);
    else
        conf = 0;
    end
    scores.svm.confidence = conf;
end

% KNN
if isfield(models,'knn')
    yhat = predict(models.knn, xv);
    scores.knn.label = yhat{1};
    % No native probability: use inverse distance heuristic
    % Here we simulate with 1 (best) since fitcknn doesn't expose distances by default in predict
    scores.knn.confidence = 0; 
end

% NN
if isfield(models,'nn')
    net = models.nn.net;
    y = net(xv');
    [~, idx] = max(y);
    lbl = models.nn.labelMap(idx);
    scores.nn.label = lbl{1};
    scores.nn.confidence = max(y) - max(y(y<max(y)));
end

% DTW (sequence alignment)
if isfield(models,'dtw') && models.dtw.use
    % Recreate sequence matrix T x D from feature vector by using sliding_window_feats format
    % For production: pass sequence directly; here we approximate with a single-frame sequence
    seqTest = testFeatures(:);
    bestKey = '';
    bestDist = inf;
    keys = models.dtw.templates.keys;
    for i = 1:numel(keys)
        k = keys{i};
        templList = models.dtw.templates(k);
        % compare to centroid template (choose shortest median length)
        dmin = inf;
        for t = 1:numel(templList)
            T = templList{t};
            if isvector(T), T = T(:); end
            d = dtw_distance(seqTest, T(:));
            if d < dmin, dmin = d; end
        end
        if dmin < bestDist
            bestDist = dmin; bestKey = k;
        end
    end
    scores.dtw.label = bestKey;
    scores.dtw.distance = bestDist;
end

% Consolidate result — pick the modal label across enabled models
labels = {};
confs  = [];
if isfield(scores,'svm'), labels{end+1} = scores.svm.label; confs(end+1) = scores.svm.confidence; end
if isfield(scores,'knn'), labels{end+1} = scores.knn.label; confs(end+1) = scores.knn.confidence; end
if isfield(scores,'nn'),  labels{end+1} = scores.nn.label;  confs(end+1) = scores.nn.confidence;  end
if isfield(scores,'dtw'), labels{end+1} = scores.dtw.label; confs(end+1) = -scores.dtw.distance; end

if isempty(labels)
    result.label = '';
    result.confidence = 0;
else
    % majority vote with confidence tie-break
    [ulbl,~,ic] = unique(labels);
    counts = accumarray(ic,1);
    [~,mx] = max(counts);
    maj = ulbl{mx};
    % tie-break by max confidence among those with 'maj'
    idxMaj = find(strcmp(labels, maj));
    [~,ib] = max(confs(idxMaj));
    result.label = maj;
    result.confidence = confs(idxMaj(ib));
end

end
