%% run_safety_sweep.m
% Phase A: 안전장치 파라미터 최적화
%
% 목표: v3의 효과를 극대화하는 안전장치 파라미터 찾기
%
% 실험 변수:
%   - burst_threshold: [5k, 10k, 20k] bytes
%   - reduction_threshold: [500, 1000, 2000] bytes
%   → 3×3 = 9 configurations
%
% 시나리오:
%   - Best 3: #7, #11, #18
%
% 각 config: Baseline + v3, 10 runs
% 총: 3 scenarios × 9 configs × 2 schemes × 10 runs = 540 sims
% 예상 시간: ~36분

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  Phase A: 안전장치 파라미터 Sweep\n');
fprintf('========================================\n\n');

%% 1. 실험 설계

% Best 3 시나리오 정의
scenarios = struct();

% Scenario #7: L=0.3, mu=0.01, rho=0.3, RA=1
scenarios(1).name = 'S7';
scenarios(1).L_cell = 0.3;
scenarios(1).mu_on = 0.01;
scenarios(1).rho = 0.3;
scenarios(1).RA_RU = 1;
scenarios(1).num_STAs = 20;

% % Scenario #11: L=0.3, mu=0.10, rho=0.3, RA=1
% scenarios(2).name = 'S11';
% scenarios(2).L_cell = 0.3;
% scenarios(2).mu_on = 0.10;
% scenarios(2).rho = 0.3;
% scenarios(2).RA_RU = 1;
% scenarios(2).num_STAs = 20;

% % Scenario #18: L=0.5, mu=0.10, rho=0.7, RA=1
% scenarios(3).name = 'S18';
% scenarios(3).L_cell = 0.5;
% scenarios(3).mu_on = 0.10;
% scenarios(3).rho = 0.7;
% scenarios(3).RA_RU = 1;
% scenarios(3).num_STAs = 20;

num_scenarios = length(scenarios);

% 파라미터 sweep
burst_threshold_values = [1000, 5000, 10000];  % bytes
reduction_threshold_values = [500, 1000, 2000];  % bytes

num_burst = length(burst_threshold_values);
num_reduction = length(reduction_threshold_values);
num_configs = num_burst * num_reduction;

% v3 고정 파라미터
v3_alpha = 0.10;
v3_max_red = 0.9;
v3_sensitivity = 1.0;

num_runs = 10;

fprintf('실험 설계:\n');
fprintf('  Scenarios: %d (Best 3)\n', num_scenarios);
for s = 1:num_scenarios
    fprintf('    %s: L=%.1f, mu=%.2f, rho=%.1f\n', ...
        scenarios(s).name, scenarios(s).L_cell, scenarios(s).mu_on, scenarios(s).rho);
end
fprintf('\n');

fprintf('  burst_threshold: %s bytes\n', mat2str(burst_threshold_values));
fprintf('  reduction_threshold: %s bytes\n', mat2str(reduction_threshold_values));
fprintf('  Total configs: %d\n\n', num_configs);

fprintf('  v3 파라미터 (고정):\n');
fprintf('    alpha: %.2f\n', v3_alpha);
fprintf('    max_reduction: %.2f\n', v3_max_red);
fprintf('    sensitivity: %.2f\n\n', v3_sensitivity);

fprintf('  Runs per config: %d\n', num_runs);

total_sims = num_scenarios * num_configs * 2 * num_runs;  % ×2 for baseline+v3
fprintf('  총 시뮬레이션: %d개\n', total_sims);
fprintf('  예상 시간: ~%.0f분\n\n', total_sims * 4 / 60);

%% 2. 결과 저장 구조

results = struct();
results.scenarios = scenarios;
results.burst_threshold_values = burst_threshold_values;
results.reduction_threshold_values = reduction_threshold_values;
results.v3_alpha = v3_alpha;
results.v3_max_red = v3_max_red;
results.v3_sensitivity = v3_sensitivity;
results.num_runs = num_runs;

% baseline: 각 시나리오당 1개 (config 무관)
results.baseline = cell(num_scenarios, num_runs);

% v3: 각 시나리오 × 각 config
results.v3 = cell(num_scenarios, num_configs, num_runs);

% Config 정보 저장
config_list = struct();
config_idx = 0;
for b_idx = 1:num_burst
    for r_idx = 1:num_reduction
        config_idx = config_idx + 1;
        config_list(config_idx).burst_threshold = burst_threshold_values(b_idx);
        config_list(config_idx).reduction_threshold = reduction_threshold_values(r_idx);
    end
end
results.config_list = config_list;

%% 3. 기본 설정

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

%% 4. 실험 실행

fprintf('========================================\n');
fprintf('  실험 실행 시작\n');
fprintf('========================================\n\n');

tic;
total_count = 0;
rng_seed_base = 2000;  % Phase A용 새로운 seed

% 중간 저장 파일
save_file = 'safety_sweep_results.mat';

for s_idx = 1:num_scenarios
    
    sc = scenarios(s_idx);
    
    fprintf('\n[Scenario %d/%d] %s (L=%.1f, mu=%.2f, rho=%.1f)\n', ...
        s_idx, num_scenarios, sc.name, sc.L_cell, sc.mu_on, sc.rho);
    fprintf('%s\n', repmat('-', 1, 70));
    
    % Scenario 기본 설정
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
    
    %% Baseline 실행 (1회만, config 무관)
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
    
    %% v3 실행 (9 configs)
    for c_idx = 1:num_configs
        
        config = config_list(c_idx);
        
        fprintf('  v3 [burst=%dk, red=%d]: ', ...
            config.burst_threshold/1000, config.reduction_threshold);
        
        for run = 1:num_runs
            
            rng(rng_seed_base + run);  % Baseline과 같은 seed
            cfg_run = cfg;
            cfg_run.scheme_id = 3;
            cfg_run.v3_EMA_alpha = v3_alpha;
            cfg_run.v3_max_reduction = v3_max_red;
            cfg_run.v3_sensitivity = v3_sensitivity;
            cfg_run.burst_threshold = config.burst_threshold;
            cfg_run.reduction_threshold = config.reduction_threshold;
            
            results.v3{s_idx, c_idx, run} = main_sim_v2(cfg_run);
            total_count = total_count + 1;
            
            fprintf('.');
        end
        
        fprintf(' (%d/%d, %.1f%%)\n', total_count, total_sims, ...
            total_count/total_sims*100);
    end
    
    % 시나리오별 중간 저장
    fprintf('  💾 중간 저장...\n');
    save(save_file, 'results', '-v7.3');
end

elapsed = toc;

%% 5. 최종 저장

fprintf('\n========================================\n');
fprintf('  실험 완료!\n');
fprintf('========================================\n\n');

fprintf('총 소요 시간: %.1f분 (%.2f시간)\n', elapsed/60, elapsed/3600);
fprintf('시뮬레이션당 평균: %.2f초\n\n', elapsed/total_sims);

save(save_file, 'results', '-v7.3');

fprintf('결과 저장: %s\n', save_file);
fprintf('파일 크기: %.1f MB\n\n', dir(save_file).bytes / 1024^2);

fprintf('다음 단계: analyze_safety_sweep.m 실행\n');
fprintf('========================================\n\n');