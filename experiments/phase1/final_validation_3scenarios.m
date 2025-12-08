%% final_validation_3scenarios.m
% 최종 검증: 3 scenarios, 최적 파라미터
%
% 파라미터:
%   alpha = 0.10
%   sensitivity = 1.0
%   max_reduction = 0.90
%
% Scenarios: S7, S11, S18
% Runs: 20 (publication quality)
% 예상 시간: ~24분

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  최종 검증 - Best 3 Scenarios\n');
fprintf('========================================\n\n');

%% 1. 시나리오 정의

scenarios = struct();

% Scenario #7: L=0.3, mu=0.01, rho=0.3, RA=1
scenarios(1).name = 'S7';
scenarios(1).id = 7;
scenarios(1).L_cell = 0.3;
scenarios(1).mu_on = 0.01;
scenarios(1).rho = 0.3;
scenarios(1).RA_RU = 1;
scenarios(1).num_STAs = 20;

% Scenario #11: L=0.3, mu=0.10, rho=0.3, RA=1
scenarios(2).name = 'S11';
scenarios(2).id = 11;
scenarios(2).L_cell = 0.3;
scenarios(2).mu_on = 0.10;
scenarios(2).rho = 0.3;
scenarios(2).RA_RU = 1;
scenarios(2).num_STAs = 20;

% Scenario #18: L=0.5, mu=0.10, rho=0.7, RA=1
scenarios(3).name = 'S18';
scenarios(3).id = 18;
scenarios(3).L_cell = 0.5;
scenarios(3).mu_on = 0.10;
scenarios(3).rho = 0.7;
scenarios(3).RA_RU = 1;
scenarios(3).num_STAs = 20;

num_scenarios = length(scenarios);

%% 2. 최적 파라미터

v3_alpha = 0.10;
v3_sensitivity = 1.0;
v3_max_red = 0.90;
v3_burst = 1000;
v3_reduction = 500;

num_runs = 20;

fprintf('실험 설계:\n');
fprintf('  Scenarios: %d\n', num_scenarios);
for s = 1:num_scenarios
    fprintf('    %s (ID=%d): L=%.1f, mu=%.2f, rho=%.1f\n', ...
        scenarios(s).name, scenarios(s).id, scenarios(s).L_cell, ...
        scenarios(s).mu_on, scenarios(s).rho);
end
fprintf('\n');

fprintf('최적 파라미터:\n');
fprintf('  alpha:         %.2f\n', v3_alpha);
fprintf('  sensitivity:   %.2f\n', v3_sensitivity);
fprintf('  max_reduction: %.2f\n', v3_max_red);
fprintf('  burst:         %d bytes\n', v3_burst);
fprintf('  reduction:     %d bytes\n\n', v3_reduction);

fprintf('  Runs per scenario: %d\n', num_runs);

total_sims = num_scenarios * 2 * num_runs;
fprintf('  총 시뮬레이션: %d개\n', total_sims);
fprintf('  예상 시간: ~%.0f분\n\n', total_sims * 4 / 60);

%% 3. 결과 저장

results = struct();
results.scenarios = scenarios;
results.v3_alpha = v3_alpha;
results.v3_sensitivity = v3_sensitivity;
results.v3_max_red = v3_max_red;
results.v3_burst = v3_burst;
results.v3_reduction = v3_reduction;
results.num_runs = num_runs;

results.baseline = cell(num_scenarios, num_runs);
results.v3 = cell(num_scenarios, num_runs);

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
rng_seed_base = 5000;  % 새로운 seed

save_file = 'final_validation_3scenarios.mat';

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
        if mod(run, 5) == 0
            fprintf('.');
        end
    end
    fprintf(' (%d/%d)\n', total_count, total_sims);
    
    %% v3
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
        if mod(run, 5) == 0
            fprintf('.');
        end
    end
    fprintf(' (%d/%d, %.1f%%)\n', total_count, total_sims, ...
        total_count/total_sims*100);
    
    % 중간 저장
    fprintf('  💾 중간 저장...\n');
    save(save_file, 'results', '-v7.3');
end

elapsed = toc;

%% 6. 결과 분석

