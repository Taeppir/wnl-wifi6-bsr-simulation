%% check_phase0_metrics.m
% Phase 0에 필요한 지표가 제대로 수집되는지 확인
%
% 목적:
%   - ANALYZE_RESULTS_v2에서 Phase 0 필수 지표가 모두 수집되는지 검증
%   - 누락된 지표나 NaN 값 확인

clear; close all; clc;

fprintf('========================================\n');
fprintf('  Phase 0 지표 수집 확인\n');
fprintf('========================================\n\n');

%% =====================================================================
%  1. 테스트 시뮬레이션 실행
%  =====================================================================

fprintf('[1/3] 테스트 시뮬레이션 실행 중...\n');

cfg = config_default();
cfg.verbose = 0;
cfg.num_STAs = 20;
cfg.simulation_time = 10.0;
cfg.warmup_time = 0.0;
cfg.L_cell = 0.30;
cfg.mu_on = 0.02;
cfg.rho = 0.3;
cfg.scheme_id = 0;  % Baseline
cfg.collect_bsr_trace = true;

rng(42);
[results, ~] = main_sim_v2(cfg);

fprintf('  ✓ 완료 (%.1f초)\n\n', cfg.simulation_time);

%% =====================================================================
%  2. Phase 0 필수 지표 확인
%  =====================================================================

fprintf('[2/3] Phase 0 필수 지표 확인\n');
fprintf('----------------------------------------\n');

required_metrics = struct();
all_present = true;

% Category 1: 지연 (Delay)
fprintf('\n[Category 1: 지연]\n');
required_metrics.delay = {
    'mean_delay', 'results.packet_level.mean_delay';
    'p10_delay', 'results.packet_level.p10_delay';
    'p50_delay', 'results.packet_level.p50_delay';
    'p90_delay', 'results.packet_level.p90_delay';
    'p99_delay', 'results.packet_level.p99_delay';
};

for i = 1:size(required_metrics.delay, 1)
    metric_name = required_metrics.delay{i, 1};
    metric_path = required_metrics.delay{i, 2};
    
    value = eval(metric_path);
    
    if ~isnan(value) && value >= 0
        fprintf('  ✅ %-20s: %.4f sec\n', metric_name, value);
    else
        fprintf('  ❌ %-20s: NaN or invalid\n', metric_name);
        all_present = false;
    end
end

% Category 2: UORA 효율
fprintf('\n[Category 2: UORA 효율]\n');
required_metrics.uora = {
    'collision_rate', 'results.uora.collision_rate';
    'success_rate', 'results.uora.success_rate';
    'idle_rate', 'results.uora.idle_rate';
    'total_attempts', 'results.uora.total_attempts';
};

for i = 1:size(required_metrics.uora, 1)
    metric_name = required_metrics.uora{i, 1};
    metric_path = required_metrics.uora{i, 2};
    
    value = eval(metric_path);
    
    if ~isnan(value) && value >= 0
        if contains(metric_name, 'rate')
            fprintf('  ✅ %-20s: %.2f%%\n', metric_name, value * 100);
        else
            fprintf('  ✅ %-20s: %d\n', metric_name, value);
        end
    else
        fprintf('  ❌ %-20s: NaN or invalid\n', metric_name);
        all_present = false;
    end
end

% Category 3: BSR 타입
fprintf('\n[Category 3: BSR 타입]\n');
required_metrics.bsr = {
    'total_explicit', 'results.bsr.total_explicit';
    'total_implicit', 'results.bsr.total_implicit';
    'explicit_ratio', 'results.bsr.explicit_ratio';
    'implicit_ratio', 'results.bsr.implicit_ratio';
};

for i = 1:size(required_metrics.bsr, 1)
    metric_name = required_metrics.bsr{i, 1};
    metric_path = required_metrics.bsr{i, 2};
    
    value = eval(metric_path);
    
    if ~isnan(value) && value >= 0
        if contains(metric_name, 'ratio')
            fprintf('  ✅ %-20s: %.2f%%\n', metric_name, value * 100);
        else
            fprintf('  ✅ %-20s: %d\n', metric_name, value);
        end
    else
        fprintf('  ❌ %-20s: NaN or invalid\n', metric_name);
        all_present = false;
    end
end

% Category 4: 큐 상태 ⭐⭐⭐
fprintf('\n[Category 4: 큐 상태] ⭐ 핵심 지표\n');
required_metrics.queue = {
    'buffer_empty_ratio', 'results.bsr.buffer_empty_ratio';
    'buffer_empty_time_per_sta', 'results.bsr.buffer_empty_time_per_sta';
};

