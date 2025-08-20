function lpcv = compute_lpc(x, order, frameLen, hopLen)
% Frame-wise LPC coefficients concatenated
n = numel(x);
idx = 1:hopLen:(n-frameLen+1);
D = order+1;
lpcv = zeros(D, numel(idx));
for i = 1:numel(idx)
    seg = x(idx(i):idx(i)+frameLen-1) .* hann(frameLen);
    a = lpc(seg, order);
    lpcv(:,i) = a(:);
end
end
