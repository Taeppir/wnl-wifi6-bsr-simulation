%% bsr_trace_test.m
% BSR trace 수집 및 저장
%
% Scenario #17: L=0.3, mu=0.05, rho=0.3, RA=1
% Baseline vs v3 (alpha=0.10, max_red=0.9)
%
% 각 1 run, BSR trace 수집

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  BSR Trace 수집\n');
fprintf('========================================\n\n');

%% 실험 설정

% Scenario #17 (최고 성능)
sc.L_cell = 0.3;
sc.mu_on = 0.05;
sc.rho = 0.3;
sc.RA_RU = 1;
sc.num_STAs = 20;

% v3 최적 파라미터
v3_alpha = 0.10;
v3_max_red = 0.9;

num_runs = 10;  % ⭐ 10 runs
rng_seed_base = 1000;

fprintf('Scenario: L=%.1f, mu=%.2f, rho=%.1f, RA=%d\n', ...
    sc.L_cell, sc.mu_on, sc.rho, sc.RA_RU);
fprintf('v3 params: alpha=%.2f, max_red=%.1f\n', v3_alpha, v3_max_red);
fprintf('Runs: %d\n\n', num_runs);

%% 기본 설정

cfg = config_default();

if ~isfield(cfg, 'max_packets_per_sta')
    cfg.max_packets_per_sta = 5000;
end
if ~isfield(cfg, 'max_delays')
    cfg.max_delays = 30000;
end

% Scenario 설정
cfg.num_STAs = sc.num_STAs;
cfg.numRU_RA = sc.RA_RU;
cfg.numRU_total = 9;
cfg.numRU_SA = cfg.numRU_total - cfg.numRU_RA;

cfg.rho = sc.rho;
cfg.mu_on = sc.mu_on;
cfg.mu_off = cfg.mu_on * (1 - cfg.rho) / cfg.rho;

cfg.L_cell = sc.L_cell;
cfg = recompute_pareto_lambda(cfg);

cfg.simulation_time = 10.0;
cfg.warmup_time = 0.0;
cfg.verbose = 0;

% ⭐ BSR trace 수집!
cfg.collect_bsr_trace = true;

%% 1. Baseline

fprintf('========================================\n');
fprintf('  1. Baseline (%d runs)\n', num_runs);
fprintf('========================================\n');

result_baseline = cell(num_runs, 1);

fprintf('실행 중: ');
tic;
for run = 1:num_runs
    fprintf('.');
    rng(rng_seed_base + run);
    cfg_base = cfg;
    cfg_base.scheme_id = 0;
    result_baseline{run} = main_sim_v2(cfg_base);
end
elapsed_base = toc;
fprintf(' 완료! (%.1f초)\n\n', elapsed_base);

% 평균 계산
base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, result_baseline));
base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, result_baseline));
base_coll = mean(cellfun(@(x) x.uora.collision_rate, result_baseline));
base_expl = mean(cellfun(@(x) x.bsr.total_explicit, result_baseline));
base_total = mean(cellfun(@(x) x.bsr.total_bsr, result_baseline));
base_expl_ratio = base_expl / base_total * 100;

% UORA delay 통계
base_uora_mean = mean(cellfun(@(x) x.bsr.mean_uora_delay, result_baseline));
base_uora_std = mean(cellfun(@(x) x.bsr.std_uora_delay, result_baseline));

fprintf('Baseline 결과 (평균):\n');
fprintf('  Mean Delay: %.2f ms\n', base_delay);
fprintf('  P90 Delay: %.2f ms\n', base_p90);
fprintf('  Collision: %.2f%%\n', base_coll*100);
fprintf('  Explicit BSR: %.0f (%.1f%%)\n', base_expl, base_expl_ratio);
fprintf('  Total BSR: %.0f\n', base_total);
fprintf('  UORA Mean: %.2f ms, Std: %.2f ms\n', base_uora_mean*1000, base_uora_std*1000);
fprintf('\n');

%% 2. v3 (최적)

fprintf('========================================\n');
fprintf('  2. v3 (alpha=%.2f, max_red=%.1f, %d runs)\n', v3_alpha, v3_max_red, num_runs);
fprintf('========================================\n');

result_v3 = cell(num_runs, 1);

fprintf('실행 중: ');
for run = 1:num_runs
    fprintf('.');
    rng(rng_seed_base + run);  % Baseline과 같은 seed!
    cfg_v3 = cfg;
    cfg_v3.scheme_id = 3;
    cfg_v3.v3_EMA_alpha = v3_alpha;
    cfg_v3.v3_max_reduction = v3_max_red;
    result_v3{run} = main_sim_v2(cfg_v3);
end
elapsed_v3 = toc;
fprintf(' 완료! (%.1f초)\n\n', elapsed_v3);

% 평균 계산
v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, result_v3));
v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, result_v3));
v3_coll = mean(cellfun(@(x) x.uora.collision_rate, result_v3));
v3_expl = mean(cellfun(@(x) x.bsr.total_explicit, result_v3));
v3_total = mean(cellfun(@(x) x.bsr.total_bsr, result_v3));
v3_expl_ratio = v3_expl / v3_total * 100;

% UORA delay 통계
v3_uora_mean = mean(cellfun(@(x) x.bsr.mean_uora_delay, result_v3));
v3_uora_std = mean(cellfun(@(x) x.bsr.std_uora_delay, result_v3));

fprintf('v3 결과 (평균):\n');
fprintf('  Mean Delay: %.2f ms\n', v3_delay);
fprintf('  P90 Delay: %.2f ms\n', v3_p90);
fprintf('  Collision: %.2f%%\n', v3_coll*100);
fprintf('  Explicit BSR: %.0f (%.1f%%)\n', v3_expl, v3_expl_ratio);
fprintf('  Total BSR: %.0f\n', v3_total);
fprintf('  UORA Mean: %.2f ms, Std: %.2f ms\n', v3_uora_mean*1000, v3_uora_std*1000);
fprintf('\n');

%% 3. 비교

fprintf('========================================\n');
fprintf('  3. Baseline vs v3 비교\n');
fprintf('========================================\n\n');

improve_delay = (base_delay - v3_delay) / base_delay * 100;
improve_p90 = (base_p90 - v3_p90) / base_p90 * 100;
improve_coll = (base_coll - v3_coll) / base_coll * 100;
improve_expl = (base_expl - v3_expl) / base_expl * 100;

% UORA variability
improve_uora_std = (base_uora_std - v3_uora_std) / base_uora_std * 100;

fprintf('Improvement:\n');
fprintf('  Mean Delay: %.2f%%\n', improve_delay);
fprintf('  P90 Delay: %.2f%%\n', improve_p90);
fprintf('  Collision: %.2f%%\n', improve_coll);
fprintf('  Explicit BSR: %.2f%%\n', improve_expl);
fprintf('  UORA Std: %.2f%%\n\n', improve_uora_std);

%% 4. 결과 저장

results = struct();
results.scenario = sc;
results.v3_alpha = v3_alpha;
results.v3_max_red = v3_max_red;
results.baseline = result_baseline;
results.v3 = result_v3;

save_file = 'bsr_trace_results.mat';
save(save_file, 'results', '-v7.3');

fprintf('결과 저장: %s\n', save_file);
fprintf('파일 크기: %.1f MB\n\n', dir(save_file).bytes / 1024^2);

fprintf('다음 단계: analyze_bsr_trace.m 실행\n');
fprintf('========================================\n\n');