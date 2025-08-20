function sv = compute_spectrogram_feats(x, fs, frameLen, hopLen)
% Log-magnitude spectrogram summarized by frequency bands
nfft = 2^nextpow2(frameLen);
[S,~,~] = stft(x,'Window',hann(frameLen,'periodic'),'OverlapLength',frameLen-hopLen,'FFTLength',nfft,'Centered',false);
L = log(abs(S)+1e-6);
% Average over time in fixed bands (e.g., 20 bands)
nb = 20;
D = size(L,1);
edges = round(linspace(1,D,nb+1));
sv = zeros(nb, size(L,2));
for b = 1:nb
    sv(b,:) = mean(L(edges(b):edges(b+1),:),1);
end
end
