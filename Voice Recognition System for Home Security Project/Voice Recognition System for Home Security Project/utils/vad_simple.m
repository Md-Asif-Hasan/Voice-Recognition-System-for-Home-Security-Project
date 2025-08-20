function x_out = vad_simple(x, fs)
% Simple energy-based VAD trimming
win = round(0.02*fs);
hop = round(0.01*fs);
n = numel(x);
idx = 1:hop:(n-win+1);
energy = zeros(numel(idx),1);
for i = 1:numel(idx)
    seg = x(idx(i):idx(i)+win-1);
    energy(i) = mean(seg.^2);
end
thr = median(energy) + 2*mad(energy,1);
mask = energy > thr;
if ~any(mask), x_out = x; return; end
first = idx(find(mask,1,'first'));
last  = idx(find(mask,1,'last')) + win - 1;
first = max(1, first - win);
last  = min(n, last + win);
x_out = x(first:last);
end
