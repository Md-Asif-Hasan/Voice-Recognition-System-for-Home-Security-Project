function feats = extract_features(x, fs, cfg)
% Extract MFCC/LPC/Spectrogram features and concatenate

featCells = {};

% Frame params
frameLen = round(cfg.feat.frameLenMs*1e-3*fs);
hopLen   = round(cfg.feat.hopLenMs*1e-3*fs);

% MFCCs with optional deltas
if cfg.feat.useMFCC
    mf = compute_mfcc(x, fs, cfg.feat.mfcc.numCoeffs, frameLen, hopLen);
    if cfg.feat.mfcc.numDeltas >= 1
        dm = diff([mf(:,1), mf],1,2); % simple delta approx over time
        mf = [mf; dm];
    end
    if cfg.feat.mfcc.numDeltas >= 2
        ddm = diff([dm(:,1), dm],1,2);
        mf = [mf; ddm];
    end
    featCells{end+1} = mf(:);
end

% LPC
if cfg.feat.useLPC
    lpcv = compute_lpc(x, cfg.feat.lpc.order, frameLen, hopLen);
    featCells{end+1} = lpcv(:);
end

% Spectrogram features (e.g., log-mel or raw log-mag summary)
if cfg.feat.useSpec
    sv = compute_spectrogram_feats(x, fs, frameLen, hopLen);
    featCells{end+1} = sv(:);
end

feats = vertcat(featCells{:});

% Feature scaling per utterance (z-score)
if cfg.pre.featureScaling
    mu = mean(feats);
    sigma = std(feats) + 1e-6;
    feats = (feats - mu) ./ sigma;
end

end
