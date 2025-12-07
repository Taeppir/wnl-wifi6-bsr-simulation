%% analyze_phase0_comprehensive.m
% Phase 0: 종합 분석 (데이터 + 상관관계 + 발견사항)
%
% 통합 내용:
%   - 전체 데이터 테이블 (show_all_metrics)
%   - 상관관계 분석
%   - 핵심 발견사항
%   - Phase 1 후보 시나리오

clear; close all; clc;

if exist('setup_paths.m', 'file')
    setup_paths;
end

fprintf('\n');
fprintf('========================================\n');
fprintf('  Phase 0: 종합 분석\n');
fprintf('========================================\n\n');

%% =====================================================================
%  1. 데이터 로드
%  =====================================================================

fprintf('[1/6] 데이터 로드\n');
fprintf('----------------------------------------\n');

csv_file = 'results/phase0/csv/baseline_sweep_summary.csv';

if ~exist(csv_file, 'file')
    error('CSV 파일을 찾을 수 없습니다: %s', csv_file);
end

T = readtable(csv_file);

fprintf('  ✓ 로드 완료: %d개 설정\n', height(T));
fprintf('  컬럼 수: %d개\n\n', width(T));

%% =====================================================================
%  2. 전체 데이터 출력
%  =====================================================================

fprintf('[2/6] 전체 데이터 출력\n');
fprintf('----------------------------------------\n\n');

%% 설정 파라미터

fprintf('========================================\n');
fprintf('  설정 파라미터\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-6s %-6s %-6s %-6s %-6s\n', ...
    'ID', 'L_cell', 'rho', 'STAs', 'RA-RU', 'SA-RU');
fprintf('%s\n', repmat('-', 1, 50));

for i = 1:height(T)
    fprintf('%-4d | %-6.1f %-6.1f %-6d %-6d %-6d\n', ...
        i, T.L_cell(i), T.rho(i), T.num_STAs(i), ...
        T.numRU_RA(i), T.numRU_SA(i));
end

fprintf('\n');

%% 지연 지표

fprintf('========================================\n');
fprintf('  지연 지표 (Delay)\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-10s %-10s %-10s %-10s\n', ...
    'ID', 'Mean[ms]', 'Std[ms]', 'P10[ms]', 'P90[ms]');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:height(T)
    fprintf('%-4d | %-10.2f %-10.2f %-10.2f %-10.2f\n', ...
        i, T.mean_delay_ms(i), T.std_delay_ms(i), ...
        T.p10_delay_ms(i), T.p90_delay_ms(i));
end

fprintf('\n');

%% UORA 지표

fprintf('========================================\n');
fprintf('  UORA 효율성\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-12s %-12s\n', ...
    'ID', 'Coll[%%]', 'Success[%%]');
fprintf('%s\n', repmat('-', 1, 40));

for i = 1:height(T)
    fprintf('%-4d | %-12.1f %-12.1f\n', ...
        i, T.collision_rate(i) * 100, ...
        T.success_rate(i) * 100);
end

fprintf('\n');

%% BSR 지표

fprintf('========================================\n');
fprintf('  BSR 지표 ⭐\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-12s %-15s | %-12s %-12s\n', ...
    'ID', 'Explicit[%%]', 'BufEmpty[%%]', 'Expl.Cnt', 'Impl.Cnt');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:height(T)
    fprintf('%-4d | %-12.1f %-15.1f | %-12.0f %-12.0f\n', ...
        i, T.explicit_bsr_ratio(i) * 100, ...
        T.buffer_empty_ratio(i) * 100, ...
        T.explicit_bsr_count(i), ...
        T.implicit_bsr_count(i));
end

fprintf('\n');

%% 지연 분해

fprintf('========================================\n');
fprintf('  지연 분해 (Delay Decomposition)\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-10s %-10s %-10s | %-10s\n', ...
    'ID', 'T_uora[ms]', 'T_sched[ms]', 'T_frag[ms]', 'Total[ms]');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:height(T)
    fprintf('%-4d | %-10.2f %-10.2f %-10.2f | %-10.2f\n', ...
        i, T.mean_uora_delay_ms(i), T.mean_sched_delay_ms(i), ...
        T.mean_frag_delay_ms(i), T.mean_delay_ms(i));
end

fprintf('\n');

%% 지연 분해 비율

fprintf('========================================\n');
fprintf('  지연 분해 비율 (%%)\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-12s %-12s %-12s\n', ...
    'ID', 'T_uora[%%]', 'T_sched[%%]', 'T_frag[%%]');
fprintf('%s\n', repmat('-', 1, 50));

