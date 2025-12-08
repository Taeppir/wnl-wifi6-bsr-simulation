%% param_sweep_best2.m
% 최고 성능 시나리오 2개에서 v3 파라미터 극단 테스트
%
% Scenario #25: L=0.5, mu=0.01, rho=0.3, RA=1 (최고 성능)
% Scenario #17: L=0.3, mu=0.05, rho=0.3, RA=1 (2등, ExplR 높음)
%
% alpha = [0.05, 0.3, 0.5]  (빠른/느린 반응)
% max_reduction = [0.5, 0.9, 1.0]  (보수/공격적)
%
% 2 scenarios × (Baseline + 9 v3 configs) × 10 runs
% = 200 sims (~50분)

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  v3 파라미터 극단 테스트\n');
fprintf('  (Best 2 Scenarios)\n');
fprintf('========================================\n\n');

%% 실험 설정

% Best 2 scenarios
scenarios = [];

% Scenario #25
scenarios(1).name = '#25';
scenarios(1).L_cell = 0.5;
scenarios(1).mu_on = 0.01;
scenarios(1).rho = 0.3;
scenarios(1).RA_RU = 1;
scenarios(1).num_STAs = 20;

% Scenario #17
scenarios(2).name = '#17';
scenarios(2).L_cell = 0.3;
scenarios(2).mu_on = 0.05;
scenarios(2).rho = 0.3;
scenarios(2).RA_RU = 1;
scenarios(2).num_STAs = 20;

% v3 파라미터
alpha_values = [0.1, 0.5];
max_red_values = [0.5, 0.9];
num_runs = 5;

num_scenarios = length(scenarios);
num_configs = length(alpha_values) * length(max_red_values);
total_sims = num_scenarios * (1 + num_configs) * num_runs;  % Baseline + configs

fprintf('실험 설계:\n');
fprintf('  Scenarios: 2개 (#25, #17)\n');
fprintf('  alpha: %s\n', mat2str(alpha_values));
fprintf('  max_reduction: %s\n', mat2str(max_red_values));
fprintf('  각 %d runs\n\n', num_runs);

fprintf('  총 configs: Baseline + %d v3 configs\n', num_configs);
fprintf('  총 시뮬레이션: %d개\n\n', total_sims);

% 결과 저장 구조
results = struct();
results.scenarios = scenarios;
results.alpha_values = alpha_values;
results.max_red_values = max_red_values;
results.num_runs = num_runs;

% baseline: {scenario_idx, run}
% v3: {scenario_idx, config_idx, run}
results.baseline = cell(num_scenarios, num_runs);
results.v3 = cell(num_scenarios, num_configs, num_runs);

%% 기본 설정

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

%% 실험 실행

fprintf('========================================\n');
fprintf('  실험 실행 시작\n');
fprintf('========================================\n\n');

tic;
total_count = 0;
rng_seed_base = 1000;

for s_idx = 1:num_scenarios
    
    sc = scenarios(s_idx);
    
    fprintf('[Scenario %s] L=%.1f, mu=%.2f, rho=%.1f, RA=%d\n', ...
        sc.name, sc.L_cell, sc.mu_on, sc.rho, sc.RA_RU);
    
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
    fprintf('  Baseline (%d runs): ', num_runs);
    for run = 1:num_runs
        rng(rng_seed_base + run);
        cfg_run = cfg;
        cfg_run.scheme_id = 0;
        results.baseline{s_idx, run} = main_sim_v2(cfg_run);
        total_count = total_count + 1;
        fprintf('.');
    end
    fprintf(' %d/%d\n', total_count, total_sims);
    
    %% v3 configs
    config_idx = 0;
    for alpha = alpha_values
        for max_red = max_red_values
            config_idx = config_idx + 1;
            
            fprintf('  v3 [%d/%d] alpha=%.2f, max_red=%.1f: ', ...
                config_idx, num_configs, alpha, max_red);
            
            for run = 1:num_runs
                rng(rng_seed_base + run);  % Baseline과 같은 seed!
                cfg_run = cfg;
                cfg_run.scheme_id = 3;
                cfg_run.v3_EMA_alpha = alpha;
                cfg_run.v3_max_reduction = max_red;
                results.v3{s_idx, config_idx, run} = main_sim_v2(cfg_run);
                total_count = total_count + 1;
                fprintf('.');
            end
            fprintf(' %d/%d (%.1f%%)\n', total_count, total_sims, total_count/total_sims*100);
        end
    end
    
    fprintf('\n');
end

elapsed = toc;

fprintf('========================================\n');
fprintf('  실험 완료!\n');
fprintf('========================================\n\n');

fprintf('총 소요 시간: %.1f분 (%.2f시간)\n', elapsed/60, elapsed/3600);
fprintf('시뮬레이션당 평균: %.2f초\n\n', elapsed/total_sims);

%% 결과 저장

save_file = 'param_sweep_best2_results.mat';
save(save_file, 'results', '-v7.3');

fprintf('결과 저장: %s\n', save_file);
fprintf('파일 크기: %.1f MB\n\n', dir(save_file).bytes / 1024^2);

fprintf('다음 단계: analyze_param_sweep_best2.m 실행\n');
fprintf('========================================\n\n');