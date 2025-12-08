%% run_sensitivity_sweep.m
% Phase A - Step 2: Sensitivity 파라미터 최적화
%
% Step 1에서 찾은 best (burst_threshold, reduction_threshold)를 사용
% sensitivity만 sweep: [0.5, 0.8, 1.0, 1.2, 1.5, 2.0]
%
% 실험:
%   - Best 3 scenarios
%   - 6 sensitivity values
%   - Baseline + v3, 10 runs
%   - 총: 3 × 6 × 2 × 10 = 360 sims
%   - 예상 시간: ~24분

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  Phase A - Step 2: Sensitivity Sweep\n');
fprintf('========================================\n\n');

%% 1. Step 1 결과 대신 검증된 값 사용

% 검증된 최적값 (이전 v3_sweep 결과)
best_burst = 1000;
best_reduction = 500;

fprintf('========================================\n');
fprintf('  검증된 안전장치 파라미터 사용\n');
fprintf('========================================\n\n');

fprintf('✅ 사용할 Config (이전 실험에서 검증됨):\n');
fprintf('   burst_threshold: %d bytes\n', best_burst);
fprintf('   reduction_threshold: %d bytes\n\n', best_reduction);

% 시나리오 정의
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

% Sensitivity sweep
sensitivity_values = [0.8, 1.0, 1.2, 1.5, 2.0];
num_sensitivity = length(sensitivity_values);

% v3 고정 파라미터
v3_alpha = 0.10;
v3_max_red = 0.9;

num_runs = 10;

fprintf('========================================\n');
fprintf('  실험 설계\n');
fprintf('========================================\n\n');

fprintf('고정 파라미터:\n');
fprintf('  burst_threshold: %d bytes\n', best_burst);
fprintf('  reduction_threshold: %d bytes\n', best_reduction);
fprintf('  alpha: %.2f\n', v3_alpha);
fprintf('  max_reduction: %.2f\n\n', v3_max_red);

fprintf('Sensitivity sweep: %s\n', mat2str(sensitivity_values));
fprintf('Scenarios: %d (Best 3)\n', num_scenarios);
fprintf('Runs per config: %d\n\n', num_runs);

total_sims = num_scenarios * (1 + num_sensitivity) * num_runs;  % baseline + v3들
fprintf('총 시뮬레이션: %d개\n', total_sims);
fprintf('예상 시간: ~%.0f분\n\n', total_sims * 4 / 60);

%% 3. 결과 저장 구조

results_step2 = struct();
results_step2.scenarios = scenarios;
results_step2.sensitivity_values = sensitivity_values;
results_step2.best_burst_threshold = best_burst;
results_step2.best_reduction_threshold = best_reduction;
results_step2.v3_alpha = v3_alpha;
results_step2.v3_max_red = v3_max_red;
results_step2.num_runs = num_runs;

% Baseline: 새로 생성
results_step2.baseline = cell(num_scenarios, num_runs);

% v3: sensitivity별
results_step2.v3 = cell(num_scenarios, num_sensitivity, num_runs);

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
fprintf('  실험 실행 시작\n');
fprintf('========================================\n\n');

tic;
total_count = 0;
rng_seed_base = 1000;  % Step 2용 새로운 seed

save_file = 'sensitivity_sweep_results.mat';

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
    
    %% Baseline 실행
    fprintf('  Baseline: ');
    for run = 1:num_runs
        rng(rng_seed_base + run);
        cfg_run = cfg;
        cfg_run.scheme_id = 0;
        results_step2.baseline{s_idx, run} = main_sim_v2(cfg_run);
        total_count = total_count + 1;
        fprintf('.');
    end
    fprintf(' (%d/%d)\n', total_count, total_sims);
    
    %% v3 실행 (sensitivity별)
    for sens_idx = 1:num_sensitivity
        
        sens = sensitivity_values(sens_idx);
        
        fprintf('  v3 [sensitivity=%.1f]: ', sens);
        
        for run = 1:num_runs
            
            rng(rng_seed_base + run);
            cfg_run = cfg;
            cfg_run.scheme_id = 3;
            cfg_run.v3_EMA_alpha = v3_alpha;
            cfg_run.v3_max_reduction = v3_max_red;
            cfg_run.v3_sensitivity = sens;
            cfg_run.burst_threshold = best_burst;
            cfg_run.reduction_threshold = best_reduction;
            
            results_step2.v3{s_idx, sens_idx, run} = main_sim_v2(cfg_run);
            total_count = total_count + 1;
            
            fprintf('.');
        end
        
        fprintf(' (%d/%d, %.1f%%)\n', total_count, total_sims, ...
            total_count/total_sims*100);
    end
    
    % 시나리오별 중간 저장
    fprintf('  💾 중간 저장...\n');
    save(save_file, 'results_step2', '-v7.3');
end

elapsed = toc;

%% 6. 최종 저장

fprintf('\n========================================\n');
fprintf('  Step 2 완료!\n');
fprintf('========================================\n\n');

fprintf('총 소요 시간: %.1f분 (%.2f시간)\n', elapsed/60, elapsed/3600);
fprintf('시뮬레이션당 평균: %.2f초\n\n', elapsed/total_sims);

save(save_file, 'results_step2', '-v7.3');

fprintf('결과 저장: %s\n', save_file);
fprintf('파일 크기: %.1f MB\n\n', dir(save_file).bytes / 1024^2);

fprintf('다음 단계: analyze_sensitivity_sweep.m 실행\n');
fprintf('========================================\n\n');