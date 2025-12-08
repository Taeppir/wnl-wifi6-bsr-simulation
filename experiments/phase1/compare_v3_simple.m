%% compare_v3_simple.m
% v3 (안전장치 있음) vs v3_simple (안전장치 없음) 비교
%
% 목표: 안전장치가 정말 필요한지 검증
%
% 실험:
%   - Best 3 scenarios
%   - Baseline, v3, v3_simple
%   - 각 10 runs
%   - 총: 3 × 3 × 10 = 90 sims
%   - 예상 시간: ~6분

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  v3 vs v3_simple 비교\n');
fprintf('========================================\n\n');

%% 1. 실험 설계

% Best 3 scenarios
scenarios = struct();

scenarios(1).name = 'S7';
scenarios(1).L_cell = 0.3;
scenarios(1).mu_on = 0.01;
scenarios(1).rho = 0.3;
scenarios(1).RA_RU = 1;
scenarios(1).num_STAs = 20;

scenarios(2).name = 'S11';
scenarios(2).L_cell = 0.3;
scenarios(2).mu_on = 0.10;
scenarios(2).rho = 0.3;
scenarios(2).RA_RU = 1;
scenarios(2).num_STAs = 20;

scenarios(3).name = 'S18';
scenarios(3).L_cell = 0.5;
scenarios(3).mu_on = 0.10;
scenarios(3).rho = 0.7;
scenarios(3).RA_RU = 1;
scenarios(3).num_STAs = 20;

num_scenarios = length(scenarios);
num_runs = 5;

fprintf('실험 설계:\n');
fprintf('  Scenarios: %d\n', num_scenarios);
fprintf('  Runs: %d\n', num_runs);
fprintf('  Schemes: Baseline, v3, v3_simple\n\n');

%% 2. 파라미터

% v3 (안전장치 있음)
v3_alpha = 0.10;
v3_sensitivity = 1.0;
v3_max_red = 0.9;
v3_burst = 1000;
v3_reduction = 500;

% v3_simple (안전장치 없음)
% - 같은 alpha, sensitivity, max_red
% - burst, reduction 사용 안 함

fprintf('v3 파라미터:\n');
fprintf('  alpha: %.2f\n', v3_alpha);
fprintf('  sensitivity: %.2f\n', v3_sensitivity);
fprintf('  max_reduction: %.2f\n', v3_max_red);
fprintf('  burst_threshold: %d\n', v3_burst);
fprintf('  reduction_threshold: %d\n\n', v3_reduction);

fprintf('v3_simple 파라미터:\n');
fprintf('  alpha: %.2f\n', v3_alpha);
fprintf('  sensitivity: %.2f\n', v3_sensitivity);
fprintf('  max_reduction: %.2f\n', v3_max_red);
fprintf('  burst_threshold: N/A (미사용)\n');
fprintf('  reduction_threshold: N/A (미사용)\n\n');

%% 3. 결과 저장

results = struct();
results.scenarios = scenarios;
results.num_runs = num_runs;
results.v3_params = struct('alpha', v3_alpha, 'sensitivity', v3_sensitivity, ...
    'max_red', v3_max_red, 'burst', v3_burst, 'reduction', v3_reduction);

results.baseline = cell(num_scenarios, num_runs);
results.v3 = cell(num_scenarios, num_runs);
results.v3_simple = cell(num_scenarios, num_runs);

%% 4. 기본 설정

cfg_base = config_default();

if ~isfield(cfg_base, 'max_packets_per_sta')
    cfg_base.max_packets_per_sta = 5000;
end
if ~isfield(cfg_base, 'max_delays')
    cfg_base.max_delays = 30000;
end

cfg_base.simulation_time = 10.0;
cfg_base.warmup_time = 0.0;
cfg_base.verbose = 0;
cfg_base.collect_bsr_trace = false;

%% 5. 실험 실행

fprintf('========================================\n');
fprintf('  실험 실행\n');
fprintf('========================================\n\n');

tic;
total_count = 0;
total_sims = num_scenarios * 3 * num_runs;
rng_seed_base = 4000;

save_file = 'v3_simple_comparison.mat';

