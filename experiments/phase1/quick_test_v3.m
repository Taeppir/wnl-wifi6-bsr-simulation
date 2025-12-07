%% quick_test_v3.m
% v3 효과 빠른 확인
%
% Scenario 1만 테스트 (Sweet Spot)
% Baseline vs v3 (alpha=0.1, max_red=0.7)
% 각 5 runs

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  v3 효과 빠른 확인\n');
fprintf('========================================\n\n');

%% 설정

num_runs = 5;
total_sims = num_runs * 2;

fprintf('Scenario: Sweet Spot (L=0.3, rho=0.7, mu_on=0.01, RA=2)\n');
fprintf('Baseline: %d runs\n', num_runs);
fprintf('v3: %d runs (alpha=0.1, max_red=0.7)\n', num_runs);
fprintf('총 시뮬레이션: %d개\n\n', total_sims);

%% Scenario config

%% Scenario config

% 기본 설정 로드
cfg = config_default();

% ⭐ 안전장치: 필수 필드 확인 및 추가
if ~isfield(cfg, 'max_packets_per_sta')
    cfg.max_packets_per_sta = 5000;
end
if ~isfield(cfg, 'max_delays')
    cfg.max_delays = 30000;
end

% Sweet Spot 파라미터로 덮어쓰기
cfg.num_STAs = 20;
cfg.numRU_RA = 1;
cfg.numRU_SA = 8;
cfg.numRU_total = cfg.numRU_RA + cfg.numRU_SA;

cfg.rho = 0.3;
cfg.mu_on = 0.01;
cfg.mu_off = cfg.mu_on * (1 - cfg.rho) / cfg.rho;

cfg.L_cell = 0.5;
cfg = recompute_pareto_lambda(cfg);

cfg.simulation_time = 10.0;
cfg.warmup_time = 0.0;

cfg.verbose = 0;  % 조용히
cfg.collect_bsr_trace = false;

%% 1. Baseline

fprintf('========================================\n');
fprintf('  1. Baseline\n');
fprintf('========================================\n');

baseline_results = cell(num_runs, 1);
rng_seed_base = 1000;  % ⭐ Seed 베이스

fprintf('실행 중: ');
tic;
for i = 1:num_runs
    fprintf('.');
    rng(rng_seed_base + i);  % ⭐ Run별 고정 seed
    cfg_run = cfg;
    cfg_run.scheme_id = 0;  % Baseline
    baseline_results{i} = main_sim_v2(cfg_run);
end
fprintf(' 완료!\n\n');

% 평균 계산
base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, baseline_results));
base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, baseline_results));
base_coll = mean(cellfun(@(x) x.uora.collision_rate, baseline_results));
base_expl = mean(cellfun(@(x) x.bsr.total_explicit, baseline_results));
base_impl = mean(cellfun(@(x) x.bsr.total_implicit, baseline_results));
base_total = mean(cellfun(@(x) x.bsr.total_bsr, baseline_results));
base_expl_ratio = base_expl / base_total * 100;
base_buf_empty = mean(cellfun(@(x) x.summary.buffer_empty_ratio, baseline_results)) * 100;

fprintf('Baseline 결과 (평균):\n');
fprintf('  Mean Delay: %.2f ms\n', base_delay);
fprintf('  P90 Delay: %.2f ms\n', base_p90);
fprintf('  Collision: %.2f%%\n', base_coll*100);
fprintf('  Explicit BSR: %.0f (%.1f%%)\n', base_expl, base_expl_ratio);
fprintf('  Implicit BSR: %.0f\n', base_impl);
fprintf('  Total BSR: %.0f\n', base_total);
fprintf('  Buffer Empty: %.1f%%\n\n', base_buf_empty);

%% 2. v3

fprintf('========================================\n');
fprintf('  2. v3 (alpha=0.1, max_red=0.7)\n');
fprintf('========================================\n');

v3_results = cell(num_runs, 1);

fprintf('실행 중: ');
for i = 1:num_runs
    fprintf('.');
    rng(rng_seed_base + i);  % ⭐ Baseline과 같은 seed!
    cfg_run = cfg;
    cfg_run.scheme_id = 3;  % v3
    cfg_run.v3_EMA_alpha = 0.10;
    cfg_run.v3_max_reduction = 0.7;
    v3_results{i} = main_sim_v2(cfg_run);
end
fprintf(' 완료!\n\n');

% 평균 계산
v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, v3_results));
v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, v3_results));
v3_coll = mean(cellfun(@(x) x.uora.collision_rate, v3_results));
v3_expl = mean(cellfun(@(x) x.bsr.total_explicit, v3_results));
v3_impl = mean(cellfun(@(x) x.bsr.total_implicit, v3_results));
v3_total = mean(cellfun(@(x) x.bsr.total_bsr, v3_results));
v3_expl_ratio = v3_expl / v3_total * 100;
v3_buf_empty = mean(cellfun(@(x) x.summary.buffer_empty_ratio, v3_results)) * 100;