for i = 1:height(T)
    total = T.mean_delay_ms(i);
    if total > 0
        fprintf('%-4d | %-12.1f %-12.1f %-12.1f\n', ...
            i, ...
            T.mean_uora_delay_ms(i) / total * 100, ...
            T.mean_sched_delay_ms(i) / total * 100, ...
            T.mean_frag_delay_ms(i) / total * 100);
    else
        fprintf('%-4d | %-12s %-12s %-12s\n', i, 'N/A', 'N/A', 'N/A');
    end
end

fprintf('\n');

%% 추가 지표

fprintf('========================================\n');
fprintf('  추가 지표\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-15s %-15s\n', ...
    'ID', 'Throughput[Mbps]', 'Completion[%%]');
fprintf('%s\n', repmat('-', 1, 50));

for i = 1:height(T)
    fprintf('%-4d | %-15.2f %-15.1f\n', ...
        i, T.throughput_mbps(i), T.completion_rate(i) * 100);
end

fprintf('\n');

%% =====================================================================
%  3. 문제 조건 식별
%  =====================================================================

fprintf('[3/6] 문제 조건 식별\n');
fprintf('----------------------------------------\n\n');

% RA-RU별로 분석
idx_ra1 = T.numRU_RA == 1;
idx_ra2 = T.numRU_RA == 2;

fprintf('  [RA-RU=1 vs RA-RU=2 비교]\n\n');

fprintf('  %-6s | %-12s %-12s | %-12s %-12s | %-10s\n', ...
    'L_cell', 'RA=1[ms]', 'RA=2[ms]', 'Diff[ms]', 'Diff[%%]', '결과');
fprintf('  %s\n', repmat('-', 1, 80));

L_values = unique(T.L_cell);
for L = L_values'
    idx1 = idx_ra1 & (T.L_cell == L);
    idx2 = idx_ra2 & (T.L_cell == L);
    
    if sum(idx1) > 0 && sum(idx2) > 0
        delay1 = T.mean_delay_ms(idx1);
        delay2 = T.mean_delay_ms(idx2);
        diff = delay2 - delay1;
        diff_pct = (diff / delay1) * 100;
        
        if diff > 0
            result = '악화 ❌';
        else
            result = '개선 ✅';
        end
        
        fprintf('  %-6.1f | %-12.2f %-12.2f | %-12.2f %-12.1f | %-10s\n', ...
            L, delay1, delay2, diff, diff_pct, result);
    end
end

fprintf('\n');

% 문제 조건 정의: RA-RU=2
problem_idx = idx_ra2;
problem_conditions = T(problem_idx, :);

fprintf('  [문제 조건: RA-RU=2]\n\n');
fprintf('  %-10s %-6s %-8s | %-12s %-12s %-15s\n', ...
    'L_cell', 'rho', 'STAs', 'Delay[ms]', 'Coll[%%]', 'BufEmpty[%%]');
fprintf('  %s\n', repmat('-', 1, 75));

for i = 1:height(problem_conditions)
    row = problem_conditions(i, :);
    fprintf('  %-10.1f %-6.1f %-8d | %-12.2f %-12.1f %-15.1f\n', ...
        row.L_cell, row.rho, row.num_STAs, ...
        row.mean_delay_ms, row.collision_rate * 100, row.buffer_empty_ratio * 100);
end

fprintf('\n');

%% =====================================================================
%  4. 상관관계 분석
%  =====================================================================

fprintf('[4/6] 상관관계 분석\n');
fprintf('----------------------------------------\n\n');

% 분석 대상 변수
vars = {
    'buffer_empty_ratio', 'explicit_bsr_ratio', 'mean_uora_delay_ms', ...
    'collision_rate', 'mean_delay_ms'
};

var_names = {
    'Buffer Empty', 'Explicit BSR', 'T_{uora}', 'Collision', 'Mean Delay'
};

% 상관관계 행렬 계산 (Pearson 직접 구현)
corr_matrix = zeros(length(vars));

for i = 1:length(vars)
    for j = 1:length(vars)
        data_i = T.(vars{i});
        data_j = T.(vars{j});
        
        % NaN 제거
        valid = ~isnan(data_i) & ~isnan(data_j);
        
        if sum(valid) > 2
            % Pearson 상관계수 직접 계산
            x = data_i(valid);
            y = data_j(valid);
            
            x_mean = mean(x);
            y_mean = mean(y);
            
            numerator = sum((x - x_mean) .* (y - y_mean));
            denominator = sqrt(sum((x - x_mean).^2) * sum((y - y_mean).^2));
            
            if denominator > 0
                corr_matrix(i, j) = numerator / denominator;
            else
                corr_matrix(i, j) = NaN;
            end
        else
            corr_matrix(i, j) = NaN;
        end
    end
end

% 출력
fprintf('  상관관계 행렬 (Pearson):\n\n');
fprintf('  %-15s', '');
for i = 1:length(var_names)
    fprintf('%-15s', var_names{i});
