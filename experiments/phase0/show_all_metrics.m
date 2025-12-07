%% show_all_metrics.m
% Phase 0 전체 결과를 보기 좋게 출력

clear; close all; clc;

fprintf('\n');
fprintf('========================================\n');
fprintf('  Phase 0: 전체 결과 상세 보기\n');
fprintf('========================================\n\n');

%% CSV 로드

csv_file = 'results/phase0/csv/baseline_sweep_summary.csv';

if ~exist(csv_file, 'file')
    error('CSV 파일을 찾을 수 없습니다: %s', csv_file);
end

T = readtable(csv_file);

fprintf('총 %d개 설정\n', height(T));
fprintf('컬럼 수: %d개\n\n', width(T));

fprintf('사용 가능한 컬럼:\n');
fprintf('%s\n', repmat('-', 1, 50));
for i = 1:width(T)
    fprintf('  %2d. %s\n', i, T.Properties.VariableNames{i});
end
fprintf('\n');

%% 파라미터 컬럼

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

%% BSR 지표 ⭐

fprintf('========================================\n');
fprintf('  BSR 지표 ⭐\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-12s %-15s\n', ...
    'ID', 'Explicit[%%]', 'BufEmpty[%%]');
fprintf('%s\n', repmat('-', 1, 40));

for i = 1:height(T)
    fprintf('%-4d | %-12.1f %-15.1f\n', ...
        i, T.explicit_bsr_ratio(i) * 100, ...
        T.buffer_empty_ratio(i) * 100);
end

fprintf('\n');

%% 지연 분해

fprintf('========================================\n');
fprintf('  지연 분해 (Delay Decomposition)\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-10s %-10s %-10s\n', ...
    'ID', 'T_uora[ms]', 'T_sched[ms]', 'T_frag[ms]');
fprintf('%s\n', repmat('-', 1, 50));

for i = 1:height(T)
    fprintf('%-4d | %-10.2f %-10.2f %-10.2f\n', ...
        i, T.mean_uora_delay_ms(i), T.mean_sched_delay_ms(i), ...
        T.mean_frag_delay_ms(i));
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

%% 순위 (Ranking)

fprintf('========================================\n');
fprintf('  순위 (높은 순)\n');
fprintf('========================================\n\n');

% Mean Delay
[~, idx] = sort(T.mean_delay_ms, 'descend');
fprintf('  [Mean Delay]\n');
for i = 1:min(3, height(T))
    row_idx = idx(i);
    fprintf('    %d위: ID=%d (L=%.1f, RA=%d) → %.2f ms\n', ...
        i, row_idx, T.L_cell(row_idx), T.numRU_RA(row_idx), ...
        T.mean_delay_ms(row_idx));
end
fprintf('\n');

% Buffer Empty
[~, idx] = sort(T.buffer_empty_ratio, 'descend');
fprintf('  [Buffer Empty Ratio]\n');
for i = 1:min(3, height(T))
    row_idx = idx(i);
    fprintf('    %d위: ID=%d (L=%.1f, RA=%d) → %.1f%%\n', ...
        i, row_idx, T.L_cell(row_idx), T.numRU_RA(row_idx), ...
        T.buffer_empty_ratio(row_idx) * 100);
end
fprintf('\n');

% Collision Rate
[~, idx] = sort(T.collision_rate, 'descend');
fprintf('  [Collision Rate]\n');
for i = 1:min(3, height(T))
    row_idx = idx(i);
    fprintf('    %d위: ID=%d (L=%.1f, RA=%d) → %.1f%%\n', ...
        i, row_idx, T.L_cell(row_idx), T.numRU_RA(row_idx), ...
        T.collision_rate(row_idx) * 100);
end
fprintf('\n');

% Explicit BSR
[~, idx] = sort(T.explicit_bsr_ratio, 'descend');
fprintf('  [Explicit BSR Ratio]\n');
for i = 1:min(3, height(T))
    row_idx = idx(i);
    fprintf('    %d위: ID=%d (L=%.1f, RA=%d) → %.1f%%\n', ...
        i, row_idx, T.L_cell(row_idx), T.numRU_RA(row_idx), ...
        T.explicit_bsr_ratio(row_idx) * 100);
end
fprintf('\n');

%% 완료

fprintf('========================================\n');
fprintf('  전체 결과 출력 완료!\n');
fprintf('========================================\n\n');