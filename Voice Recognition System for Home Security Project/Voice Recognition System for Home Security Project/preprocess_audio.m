function x_out = preprocess_audio(x, fs, cfg)
% Noise reduction, VAD, normalization, scaling

x_proc = x(:);

% Basic de-mean
x_proc = x_proc - mean(x_proc);

% Noise reduction
if cfg.pre.noiseReduction
    x_proc = noise_reduce(x_proc, fs);
end

% VAD (trim silence)
if cfg.pre.vad
    x_proc = vad_simple(x_proc, fs);
end

% Normalization to unit RMS
if cfg.pre.normalize
    rmsv = sqrt(mean(x_proc.^2) + 1e-8);
    x_proc = x_proc / max(rmsv, 1e-3);
end

% Feature scaling handled in feature extractor level (mean-std per utterance)
x_out = x_proc;

end
