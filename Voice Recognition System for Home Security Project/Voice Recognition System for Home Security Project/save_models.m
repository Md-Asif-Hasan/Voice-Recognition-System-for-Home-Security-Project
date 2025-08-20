function save_models(models, cfg)
fname = fullfile(cfg.outDir, 'models.mat');
save(fname, 'models', '-v7.3');
fprintf('Models saved: %s\n', fname);
end
