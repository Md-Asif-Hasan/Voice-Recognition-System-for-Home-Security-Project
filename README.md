# Voice Authentication System (MATLAB)

A modular MATLAB project for speaker-based access control in home security. It supports end-to-end data collection, preprocessing, feature extraction (MFCC/LPC/spectrogram), multiple classifiers (SVM/KNN/DTW/optional NN), a decision system with thresholds, a basic GUI door lock simulation, testing/validation, and deployment-oriented optimizations.

## Features

- Multi-user, multi-command enrollment and verification
- Robust preprocessing: noise reduction, VAD trimming, normalization, feature scaling
- Flexible features: MFCC (+Δ/+ΔΔ), LPC, optional spectrogram summaries
- Multiple models: linear SVM, KNN, DTW templates, optional compact neural net
- Threshold-based decision system with majority voting and confidence aggregation
- Simple GUI to record and authenticate, with door lock simulation
- Testing utilities for k-fold accuracy, FAR/FRR, EER approximation
- Portable structure for embedded/edge deployment (MATLAB Coder friendly)

## Repository Structure

- main.m — Orchestrates the full workflow end to end
- config.m — Central requirement definition and system configuration
- collect_data.m — Records or loads samples per user/command/condition
- preprocess_audio.m — Denoise, VAD, normalize
- extract_features.m — MFCC/LPC/spec features and scaling
- train_models.m — Trains SVM/KNN/DTW/NN and builds templates
- save_models.m, load_models.m — Model I/O
- authenticate.m — Inference over one utterance, aggregates per-model scores
- decision_system.m — Threshold/margin policy, ALLOW/DENY decision
- build_gui.m — Minimal GUI for real-time record-and-authenticate
- simulate_door.m — Door lock/unlock print simulation
- test_validation.m — K-fold accuracy, FAR/FRR, EER approximation
- utils/
  - vad_simple.m — Energy-based VAD trimming
  - noise_reduce.m — Lightweight spectral gating
  - feature_scale.m — Z-scoring helper
  - compute_mfcc.m — MFCCs (uses mfcc if available, with fallback)
  - compute_lpc.m — Framewise LPC coefficients
  - compute_spectrogram_feats.m — Log-mag spectrogram band summaries
  - dtw_distance.m — DTW (uses built-in if available; else custom)
  - sliding_window_feats.m — Time-ordered MFCC sequences for DTW
  - set_random_seed.m — Reproducibility
  - timer_profiler.m — Quick latency profiling

## Requirements

- MATLAB R2021a or newer recommended
- Toolboxes:
  - Audio Toolbox (mfcc, stft/istft helpful but fallbacks provided)
  - Statistics and Machine Learning Toolbox (SVM/KNN/ECOC)
  - Signal Processing Toolbox (optional, for dtw if available)
  - Deep Learning Toolbox (optional, only if enabling the NN)
- Microphone access for data collection (or provide your own dataset)

## Quick Start

1) Clone or copy the project into a MATLAB working directory.

2) Open MATLAB and ensure the project folder is on the path:
   addpath(genpath('.'));

3) Configure the system in config.m:
- numUsers, commands
- samplesPerUserPerCommand, sampleDurationSec, fs
- feature toggles (MFCC/LPC/spec), model choices (SVM/KNN/DTW/NN)
- decision thresholds and target performance

4) Run the pipeline:
   main

5) Follow console prompts to record samples for each user/command under quiet/noisy conditions.

6) Optional: Launch the GUI after training:
   build_gui(config())

## Data Collection

- collect_data.m records audio per (user, command, condition).
- Conditions: “quiet” and “noisy” to improve robustness.
- For “noisy,” you can either record in a noisy environment or rely on light synthetic noise added in code.
- Replace collect_data.m with dataset loading logic if using a pre-recorded corpus.

Recommended recording tips:
- Speak consistent passphrases (e.g., “open door”, “close door”).
- Keep the microphone at a similar distance/angle across sessions.
- Capture at least 5–10 samples per user per command, in both quiet and noisy settings.

## Preprocessing

- Noise reduction: Wiener-like spectral gating with adaptive noise floor update.
- VAD: Simple energy-based trimming to remove leading/trailing silence.
- Normalization: Unit-RMS normalization for loudness invariance.
- Feature scaling: Per-utterance z-scoring in extract_features.m.

## Feature Extraction