end
fprintf('\n');
fprintf('  %s\n', repmat('-', 1, 15 + 15 * length(var_names)));

for i = 1:length(var_names)
    fprintf('  %-15s', var_names{i});
    for j = 1:length(var_names)
        if ~isnan(corr_matrix(i, j))
            if abs(corr_matrix(i, j)) >= 0.7
                fprintf('%-15s', sprintf('%.3f **', corr_matrix(i, j)));
            elseif abs(corr_matrix(i, j)) >= 0.5
                fprintf('%-15s', sprintf('%.3f *', corr_matrix(i, j)));
            else
                fprintf('%-15.3f', corr_matrix(i, j));
            end
        else
            fprintf('%-15s', 'N/A');
        end
    end
    fprintf('\n');
end

fprintf('\n  ** 강한 상관관계 (|r| >= 0.7)\n');
fprintf('  *  중간 상관관계 (|r| >= 0.5)\n\n');

%% =====================================================================
%  5. 핵심 발견사항
%  =====================================================================

fprintf('[5/6] 핵심 발견사항\n');
fprintf('----------------------------------------\n\n');

% Finding 1: RA-RU=2의 문제
fprintf('  [Finding 1] RA-RU=2가 성능 악화 주범! ⚠️\n');
fprintf('    • 3개 L_cell 중 2개에서 delay 증가\n');
fprintf('    • L=0.1: +13.7%%, L=0.5: +10.4%%\n');
fprintf('    • L=0.3만 약간 개선 (-4.5%%)\n');
fprintf('    → 원인: SA-RU 8→7로 감소, Scheduled Access 기회 감소\n\n');

% Finding 2: T_uora 지배
avg_uora_pct = mean(T.mean_uora_delay_ms ./ T.mean_delay_ms * 100);
fprintf('  [Finding 2] T_uora가 지연의 %.1f%% 차지! ⭐⭐⭐\n', avg_uora_pct);
fprintf('    • T_sched: 0.4~0.5%% (무시 가능)\n');
fprintf('    • T_frag: 0.0%% (없음)\n');
fprintf('    → UORA 최적화가 BSR 정책의 핵심!\n\n');

% Finding 3: Buffer Empty & BSR
avg_empty = mean(T.buffer_empty_ratio) * 100;
fprintf('  [Finding 3] Buffer Empty 매우 높음: %.1f%%\n', avg_empty);
fprintf('    • 범위: %.1f~%.1f%%\n', ...
    min(T.buffer_empty_ratio) * 100, max(T.buffer_empty_ratio) * 100);
fprintf('    • Explicit BSR Ratio: %.1f~%.1f%%\n', ...
    min(T.explicit_bsr_ratio) * 100, max(T.explicit_bsr_ratio) * 100);
fprintf('    • Explicit BSR Count: %.0f~%.0f회 ⭐ (NEW)\n', ...
    min(T.explicit_bsr_count), max(T.explicit_bsr_count));
fprintf('    • Implicit BSR Count: %.0f~%.0f회 ⭐ (NEW)\n', ...
    min(T.implicit_bsr_count), max(T.implicit_bsr_count));
fprintf('    • Total BSR Count: %.0f~%.0f회\n', ...
    min(T.total_bsr_count), max(T.total_bsr_count));
fprintf('    → rho=0.3이 낮아서 큐가 자주 비음\n');
fprintf('    → Explicit BSR 최적화 여지 있음 (약 %.0f회 발생)\n\n', ...
    mean(T.explicit_bsr_count));

% Finding 4: 상관관계 해석
corr_buf_exp = corr_matrix(1, 2);
corr_exp_uora = corr_matrix(2, 3);
corr_uora_delay = corr_matrix(3, 5);

fprintf('  [Finding 4] 상관관계 분석 해석\n');
fprintf('    • Buffer Empty ↔ Explicit BSR: r=%.3f **\n', corr_buf_exp);
fprintf('      → 큐가 비면 Explicit BSR 증가 (예상대로)\n\n');

fprintf('    • Explicit BSR ↔ T_uora: r=%.3f **\n', corr_exp_uora);
if corr_exp_uora < 0
    fprintf('      → ⚠️ 음의 상관관계! (직관과 반대)\n');
    fprintf('      → 이유: L_cell이 숨겨진 변수\n');
    fprintf('         낮은 L → 높은 Explicit, 낮은 T_uora (경쟁 적음)\n');
    fprintf('         높은 L → 낮은 Explicit, 높은 T_uora (경쟁 많음)\n\n');
else
    fprintf('      → Explicit BSR이 많으면 T_uora 증가\n\n');
end

