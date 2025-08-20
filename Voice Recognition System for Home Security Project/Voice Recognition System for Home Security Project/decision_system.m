function [decision, decidedUser, details] = decision_system(scores, cfg)
% Convert classifier labels to user decision and apply thresholds

% Parse label "U#_C#" to userId, commandId
extractUC = @(s) deal(sscanf(s,'U%d'), sscanf(s, 'U%d_C%d'));

candidates = {};

if isfield(scores,'svm') && isfield(scores.svm,'label')
    candidates{end+1} = scores.svm.label;
end
if isfield(scores,'knn') && isfield(scores.knn,'label')
    candidates{end+1} = scores.knn.label;
end
if isfield(scores,'nn') && isfield(scores.nn,'label')
    candidates{end+1} = scores.nn.label;
end
if isfield(scores,'dtw') && isfield(scores.dtw,'label')
    candidates{end+1} = scores.dtw.label;
end

if isempty(candidates)
    decision = 'DENY';
    decidedUser = -1;
    details = struct('reason','No candidates');
    return;
end

% Frequency of candidates
[ulbl,~,ic] = unique(candidates);
counts = accumarray(ic,1);
[~,mx] = max(counts);
bestLbl = ulbl{mx};

% Confidence score
conf = 0;
if isfield(scores,'svm'), if strcmp(scores.svm.label,bestLbl), conf = conf + max(0,scores.svm.confidence); end, end
if isfield(scores,'knn'), if strcmp(scores.knn.label,bestLbl), conf = conf + max(0,scores.knn.confidence); end, end
if isfield(scores,'dtw'), if strcmp(scores.dtw.label,bestLbl)
        conf = conf + 1/(1+scores.dtw.distance);
    end
end

% Normalize conf into [0,1] roughly
conf = min(1, conf / 2);

% Apply decision policy
switch cfg.decision.method
    case 'threshold'
        allow = conf >= cfg.decision.threshold;
    case 'score_margin'
        % Simple rule: require conf above threshold; otherwise deny
        allow = conf >= cfg.decision.threshold;
    otherwise
        allow = conf >= 0.5;
end

% Extract user
tokens = regexp(bestLbl, 'U(\d+)_C(\d+)', 'tokens', 'once');
if isempty(tokens)
    decidedUser = -1; cmd = -1;
else
    decidedUser = str2double(tokens{1});
    cmd = str2double(tokens{2});
end

decision = ternary(allow, 'ALLOW', 'DENY');
details = struct('label', bestLbl, 'confidence', conf, 'commandId', cmd);

end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