- MFCCs: 13 coeffs by default, with optional delta and delta-delta.
- LPC: Order 12 by default; complements MFCCs with source-filter cues.
- Spectrogram: Optional log-magnitude band summaries for diversity.
- Frame parameters: 25ms window, 10ms hop (configurable).

Note: For DTW, time-ordered MFCC sequences are created via utils/sliding_window_feats.m.

## Model Training

- Closed-set labels: “U#_C#” (user and command).
- SVM: Linear ECOC for speed and generalization.
- KNN: Simple, standardized features; k configurable.
- DTW: Template lists per (user, command) built from sequences.
- NN (optional): Compact patternnet for low-parameter classification.
- Basic validation printed during training; models saved to models/models.mat.

## Authentication Pipeline

- authenticate.m:
  - Generates per-model predictions and confidence-like scores.
  - For SVM: margin between top-2 class scores.
  - For KNN: placeholder confidence (can be extended with distances).
  - For DTW: negative of best distance used as confidence proxy.
  - Majority vote with confidence tie-break produces a single predicted label and confidence.

- decision_system.m:
  - Aggregates scores, normalizes a rough confidence in , and applies threshold/margin rules.
  - Produces ALLOW/DENY, decided user, command id, and details.

## Real-Time Integration

- build_gui.m provides a simple GUI to:
  - Record 2s audio, preprocess, extract features, run authentication, and show decision.
  - simulate_door.m prints UNLOCKED/LOCKED to console.

For Simulink users:
- Wrap preprocess_audio, extract_features, authenticate, and decision_system in MATLAB Function blocks.
- Use UDP/Serial blocks to control an external actuator if needed.

## Testing & Validation

- test_validation.m:
  - 5-fold KNN accuracy over utterance-level classification.
  - Estimates FAR, FRR, and EER approximation using current decision policy over a subset.
  - Prints summary metrics and returns a struct for logging/plotting.

Recommended experiments:
- Vary noise reduction and VAD settings; check FAR/FRR trade-offs.
- Tune cfg.decision.threshold and evaluate impacts on EER.
- Try MFCC-only vs MFCC+LPC and measure latency and accuracy.

## Deployment and Optimization

- Reduce feature dimensionality: fewer MFCC coeffs (10–12), disable LPC/spec if latency-bound.
- Apply PCA to 32–64 dims for faster inference (add PCA in train_models.m).
- Prefer linear SVM or 1-NN; keep k small for KNN.
- Use single-precision where possible.
- Cache models, preallocate arrays, and avoid repeated recomputation.
- Use MATLAB Coder to generate C/C++ from preprocess_audio, extract_features, and authenticate for embedded targets (e.g., Raspberry Pi).
- Keep utterances short (1.5–2.0s) and enforce passphrase length.

## Security Considerations

- Add liveness checks:
  - Randomized prompts (“say 3–7–9” or “open door now” vs fixed phrase)
  - Replay attack detection via spectral artifacts or challenge-response timing
- Store embeddings/templates securely and encrypt model files at rest.
- Log attempts with timestamps and device IDs for audit trails.

## Customization

Common edits:
- config.m: adjust users, commands, sampling rate, frame sizes, deltas.
- collect_data.m: replace with dataset loader.
- extract_features.m: toggle MFCC/LPC/spec and deltas.
- train_models.m: switch models on/off; add PCA; tune SVM/KNN hyperparameters.
- decision_system.m: change threshold policy or add per-user thresholds.

## Troubleshooting

- Audio toolbox missing: compute_mfcc has a fallback; ensure stft/istft available or replace with spectrogram/overlap-add equivalents.
- dtw not found: utils/dtw_distance.m provides a custom implementation.
- Low accuracy:
  - Increase samples per user/command.
  - Ensure consistent enrollment conditions and clear speech.
  - Enable noise reduction and VAD; re-tune thresholds.
- High FAR (false accepts):
  - Raise cfg.decision.threshold.
  - Use DTW in addition to SVM/KNN for phrase-sensitive alignment.
  - Enforce randomized prompts per attempt.
- High latency:
  - Disable LPC/spec, reduce MFCC dims, apply PCA, prefer linear SVM.

## License

Specify a license for your project (e.g., MIT, Apache-2.0).

## Acknowledgments

- MATLAB toolboxes for audio processing and machine learning.
- Classic speech processing techniques: MFCCs, LPC, DTW, SVM/KNN pipelines.

## Citation

If this project contributes to academic work, consider citing it or acknowledging in the methods section as a MATLAB-based voice authentication prototype using MFCC/LPC features with SVM/KNN/DTW classifiers and a thresholded decision system.