for i = 1:size(required_metrics.queue, 1)
    metric_name = required_metrics.queue{i, 1};
    metric_path = required_metrics.queue{i, 2};
    
    value = eval(metric_path);
    
    if ~isnan(value) && value >= 0
        if contains(metric_name, 'ratio')
            fprintf('  ✅ %-30s: %.2f%%\n', metric_name, value * 100);
        else
            fprintf('  ✅ %-30s: %.4f sec\n', metric_name, value);
        end
    else
        fprintf('  ❌ %-30s: NaN or invalid\n', metric_name);
        all_present = false;
    end
end

% Category 5: 지연 분해
fprintf('\n[Category 5: 지연 분해]\n');
required_metrics.decomp = {
    'mean_uora_delay', 'results.bsr.mean_uora_delay';
    'p90_uora_delay', 'results.bsr.p90_uora_delay';
    'mean_sched_delay', 'results.bsr.mean_sched_delay';
    'p90_sched_delay', 'results.bsr.p90_sched_delay';
    'mean_overhead_delay', 'results.bsr.mean_overhead_delay';
    'mean_frag_delay', 'results.packet_level.mean_frag_delay';
};

for i = 1:size(required_metrics.decomp, 1)
    metric_name = required_metrics.decomp{i, 1};
    metric_path = required_metrics.decomp{i, 2};
    
    value = eval(metric_path);
    
    if ~isnan(value) && value >= 0
        fprintf('  ✅ %-25s: %.4f sec\n', metric_name, value);
    else
        fprintf('  ⚠️  %-25s: NaN (비어있을 수 있음)\n', metric_name);
        % T_overhead, T_frag은 조건에 따라 0일 수 있으므로 경고만
    end
end

fprintf('\n');

%% =====================================================================
%  3. 지표 요약
%  =====================================================================

fprintf('[3/3] 지표 요약\n');
fprintf('----------------------------------------\n\n');

fprintf('✅ 필수 지표 수집 상태: ');
if all_present
    fprintf('모두 정상\n');
else
    fprintf('일부 누락 (위 ❌ 항목 확인)\n');
end

fprintf('\n📊 Phase 0 실험에 필요한 지표:\n');
fprintf('  1. 지연: Mean, P10, P50, P90, P99\n');
fprintf('  2. UORA: Collision/Success/Idle rate\n');
fprintf('  3. BSR: Explicit/Implicit count & ratio\n');
fprintf('  4. 큐 상태: Buffer empty ratio ⭐\n');
fprintf('  5. 지연 분해: T_uora, T_sched, T_overhead, T_frag\n');

fprintf('\n');

%% =====================================================================
%  4. 지표 샘플 출력
%  =====================================================================

fprintf('========================================\n');
fprintf('  지표 샘플 출력 (요약)\n');
fprintf('========================================\n\n');

fprintf('설정:\n');
fprintf('  L_cell: %.1f, rho: %.1f, STAs: %d, RA-RU: %d\n\n', ...
    cfg.L_cell, cfg.rho, cfg.num_STAs, cfg.numRU_RA);

fprintf('결과:\n');
fprintf('  Mean Delay        : %.2f ms\n', results.summary.mean_delay_ms);
fprintf('  P90 Delay         : %.2f ms\n', results.summary.p90_delay_ms);
fprintf('  Collision Rate    : %.1f%%\n', results.summary.collision_rate * 100);
fprintf('  Explicit BSR Ratio: %.1f%%\n', results.bsr.explicit_ratio * 100);
fprintf('  Buffer Empty Ratio: %.1f%% ⭐\n', results.bsr.buffer_empty_ratio * 100);
fprintf('  T_uora (mean)     : %.2f ms\n', results.bsr.mean_uora_delay * 1000);

fprintf('\n');

%% =====================================================================
%  5. 최종 판정
%  =====================================================================

fprintf('========================================\n');
fprintf('  최종 판정\n');
fprintf('========================================\n');

if all_present
    fprintf('\n✅ Phase 0 실험 준비 완료!\n');
    fprintf('   모든 필수 지표가 정상적으로 수집됩니다.\n\n');
    fprintf('다음 단계:\n');
    fprintf('  1. experiments/common/ 폴더의 공통 함수 작성\n');
    fprintf('  2. experiments/phase0/exp0_baseline_sweep.m 작성\n');
    fprintf('  3. Phase 0 실험 실행\n\n');
else
    fprintf('\n⚠️  일부 지표 누락\n');
    fprintf('   위의 ❌ 표시된 지표를 확인하세요.\n\n');
end

fprintf('========================================\n\n');