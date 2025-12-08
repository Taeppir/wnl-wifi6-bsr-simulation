%% run_v3_sweep.m
% v3 효과 체계적 분석 (최적 파라미터)
%
% L_cell = [0.1, 0.3, 0.5]
% mu_on = [0.01, 0.05, 0.1, 0.5]
% RA_RU = [1, 2]
% rho = [0.3, 0.5, 0.7]
% → 72 scenarios
%
% 각 scenario: Baseline vs v3 (alpha=0.1, max_red=0.9) ⭐
% 각 10 runs (같은 seed로 공정 비교)
% 총 1440 시뮬레이션 (~2시간)

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  v3 효과 체계적 분석\n');
fprintf('========================================\n\n');

%% 실험 설정

L_cell_values = [0.1, 0.3, 0.5];
mu_on_values = [0.01, 0.05, 0.1];
RA_RU_values = [1];
rho_values = [0.3, 0.7];
num_runs = 5;

% v3 파라미터 고정
v3_alpha = 0.10;
v3_max_red = 0.9;  % ⭐ 최적값!

% Scenario 생성
scenarios = [];
scenario_idx = 0;
for L = L_cell_values
    for mu = mu_on_values
        for RA = RA_RU_values
            for rho = rho_values
                scenario_idx = scenario_idx + 1;
                scenarios(scenario_idx).L_cell = L;
                scenarios(scenario_idx).mu_on = mu;
                scenarios(scenario_idx).rho = rho;
                scenarios(scenario_idx).RA_RU = RA;
                scenarios(scenario_idx).num_STAs = 20;  % 고정
            end
        end
    end
end

num_scenarios = length(scenarios);
total_sims = num_scenarios * 2 * num_runs;

fprintf('실험 설계:\n');
fprintf('  L_cell: %s\n', mat2str(L_cell_values));
fprintf('  mu_on: %s\n', mat2str(mu_on_values));
fprintf('  RA_RU: %s\n', mat2str(RA_RU_values));
fprintf('  rho: %s\n', mat2str(rho_values));
fprintf('  num_STAs: 20 (고정)\n\n');

fprintf('  총 scenarios: %d\n', num_scenarios);
fprintf('  각 scenario: Baseline + v3\n');
fprintf('  각 %d runs\n', num_runs);
fprintf('  총 시뮬레이션: %d개\n\n', total_sims);

fprintf('v3 파라미터:\n');
fprintf('  EMA_alpha: %.2f\n', v3_alpha);
fprintf('  max_reduction: %.2f\n\n', v3_max_red);

% 결과 저장 구조
results = struct();
results.scenarios = scenarios;
results.num_runs = num_runs;
results.v3_alpha = v3_alpha;
results.v3_max_red = v3_max_red;
results.baseline = cell(num_scenarios, num_runs);
results.v3 = cell(num_scenarios, num_runs);

%% 기본 설정 로드

cfg_base = config_default();

% 안전장치
if ~isfield(cfg_base, 'max_packets_per_sta')
    cfg_base.max_packets_per_sta = 5000;
end
if ~isfield(cfg_base, 'max_delays')
    cfg_base.max_delays = 30000;
end

% 공통 설정
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

% 중간 저장 파일명
save_file = 'v3_sweep_results.mat';

for s_idx = 1:num_scenarios
    
    sc = scenarios(s_idx);
    
    fprintf('[%2d/%2d] L=%.1f, mu=%.2f, rho=%.1f, RA=%d: ', ...
        s_idx, num_scenarios, sc.L_cell, sc.mu_on, sc.rho, sc.RA_RU);
    
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
    
    % 10 runs
    for run = 1:num_runs
        
        % Baseline
        rng(rng_seed_base + run);
        cfg_run = cfg;
        cfg_run.scheme_id = 0;
        results.baseline{s_idx, run} = main_sim_v2(cfg_run);
        total_count = total_count + 1;
        
        % v3 (같은 seed!)
        rng(rng_seed_base + run);
        cfg_run = cfg;
        cfg_run.scheme_id = 3;
        cfg_run.v3_EMA_alpha = v3_alpha;
        cfg_run.v3_max_reduction = v3_max_red;
        results.v3{s_idx, run} = main_sim_v2(cfg_run);
        total_count = total_count + 1;
        
        fprintf('.');
    end
    
    fprintf(' %d/%d (%.1f%%)\n', total_count, total_sims, total_count/total_sims*100);
    
    % ⭐ 10 scenarios마다 중간 저장
    if mod(s_idx, 10) == 0
        fprintf('   💾 중간 저장 (scenario %d/%d)...', s_idx, num_scenarios);
        save(save_file, 'results', '-v7.3');
        fprintf(' 완료!\n');
    end
end

elapsed = toc;

fprintf('\n========================================\n');
fprintf('  실험 완료!\n');
fprintf('========================================\n\n');

fprintf('총 소요 시간: %.1f분 (%.2f시간)\n', elapsed/60, elapsed/3600);
fprintf('시뮬레이션당 평균: %.2f초\n\n', elapsed/total_sims);

%% 최종 저장

fprintf('\n========================================\n');
fprintf('  최종 저장\n');
fprintf('========================================\n\n');

save(save_file, 'results', '-v7.3');

fprintf('결과 저장: %s\n', save_file);
fprintf('파일 크기: %.1f MB\n\n', dir(save_file).bytes / 1024^2);

fprintf('다음 단계: analyze_v3_sweep.m 실행\n');
fprintf('========================================\n\n');