function models = load_models(cfg)
fname = fullfile(cfg.outDir, 'models.mat');
S = load(fname);
models = S.models;
end
