%% test_bsr_policies.m
% BSR 정책 검증 (v0 ~ v3)
%
% 검증 내용:
%   - Baseline (v0): R = Q
%   - v1: 고정 적응형
%   - v2: 비례 적응형
%   - v3: 추세 기반 적응형
%
% 핵심: 상승 시 R=Q, 하락 시 R<Q

clear; close all; clc;

fprintf('========================================\n');
fprintf('  BSR 정책 검증 (v0-v3)\n');
fprintf('========================================\n\n');

%% 시뮬레이션 실행
schemes = [0, 1, 2, 3];
scheme_names = {'v0 (Baseline)', 'v1 (Fixed)', 'v2 (Proportional)', 'v3 (Trend)'};

cfg_base = config_default();
cfg_base.num_STAs = 20;
cfg_base.simulation_time = 10.0;
cfg_base.warmup_time = 2.0;
cfg_base.verbose = 0;
cfg_base.collect_bsr_trace = true;
cfg_base.L_cell = 0.6;

RNG_SEED = 42;

fprintf('시뮬레이션 실행 중...\n');
fprintf('  STA: %d, Time: %.1fs, Seed: %d\n\n', ...
    cfg_base.num_STAs, cfg_base.simulation_time, RNG_SEED);

results_all = cell(length(schemes), 1);
metrics_all = cell(length(schemes), 1);

for i = 1:length(schemes)
    cfg = cfg_base;
    cfg.scheme_id = schemes(i);
    
    fprintf('  [%d/4] %s... ', i, scheme_names{i});
    
    rng(RNG_SEED);
    [results, metrics] = main_sim_v2(cfg);
    
    results_all{i} = results;
    metrics_all{i} = metrics;
    
    fprintf('완료\n');
end

fprintf('\n');

%% 수치 검증
fprintf('========================================\n');
fprintf('  수치적 검증 (BSR 트레이스)\n');
fprintf('========================================\n');
fprintf('%-18s | %10s | %10s | %12s | %15s\n', ...
    'Policy', 'Total BSRs', 'Reductions', 'Freq. (%)', 'Mean Error (B)');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:length(schemes)
    try
        trace = metrics_all{i}.policy_level.trace;
        idx = 1:metrics_all{i}.policy_level.trace_idx;
        
        Q = trace.Q(idx);
        R = trace.R(idx);
        
        if isempty(Q)
            fprintf('%-18s | %10d | %10s | %12s | %15s\n', ...
                scheme_names{i}, 0, 'N/A', 'N/A', 'N/A');
            continue;
        end
        
        total_bsrs = length(Q);
        reduction_mask = (R < Q);
        reduction_count = sum(reduction_mask);
        
        if total_bsrs > 0
            reduction_freq = (reduction_count / total_bsrs) * 100;
        else
            reduction_freq = 0;
        end
        
        if reduction_count > 0
            mean_error = mean(Q(reduction_mask) - R(reduction_mask));
        else
            mean_error = 0;
        end
        
        fprintf('%-18s | %10d | %10d | %12.1f%% | %15.0f\n', ...
            scheme_names{i}, total_bsrs, reduction_count, reduction_freq, mean_error);
        
    catch ME
        fprintf('%-18s | Error: %s\n', scheme_names{i}, ME.message);
    end
end

fprintf('\n');

%% 버퍼 통계
fprintf('========================================\n');
fprintf('  버퍼 크기 통계\n');
fprintf('========================================\n');
fprintf('%-18s | %10s | %10s | %10s | %10s\n', ...
    'Policy', 'Avg Q (B)', 'p50 (B)', 'p90 (B)', 'Empty (#)');
fprintf('%s\n', repmat('-', 1, 65));

for i = 1:length(schemes)
    try
        trace = metrics_all{i}.policy_level.trace;
        idx = 1:metrics_all{i}.policy_level.trace_idx;
        
        Q = trace.Q(idx);
        
        if isempty(Q)
            fprintf('%-18s | %10s | %10s | %10s | %10s\n', ...
                scheme_names{i}, 'N/A', 'N/A', 'N/A', 'N/A');
            continue;
        end
        
        avg_q = mean(Q);
        p50_q = prctile(Q, 50);
        p90_q = prctile(Q, 90);
        empty_count = sum(Q == 0);
        
        fprintf('%-18s | %10.0f | %10.0f | %10.0f | %10d\n', ...
            scheme_names{i}, avg_q, p50_q, p90_q, empty_count);
        
    catch ME
        fprintf('%-18s | Error\n', scheme_names{i});
    end
end

fprintf('\n');

%% 검증 가이드
fprintf('========================================\n');
fprintf('  검증 가이드\n');
fprintf('========================================\n');
fprintf('  ✓ v0: Reduction Freq. = 0%% (R=Q 항상)\n');
fprintf('  ✓ v1, v2, v3: Reduction Freq. > 0%% (하락 시 감산)\n');
fprintf('  ✓ v1, v2, v3: Mean Error > 0 (실제 감산 적용)\n');
fprintf('  ✓ v3: 가장 안정적 (EMA 기반)\n');
fprintf('\n');

fprintf('========================================\n');
fprintf('  🎉 BSR 정책 검증 완료!\n');
fprintf('========================================\n\n');