for s_idx = 1:num_scenarios
    
    sc = scenarios(s_idx);
    
    fprintf('\n[Scenario %d/%d] %s (L=%.1f, mu=%.2f, rho=%.1f)\n', ...
        s_idx, num_scenarios, sc.name, sc.L_cell, sc.mu_on, sc.rho);
    fprintf('%s\n', repmat('-', 1, 70));
    
    % Scenario 설정
    cfg = cfg_base;
    cfg.num_STAs = sc.num_STAs;
    cfg.numRU_RA = sc.RA_RU;
    cfg.numRU_total = 9;
    cfg.numRU_SA = cfg.numRU_total - cfg.numRU_RA;
    
    cfg.rho = sc.rho;
    cfg.mu_on = sc.mu_on;
    cfg.mu_off = cfg.mu_on * (1 - cfg.rho) / cfg.rho;
    
    cfg.L_cell = sc.L_cell;
    cfg = recompute_pareto_lambda(cfg);
    
    %% Baseline
    fprintf('  Baseline: ');
    for run = 1:num_runs
        rng(rng_seed_base + run);
        cfg_run = cfg;
        cfg_run.scheme_id = 0;
        results.baseline{s_idx, run} = main_sim_v2(cfg_run);
        total_count = total_count + 1;
        fprintf('.');
    end
    fprintf(' (%d/%d)\n', total_count, total_sims);
    
    %% v3 (안전장치 있음)
    fprintf('  v3:       ');
    for run = 1:num_runs
        rng(rng_seed_base + run);
        cfg_run = cfg;
        cfg_run.scheme_id = 3;
        cfg_run.v3_EMA_alpha = v3_alpha;
        cfg_run.v3_sensitivity = v3_sensitivity;
        cfg_run.v3_max_reduction = v3_max_red;
        cfg_run.burst_threshold = v3_burst;
        cfg_run.reduction_threshold = v3_reduction;
        results.v3{s_idx, run} = main_sim_v2(cfg_run);
        total_count = total_count + 1;
        fprintf('.');
    end
    fprintf(' (%d/%d)\n', total_count, total_sims);
    
    %% v3_simple (안전장치 없음)
    fprintf('  v3_simple:');
    for run = 1:num_runs
        rng(rng_seed_base + run);
        cfg_run = cfg;
        cfg_run.scheme_id = 3;
        cfg_run.v3_EMA_alpha = v3_alpha;
        cfg_run.v3_sensitivity = v3_sensitivity;
        cfg_run.v3_max_reduction = v3_max_red;
        cfg_run.v3_use_simple = true;  % 간소화 버전 사용
        results.v3_simple{s_idx, run} = main_sim_v2(cfg_run);
        total_count = total_count + 1;
        fprintf('.');
    end
    fprintf(' (%d/%d)\n', total_count, total_sims);
    
    % 중간 저장
    save(save_file, 'results', '-v7.3');
end

elapsed = toc;

%% 6. 결과 분석

fprintf('\n========================================\n');
fprintf('  결과 분석\n');
fprintf('========================================\n\n');

fprintf('총 소요 시간: %.1f분\n\n', elapsed/60);

for s = 1:num_scenarios
    
    sc = scenarios(s);
    
    % Baseline
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.baseline(s, :)));
    base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.baseline(s, :)));
    base_coll = mean(cellfun(@(x) x.uora.collision_rate, results.baseline(s, :)));
    
    % v3
    v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.v3(s, :)));
    v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.v3(s, :)));
    v3_coll = mean(cellfun(@(x) x.uora.collision_rate, results.v3(s, :)));
    
    % v3_simple
    simple_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.v3_simple(s, :)));
    simple_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.v3_simple(s, :)));
    simple_coll = mean(cellfun(@(x) x.uora.collision_rate, results.v3_simple(s, :)));
    
    % Improvement
    v3_imp_delay = (base_delay - v3_delay) / base_delay * 100;
    v3_imp_p90 = (base_p90 - v3_p90) / base_p90 * 100;
    v3_imp_coll = (base_coll - v3_coll) / base_coll * 100;
    
    simple_imp_delay = (base_delay - simple_delay) / base_delay * 100;
    simple_imp_p90 = (base_p90 - simple_p90) / base_p90 * 100;
    simple_imp_coll = (base_coll - simple_coll) / base_coll * 100;
    
    fprintf('[%s] L=%.1f, mu=%.2f, rho=%.1f\n', sc.name, sc.L_cell, sc.mu_on, sc.rho);
    fprintf('─────────────────────────────────────────────────────\n');
    fprintf('%-15s | %-12s | %-12s | %-12s\n', '', 'Baseline', 'v3', 'v3_simple');
    fprintf('─────────────────────────────────────────────────────\n');
    fprintf('%-15s | %10.2f ms | %10.2f ms | %10.2f ms\n', 'Mean Delay', base_delay, v3_delay, simple_delay);
    fprintf('%-15s | %12s | %10.2f%% | %10.2f%%\n', 'Improvement', '-', v3_imp_delay, simple_imp_delay);
    fprintf('\n');
    fprintf('%-15s | %10.2f ms | %10.2f ms | %10.2f ms\n', 'P90 Delay', base_p90, v3_p90, simple_p90);
    fprintf('%-15s | %12s | %10.2f%% | %10.2f%%\n', 'Improvement', '-', v3_imp_p90, simple_imp_p90);
    fprintf('\n');
    fprintf('%-15s | %11.2f%% | %11.2f%% | %11.2f%%\n', 'Collision', base_coll*100, v3_coll*100, simple_coll*100);
    fprintf('%-15s | %12s | %10.2f%% | %10.2f%%\n', 'Improvement', '-', v3_imp_coll, simple_imp_coll);
    fprintf('\n\n');
end

%% 7. 저장

save(save_file, 'results', '-v7.3');
fprintf('결과 저장: %s\n', save_file);
fprintf('파일 크기: %.1f MB\n\n', dir(save_file).bytes / 1024^2);

fprintf('========================================\n');
fprintf('  완료!\n');
fprintf('========================================\n\n');