fprintf('\n========================================\n');
fprintf('  결과 분석\n');
fprintf('========================================\n\n');

fprintf('총 소요 시간: %.1f분\n\n', elapsed/60);

summary = struct();

for s = 1:num_scenarios
    
    sc = scenarios(s);
    
    % Baseline
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.baseline(s, :)));
    base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.baseline(s, :)));
    base_p10 = mean(cellfun(@(x) x.summary.p10_delay_ms, results.baseline(s, :)));
    base_coll = mean(cellfun(@(x) x.uora.collision_rate, results.baseline(s, :)));
    base_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.baseline(s, :)));
    base_total = mean(cellfun(@(x) x.bsr.total_bsr, results.baseline(s, :)));
    
    % v3
    v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.v3(s, :)));
    v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.v3(s, :)));
    v3_p10 = mean(cellfun(@(x) x.summary.p10_delay_ms, results.v3(s, :)));
    v3_coll = mean(cellfun(@(x) x.uora.collision_rate, results.v3(s, :)));
    v3_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.v3(s, :)));
    v3_total = mean(cellfun(@(x) x.bsr.total_bsr, results.v3(s, :)));
    
    % Improvement
    improve_delay = (base_delay - v3_delay) / base_delay * 100;
    improve_p90 = (base_p90 - v3_p90) / base_p90 * 100;
    improve_p10 = (base_p10 - v3_p10) / base_p10 * 100;
    improve_coll = (base_coll - v3_coll) / base_coll * 100;
    
    % 저장
    summary(s).name = sc.name;
    summary(s).base_delay = base_delay;
    summary(s).v3_delay = v3_delay;
    summary(s).improve_delay = improve_delay;
    summary(s).base_p90 = base_p90;
    summary(s).v3_p90 = v3_p90;
    summary(s).improve_p90 = improve_p90;
    summary(s).base_coll = base_coll;
    summary(s).v3_coll = v3_coll;
    summary(s).improve_coll = improve_coll;
    summary(s).expl_ratio = base_expl / base_total * 100;
    
    % 출력
    fprintf('[%s] L=%.1f, mu=%.2f, rho=%.1f\n', ...
        sc.name, sc.L_cell, sc.mu_on, sc.rho);
    fprintf('─────────────────────────────────────────────────────\n');
    fprintf('%-15s | Baseline    | v3          | Improvement\n', '');
    fprintf('─────────────────────────────────────────────────────\n');
    fprintf('%-15s | %9.2f ms | %9.2f ms | %10.2f%%\n', 'Mean Delay', ...
        base_delay, v3_delay, improve_delay);
    fprintf('%-15s | %9.2f ms | %9.2f ms | %10.2f%%\n', 'P10 Delay', ...
        base_p10, v3_p10, improve_p10);
    fprintf('%-15s | %9.2f ms | %9.2f ms | %10.2f%%\n', 'P90 Delay', ...
        base_p90, v3_p90, improve_p90);
    fprintf('%-15s | %10.2f%% | %10.2f%% | %10.2f%%\n', 'Collision', ...
        base_coll*100, v3_coll*100, improve_coll);
    fprintf('%-15s | %10.2f%% | %12s | %12s\n', 'ExplR', ...
        base_expl/base_total*100, '-', '-');
    fprintf('\n');
end

%% 7. 전체 평균

avg_delay = mean([summary.improve_delay]);
avg_p90 = mean([summary.improve_p90]);
avg_coll = mean([summary.improve_coll]);

fprintf('========================================\n');
fprintf('  전체 평균 (3 scenarios)\n');
fprintf('========================================\n\n');

fprintf('Mean Delay:  %.2f%% 개선\n', avg_delay);
fprintf('P90 Delay:   %.2f%% 개선\n', avg_p90);
fprintf('Collision:   %.2f%% 개선\n\n', avg_coll);

%% 8. 저장

results.summary = summary;
save(save_file, 'results', '-v7.3');

fprintf('결과 저장: %s\n', save_file);
fprintf('파일 크기: %.1f MB\n\n', dir(save_file).bytes / 1024^2);

fprintf('========================================\n');
fprintf('  완료!\n');
fprintf('========================================\n\n');