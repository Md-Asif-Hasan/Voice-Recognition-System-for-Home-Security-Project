function d = dtw_distance(a, b)
% DTW distance between two sequences (vectors)
% If Signal Processing Toolbox dtw exists, use it:
if exist('dtw','file') == 2
    d = dtw(a(:), b(:));
    return;
end

A = a(:); B = b(:);
NA = numel(A); NB = numel(B);
D = inf(NA+1, NB+1); D(1,1) = 0;
for i = 2:NA+1
    for j = 2:NB+1
        cost = (A(i-1) - B(j-1))^2;
        D(i,j) = cost + min([D(i-1,j), D(i,j-1), D(i-1,j-1)]);
    end
end
d = sqrt(D(end,end)/max(1,NA+NB));
end
