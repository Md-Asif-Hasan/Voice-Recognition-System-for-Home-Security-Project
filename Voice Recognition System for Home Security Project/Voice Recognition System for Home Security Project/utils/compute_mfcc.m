function mf = compute_mfcc(x, fs, numCoeffs, frameLen, hopLen)
% Compute MFCCs averaged over time (D x T -> D x T kept)
% Uses mfcc if available; fallback to custom.

if exist('mfcc','file') == 2
    coeffs = mfcc(x, fs, 'WindowLength', frameLen, 'OverlapLength', frameLen - hopLen, ...
        'NumCoeffs', numCoeffs, 'LogEnergy','Ignore');
    mf = coeffs'; % D x T
else
    % Simple mel filterbank MFCC via auditoryFilterBank/mfcc-like pipeline could be implemented here
    % For brevity, use spectrogram cepstral summary as fallback
    nfft = 2^nextpow2(frameLen);
    [S,~,~] = stft(x,'Window',hann(frameLen,'periodic'),'OverlapLength',frameLen-hopLen,'FFTLength',nfft,'Centered',false);
    logMag = log(abs(S)+1e-6);
    c = dct(logMag);
    mf = c(1:numCoeffs, :);
end

end
