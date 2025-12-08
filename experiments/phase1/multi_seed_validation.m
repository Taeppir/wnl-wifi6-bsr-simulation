%% multi_seed_validation.m
% Multi-Seed 검증: 5 seeds × 3 scenarios × 20 runs
%
% Seeds: [1000, 2000, 3000, 4000, 5000]
% Scenarios: S7, S11, S18
% Runs per (seed, scenario): 20
%
% 총: 5 × 3 × 2 × 20 = 600 sims
% 예상 시간: ~40분

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  Multi-Seed 검증 실험\n');
fprintf('========================================\n\n');

%% 1. 실험 설계

% Seeds
seeds = [1000, 2000, 3000];
num_seeds = length(seeds);

% Scenarios
scenarios = struct();

scenarios(1).name = 'S7';
scenarios(1).id = 7;
scenarios(1).L_cell = 0.3;
scenarios(1).mu_on = 0.01;
scenarios(1).rho = 0.3;
scenarios(1).RA_RU = 1;
scenarios(1).num_STAs = 20;

% scenarios(2).name = 'S11';
% scenarios(2).id = 11;
% scenarios(2).L_cell = 0.3;
% scenarios(2).mu_on = 0.10;
% scenarios(2).rho = 0.3;
% scenarios(2).RA_RU = 1;
% scenarios(2).num_STAs = 20;

% scenarios(3).name = 'S18';
% scenarios(3).id = 18;
% scenarios(3).L_cell = 0.5;
% scenarios(3).mu_on = 0.10;
% scenarios(3).rho = 0.7;
% scenarios(3).RA_RU = 1;
% scenarios(3).num_STAs = 20;

num_scenarios = length(scenarios);

% 파라미터
v3_alpha = 0.10;
v3_sensitivity = 1.0;
v3_max_red = 0.90;
v3_burst = 1000;
v3_reduction = 500;

num_runs = 10;

fprintf('실험 설계:\n');
fprintf('  Seeds: %d개 %s\n', num_seeds, mat2str(seeds));
fprintf('  Scenarios: %d개\n', num_scenarios);
for s = 1:num_scenarios
    fprintf('    %s: L=%.1f, mu=%.2f, rho=%.1f\n', ...
        scenarios(s).name, scenarios(s).L_cell, scenarios(s).mu_on, scenarios(s).rho);
end
fprintf('  Runs per (seed, scenario): %d\n\n', num_runs);

fprintf('v3 파라미터:\n');
fprintf('  alpha:         %.2f\n', v3_alpha);
fprintf('  sensitivity:   %.2f\n', v3_sensitivity);
fprintf('  max_reduction: %.2f\n\n', v3_max_red);

total_sims = num_seeds * num_scenarios * 2 * num_runs;
fprintf('총 시뮬레이션: %d개\n', total_sims);
fprintf('예상 시간: ~%.0f분\n\n', total_sims * 4 / 60);

%% 2. 결과 저장 구조

results = struct();
results.seeds = seeds;
results.scenarios = scenarios;
results.v3_params = struct('alpha', v3_alpha, 'sensitivity', v3_sensitivity, ...
    'max_red', v3_max_red, 'burst', v3_burst, 'reduction', v3_reduction);
results.num_runs = num_runs;

% baseline(seed, scenario, run)
% v3(seed, scenario, run)
results.baseline = cell(num_seeds, num_scenarios, num_runs);
results.v3 = cell(num_seeds, num_scenarios, num_runs);

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
fprintf('  실험 실행\n');
fprintf('========================================\n\n');

tic;
total_count = 0;
save_file = 'multi_seed_validation.mat';

for seed_idx = 1:num_seeds
    
    seed_base = seeds(seed_idx);
    
    fprintf('\n[Seed %d/%d] base=%d\n', seed_idx, num_seeds, seed_base);
    fprintf('%s\n', repmat('=', 1, 70));
    
    for s_idx = 1:num_scenarios
        
        sc = scenarios(s_idx);
        
        fprintf('  [%s] L=%.1f, mu=%.2f, rho=%.1f\n', ...
            sc.name, sc.L_cell, sc.mu_on, sc.rho);
        
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
        fprintf('    Baseline: ');
        for run = 1:num_runs
            rng(seed_base + run);
            cfg_run = cfg;
            cfg_run.scheme_id = 0;
            results.baseline{seed_idx, s_idx, run} = main_sim_v2(cfg_run);
            total_count = total_count + 1;
            if mod(run, 5) == 0
                fprintf('.');
            end
        end
        fprintf('\n');
        
        %% v3
        fprintf('    v3:       ');
        for run = 1:num_runs
            rng(seed_base + run);
            cfg_run = cfg;
            cfg_run.scheme_id = 3;
            cfg_run.v3_EMA_alpha = v3_alpha;
            cfg_run.v3_sensitivity = v3_sensitivity;
            cfg_run.v3_max_reduction = v3_max_red;
            cfg_run.burst_threshold = v3_burst;
            cfg_run.reduction_threshold = v3_reduction;
            results.v3{seed_idx, s_idx, run} = main_sim_v2(cfg_run);
            total_count = total_count + 1;
            if mod(run, 5) == 0
                fprintf('.');
            end
        end
        fprintf(' (%d/%d, %.1f%%)\n', total_count, total_sims, ...
            total_count/total_sims*100);
    end
    
    % Seed별 중간 저장
    fprintf('  💾 중간 저장...\n');
    save(save_file, 'results', '-v7.3');