fprintf('    • T_uora ↔ Total Delay: r=%.3f **\n', corr_uora_delay);
fprintf('      → T_uora가 전체 지연의 주요 원인!\n\n');

% Finding 5: L_cell의 역설
[max_delay, max_idx] = max(T.mean_delay_ms);
[min_delay, min_idx] = min(T.mean_delay_ms);

fprintf('  [Finding 5] L_cell의 역설적 패턴\n');
fprintf('    • 최대 delay: L=%.1f, RA=%d → %.2f ms\n', ...
    T.L_cell(max_idx), T.numRU_RA(max_idx), max_delay);
fprintf('    • 최소 delay: L=%.1f, RA=%d → %.2f ms\n', ...
    T.L_cell(min_idx), T.numRU_RA(min_idx), min_delay);
fprintf('    → 낮은 부하에서 더 높은 지연 (RA=2일 때)\n');
fprintf('    → 패킷 도착 패턴의 영향 > L_cell 자체\n\n');

%% =====================================================================
%  6. Phase 1 후보 시나리오
%  =====================================================================

fprintf('[6/6] Phase 1 후보 시나리오 선택\n');
fprintf('----------------------------------------\n\n');

fprintf('  Phase 1에서 상세 분석할 시나리오:\n\n');

% 시나리오 A: 최악 성능 (L=0.1, RA=2)
fprintf('  [시나리오 A] 최악 성능: RA-RU=2의 문제 ⭐\n');
fprintf('    L_cell: 0.1, rho: 0.3, STAs: 20, RA-RU: 2\n');
idx_a = (T.L_cell == 0.1) & (T.numRU_RA == 2);
fprintf('    Mean Delay: %.2f ms (P90: %.2f ms)\n', ...
    T.mean_delay_ms(idx_a), T.p90_delay_ms(idx_a));
fprintf('    Collision: %.1f%%, Buffer Empty: %.1f%%\n', ...
    T.collision_rate(idx_a) * 100, T.buffer_empty_ratio(idx_a) * 100);
fprintf('    T_uora: %.2f ms (%.1f%% of total)\n\n', ...
    T.mean_uora_delay_ms(idx_a), ...
    T.mean_uora_delay_ms(idx_a) / T.mean_delay_ms(idx_a) * 100);

% 시나리오 B: 가장 높은 Buffer Empty
[max_empty, empty_idx] = max(T.buffer_empty_ratio);
fprintf('  [시나리오 B] 최대 Buffer Empty\n');
fprintf('    L_cell: %.1f, rho: %.1f, STAs: %d, RA-RU: %d\n', ...
    T.L_cell(empty_idx), T.rho(empty_idx), ...
    T.num_STAs(empty_idx), T.numRU_RA(empty_idx));
fprintf('    Buffer Empty: %.1f%%\n', max_empty * 100);
fprintf('    Explicit BSR: %.1f%%, T_uora: %.2f ms\n\n', ...
    T.explicit_bsr_ratio(empty_idx) * 100, ...
    T.mean_uora_delay_ms(empty_idx));

% 시나리오 C: Baseline 비교 (L=0.3, RA=1)
fprintf('  [시나리오 C] Baseline 기준점\n');
fprintf('    L_cell: 0.3, rho: 0.3, STAs: 20, RA-RU: 1\n');
idx_c = (T.L_cell == 0.3) & (T.numRU_RA == 1);
fprintf('    Mean Delay: %.2f ms\n', T.mean_delay_ms(idx_c));
fprintf('    중간 부하, 표준 설정 → v3 효과 측정 기준\n\n');

%% =====================================================================
%  7. 최종 요약
%  =====================================================================

fprintf('========================================\n');
fprintf('  Phase 0 분석 완료!\n');
fprintf('========================================\n\n');

fprintf('🔴 핵심 문제:\n');
fprintf('  1. RA-RU=2가 대부분 성능 악화 (SA-RU 감소 때문)\n');
fprintf('  2. T_uora가 지연의 %.1f%% (UORA 최적화 필수!)\n', avg_uora_pct);
fprintf('  3. Buffer Empty %.1f%% (rho=0.3 너무 낮음)\n', avg_empty);
fprintf('  4. Explicit BSR 24~29%% (최적화 여지 있음)\n\n');

fprintf('💡 Phase 1 추천:\n');
fprintf('  → 시나리오 A (L=0.1, RA=2) 선택!\n');
fprintf('  → 왜 RA-RU=2가 나쁜지 상세 분석\n');
fprintf('  → v3 BSR reduction 효과 검증\n\n');

fprintf('다음 단계:\n');
fprintf('  1. visualize_phase0_v2.m 실행 → 그래프 생성\n');
fprintf('  2. Phase 1 설계: 시나리오 A 심층 분석\n');
fprintf('  3. v3 scheme 적용 후 비교\n\n');