fprintf('v3 결과 (평균):\n');
fprintf('  Mean Delay: %.2f ms\n', v3_delay);
fprintf('  P90 Delay: %.2f ms\n', v3_p90);
fprintf('  Collision: %.2f%%\n', v3_coll*100);
fprintf('  Explicit BSR: %.0f (%.1f%%)\n', v3_expl, v3_expl_ratio);
fprintf('  Implicit BSR: %.0f\n', v3_impl);
fprintf('  Total BSR: %.0f\n', v3_total);
fprintf('  Buffer Empty: %.1f%%\n\n', v3_buf_empty);

elapsed = toc;

%% 3. 비교

fprintf('========================================\n');
fprintf('  3. Baseline vs v3 비교\n');
fprintf('========================================\n\n');

delta_delay = v3_delay - base_delay;
delta_p90 = v3_p90 - base_p90;
delta_coll = (v3_coll - base_coll) * 100;
delta_expl = v3_expl - base_expl;
delta_impl = v3_impl - base_impl;
delta_total = v3_total - base_total;
delta_buf = v3_buf_empty - base_buf_empty;

improve_delay = -delta_delay / base_delay * 100;
improve_p90 = -delta_p90 / base_p90 * 100;
improve_coll = -delta_coll / (base_coll*100) * 100;
improve_expl = -delta_expl / base_expl * 100;
improve_buf = -delta_buf / base_buf_empty * 100;

fprintf('%-20s | %-12s %-12s %-12s %-12s\n', ...
    'Metric', 'Baseline', 'v3', 'Delta', 'Improve');
fprintf('%s\n', repmat('-', 1, 80));

fprintf('%-20s | %-12.2f %-12.2f %-12.2f %-12.2f%%\n', ...
    'Mean Delay [ms]', base_delay, v3_delay, delta_delay, improve_delay);
fprintf('%-20s | %-12.2f %-12.2f %-12.2f %-12.2f%%\n', ...
    'P90 Delay [ms]', base_p90, v3_p90, delta_p90, improve_p90);
fprintf('%-20s | %-12.2f %-12.2f %-12.2f %-12.2f%%\n', ...
    'Collision [%]', base_coll*100, v3_coll*100, delta_coll, improve_coll);
fprintf('%-20s | %-12.0f %-12.0f %-12.0f %-12.2f%%\n', ...
    'Explicit BSR', base_expl, v3_expl, delta_expl, improve_expl);
fprintf('%-20s | %-12.0f %-12.0f %-12.0f %-12s\n', ...
    'Implicit BSR', base_impl, v3_impl, delta_impl, '-');
fprintf('%-20s | %-12.0f %-12.0f %-12.0f %-12s\n', ...
    'Total BSR', base_total, v3_total, delta_total, '-');
fprintf('%-20s | %-12.1f %-12.1f %-12.1f %-12.2f%%\n', ...
    'Buffer Empty [%]', base_buf_empty, v3_buf_empty, delta_buf, improve_buf);

fprintf('\n');

%% 4. 결론

fprintf('========================================\n');
fprintf('  결론\n');
fprintf('========================================\n\n');

fprintf('총 소요 시간: %.1f분\n\n', elapsed/60);

if improve_expl > 5
    fprintf('✅ v3 효과 확인! (Explicit BSR %.1f%% 감소)\n', improve_expl);
    
    if improve_delay > 2
        fprintf('✅ Mean Delay도 %.1f%% 개선!\n', improve_delay);
    else
        fprintf('⚠️  Mean Delay 개선은 미미함 (%.1f%%)\n', improve_delay);
    end
    
    if improve_p90 > 2
        fprintf('✅ P90 Delay도 %.1f%% 개선!\n', improve_p90);
    else
        fprintf('⚠️  P90 Delay 개선은 미미함 (%.1f%%)\n', improve_p90);
    end
    
    if improve_coll > 2
        fprintf('✅ Collision도 %.1f%% 감소!\n', improve_coll);
    else
        fprintf('⚠️  Collision 개선은 미미함 (%.1f%%)\n', improve_coll);
    end
    
    if improve_buf > 2
        fprintf('✅ Buffer Empty도 %.1f%% 감소!\n', improve_buf);
    else
        fprintf('⚠️  Buffer Empty 변화 미미 (%.1f%%)\n', improve_buf);
    end
    
    fprintf('\n👉 다음 단계: 전체 파라미터 최적화 진행 추천\n');
    
elseif improve_expl > 0
    fprintf('⚠️  v3 효과 있지만 미미함 (%.1f%%)\n', improve_expl);
    
    if improve_delay > 0
        fprintf('   Mean Delay: %.1f%% 개선\n', improve_delay);
    else
        fprintf('   Mean Delay: %.1f%% 악화 ❌\n', abs(improve_delay));
    end
    
    if improve_p90 > 0
        fprintf('   P90 Delay: %.1f%% 개선\n', improve_p90);
    else
        fprintf('   P90 Delay: %.1f%% 악화 ❌\n', abs(improve_p90));
    end
    
    fprintf('👉 다른 시나리오 테스트 또는 파라미터 조정 필요\n');
    
else
    fprintf('❌ v3 효과 없음\n');
    fprintf('👉 근본 원인 분석 필요\n');
    fprintf('   - Explicit BSR ratio 확인: %.1f%%\n', base_expl_ratio);
    fprintf('   - RA-RU 설정 확인: %d\n', cfg.numRU_RA);
end

fprintf('\n========================================\n\n');