end

elapsed = toc;

%% 5. 결과 분석

fprintf('\n========================================\n');
fprintf('  결과 분석\n');
fprintf('========================================\n\n');

fprintf('총 소요 시간: %.1f분 (%.2f시간)\n\n', elapsed/60, elapsed/3600);

%% Seed별, Scenario별 정리

summary = struct();

for seed_idx = 1:num_seeds
    for s_idx = 1:num_scenarios
        
        % Baseline
        base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, ...
            squeeze(results.baseline(seed_idx, s_idx, :))));
        base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, ...
            squeeze(results.baseline(seed_idx, s_idx, :))));
        base_coll = mean(cellfun(@(x) x.uora.collision_rate, ...
            squeeze(results.baseline(seed_idx, s_idx, :))));
        
        % v3
        v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, ...
            squeeze(results.v3(seed_idx, s_idx, :))));
        v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, ...
            squeeze(results.v3(seed_idx, s_idx, :))));
        v3_coll = mean(cellfun(@(x) x.uora.collision_rate, ...
            squeeze(results.v3(seed_idx, s_idx, :))));
        
        % Improvement
        improve_delay = (base_delay - v3_delay) / base_delay * 100;
        improve_p90 = (base_p90 - v3_p90) / base_p90 * 100;
        improve_coll = (base_coll - v3_coll) / base_coll * 100;
        
        % 저장
        summary(seed_idx, s_idx).seed = seeds(seed_idx);
        summary(seed_idx, s_idx).scenario = scenarios(s_idx).name;
        summary(seed_idx, s_idx).base_delay = base_delay;
        summary(seed_idx, s_idx).v3_delay = v3_delay;
        summary(seed_idx, s_idx).improve_delay = improve_delay;
        summary(seed_idx, s_idx).improve_p90 = improve_p90;
        summary(seed_idx, s_idx).improve_coll = improve_coll;
    end
end

%% 6. Seed별 평균 출력

fprintf('========================================\n');
fprintf('  Seed별 평균 Improvement\n');
fprintf('========================================\n\n');

fprintf('%-6s | %-10s | %-10s | %-10s\n', 'Seed', 'Mean Delay', 'P90 Delay', 'Collision');
fprintf('%s\n', repmat('-', 1, 50));

for seed_idx = 1:num_seeds
    delay_avg = mean([summary(seed_idx, :).improve_delay]);
    p90_avg = mean([summary(seed_idx, :).improve_p90]);
    coll_avg = mean([summary(seed_idx, :).improve_coll]);
    
    fprintf('%5d  | %9.2f%% | %9.2f%% | %9.2f%%\n', ...
        seeds(seed_idx), delay_avg, p90_avg, coll_avg);
end

fprintf('\n');

%% 7. Scenario별 평균 출력

fprintf('========================================\n');
fprintf('  Scenario별 평균 Improvement\n');
fprintf('========================================\n\n');

fprintf('%-6s | %-10s | %-10s | %-10s\n', 'Scen', 'Mean Delay', 'P90 Delay', 'Collision');
fprintf('%s\n', repmat('-', 1, 50));

for s_idx = 1:num_scenarios
    delay_avg = mean([summary(:, s_idx).improve_delay]);
    p90_avg = mean([summary(:, s_idx).improve_p90]);
    coll_avg = mean([summary(:, s_idx).improve_coll]);
    
    fprintf('%5s  | %9.2f%% | %9.2f%% | %9.2f%%\n', ...
        scenarios(s_idx).name, delay_avg, p90_avg, coll_avg);
end

fprintf('\n');

%% 8. 전체 평균 (최종)

all_delay = [summary.improve_delay];
all_p90 = [summary.improve_p90];
all_coll = [summary.improve_coll];

fprintf('========================================\n');
fprintf('  전체 평균 (5 seeds × 3 scenarios)\n');
fprintf('========================================\n\n');

fprintf('Mean Delay:  %.2f%% ± %.2f%%\n', mean(all_delay), std(all_delay));
fprintf('P90 Delay:   %.2f%% ± %.2f%%\n', mean(all_p90), std(all_p90));
fprintf('Collision:   %.2f%% ± %.2f%%\n\n', mean(all_coll), std(all_coll));

fprintf('Range:\n');
fprintf('  Mean Delay:  %.2f%% ~ %.2f%%\n', min(all_delay), max(all_delay));
fprintf('  P90 Delay:   %.2f%% ~ %.2f%%\n', min(all_p90), max(all_p90));
fprintf('  Collision:   %.2f%% ~ %.2f%%\n\n', min(all_coll), max(all_coll));

%% 9. 저장

results.summary = summary;
save(save_file, 'results', '-v7.3');

fprintf('결과 저장: %s\n', save_file);
fprintf('파일 크기: %.1f MB\n\n', dir(save_file).bytes / 1024^2);

fprintf('========================================\n');
fprintf('  완료!\n');
fprintf('========================================\n\n');

fprintf('다음 단계: analyze_multi_seed.m 실행\n');