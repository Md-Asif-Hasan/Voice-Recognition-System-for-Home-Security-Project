function y = noise_reduce(x, fs)
% Lightweight spectral gating via Wiener-like filter
win = round(0.025*fs);
hop = round(0.010*fs);
nfft = 2^nextpow2(win);
[S,F,T] = stft(x,'Window',hann(win,'periodic'),'OverlapLength',win-hop,'FFTLength',nfft,'Centered',false);
mag = abs(S); phase = angle(S);

% Estimate noise floor from first 10 frames
nFrames = min(10, size(mag,2));
noiseSpec = median(mag(:,1:nFrames),2);
alpha = 0.98;
Y = zeros(size(S));
for t = 1:size(S,2)
    snrEst = (mag(:,t).^2) ./ (noiseSpec.^2 + 1e-8);
    gain = snrEst ./ (snrEst + 1);
    gain = max(0.1, min(1, gain));
    Y(:,t) = gain .* S(:,t);
    % adaptive noise update in low-energy frames
    if mean(mag(:,t)) < 1.2*mean(noiseSpec)
        noiseSpec = alpha*noiseSpec + (1-alpha)*mag(:,t);
    end
end
y = istft(Y,'Window',hann(win,'periodic'),'OverlapLength',win-hop,'FFTLength',nfft,'Centered',false);
y = real(y(:));
end
