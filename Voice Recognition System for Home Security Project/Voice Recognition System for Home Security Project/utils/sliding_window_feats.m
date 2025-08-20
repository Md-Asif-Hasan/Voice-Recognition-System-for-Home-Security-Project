function sw = sliding_window_feats(featTable, cfg)
% Create sequence features per sample: concatenate MFCC-only frames if available.
% Here we reconstruct from raw audio again for DTW sequences to preserve time order.

sw = cell(height(featTable),1);
for i = 1:height(featTable)
    x = featTable.audio{i};
    fs = featTable.fs(i);
    frameLen = round(cfg.feat.frameLenMs*1e-3*fs);
    hopLen   = round(cfg.feat.hopLenMs*1e-3*fs);
    M = compute_mfcc(x, fs, cfg.feat.mfcc.numCoeffs, frameLen, hopLen); % D x T
    sw{i} = M'; % T x D
end
end
