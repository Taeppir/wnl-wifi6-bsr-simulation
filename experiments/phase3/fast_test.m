%% 빠른 v3 작동 테스트
clear; close all;

% Baseline 설정
cfg = config_default();
cfg.scheme_id = 0;  % Baseline
cfg.L_cell = 0.15;
cfg.numRU_RA = 2;
cfg.num_STAs = 20;
cfg.numRU_SA = 8;
cfg.numRU_total = 10;
cfg.rho = 0.3;
cfg.mu_on = 0.05;
cfg.alpha = 1.5;
cfg.v3_EMA_alpha = 0.1;
cfg.v3_max_reduction = 0.7;
cfg.simulation_time = 10;
cfg.warmup_time = 1;
cfg.verbose = false;
cfg.collect_bsr_trace = false;
cfg = recompute_pareto_lambda(cfg);

fprintf('=== Baseline Test ===\n');
rng(3001);
[res_bl, ~] = main_sim_v2(cfg);
fprintf('Baseline P90: %.2f ms\n', res_bl.summary.p90_delay_ms);
fprintf('Baseline Mean: %.2f ms\n', res_bl.summary.mean_delay_ms);
fprintf('Baseline Coll: %.2f%%\n\n', res_bl.summary.collision_rate*100);

% v3 설정
cfg.scheme_id = 3;  % v3
fprintf('=== v3 Test ===\n');
rng(3001);  % 같은 시드!
[res_v3, ~] = main_sim_v2(cfg);
fprintf('v3 P90: %.2f ms\n', res_v3.summary.p90_delay_ms);
fprintf('v3 Mean: %.2f ms\n', res_v3.summary.mean_delay_ms);
fprintf('v3 Coll: %.2f%%\n\n', res_v3.summary.collision_rate*100);

% 비교
fprintf('=== 차이 ===\n');
fprintf('P90 개선: %.2f ms (%.1f%%)\n', ...
    res_bl.summary.p90_delay_ms - res_v3.summary.p90_delay_ms, ...
    (res_bl.summary.p90_delay_ms - res_v3.summary.p90_delay_ms) / res_bl.summary.p90_delay_ms * 100);
fprintf('Mean 개선: %.2f ms (%.1f%%)\n', ...
    res_bl.summary.mean_delay_ms - res_v3.summary.mean_delay_ms, ...
    (res_bl.summary.mean_delay_ms - res_v3.summary.mean_delay_ms) / res_bl.summary.mean_delay_ms * 100);