function [Z, mu, sigma] = feature_scale(X)
mu = mean(X,1);
sigma = std(X,[],1) + 1e-6;
Z = (X - mu) ./ sigma;
end
