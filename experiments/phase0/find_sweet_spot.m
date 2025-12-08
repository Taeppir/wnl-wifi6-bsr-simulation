%% find_v3_sweet_spot.m
% v3에 최적인 "sweet spot" 찾기
%
% 조건:
%   1. buffer_empty: 30~60% (중간)
%   2. explicit_bsr_count: 많을수록 (최소 1500개)
%   3. mean_delay: 40~100ms (개선 여지 있음)
%   4. collision_rate: 30~50% (개선 여지 있음)

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  v3 Sweet Spot 찾기\n');
fprintf('========================================\n\n');

%% CSV 로드

csv_file = 'results/phase0/csv/baseline_sweep_summary.csv';
T = readtable(csv_file);

% Explicit BSR 비율
T.expl_ratio = T.explicit_bsr_count ./ T.total_bsr_count * 100;

fprintf('총 %d개 config\n\n', height(T));

%% Sweet Spot 필터링

fprintf('========================================\n');
fprintf('  Sweet Spot 조건\n');
fprintf('========================================\n\n');

fprintf('조건:\n');
fprintf('  1. buffer_empty: 30~70%%\n');
fprintf('  2. explicit_bsr_count: >= 1500개\n');
fprintf('  3. mean_delay: 40~100ms\n');
fprintf('  4. collision_rate: 25~50%%\n\n');

% 필터 적용
mask = (T.buffer_empty_ratio >= 0.30) & (T.buffer_empty_ratio <= 0.70) & ...
       (T.explicit_bsr_count >= 1500) & ...
       (T.mean_delay_ms >= 40) & (T.mean_delay_ms <= 100) & ...
       (T.collision_rate >= 0.25) & (T.collision_rate <= 0.50);

T_sweet = T(mask, :);

fprintf('필터링 결과: %d개 config\n\n', height(T_sweet));

if height(T_sweet) == 0
    fprintf('⚠️  조건 만족하는 config 없음! 조건 완화 필요\n\n');
    
    % 조건 완화
    fprintf('조건 완화 (버전 2):\n');
    fprintf('  1. buffer_empty: 25~75%%\n');
    fprintf('  2. explicit_bsr_count: >= 1400개\n');
    fprintf('  3. mean_delay: 30~120ms\n');
    fprintf('  4. collision_rate: 20~55%%\n\n');
    
    mask2 = (T.buffer_empty_ratio >= 0.25) & (T.buffer_empty_ratio <= 0.75) & ...
            (T.explicit_bsr_count >= 1400) & ...
            (T.mean_delay_ms >= 30) & (T.mean_delay_ms <= 120) & ...
            (T.collision_rate >= 0.20) & (T.collision_rate <= 0.55);
    
    T_sweet = T(mask2, :);
    fprintf('필터링 결과: %d개 config\n\n', height(T_sweet));
end

if height(T_sweet) == 0
    fprintf('⚠️  여전히 없음! 전체 분포 확인 필요\n\n');
    
    % 전체 범위 출력
    fprintf('전체 범위:\n');
    fprintf('  buffer_empty: %.1f%% ~ %.1f%%\n', ...
        min(T.buffer_empty_ratio)*100, max(T.buffer_empty_ratio)*100);
    fprintf('  explicit_bsr_count: %d ~ %d\n', ...
        min(T.explicit_bsr_count), max(T.explicit_bsr_count));
    fprintf('  mean_delay: %.1f ~ %.1f ms\n', ...
        min(T.mean_delay_ms), max(T.mean_delay_ms));
    fprintf('  collision_rate: %.1f%% ~ %.1f%%\n\n', ...
        min(T.collision_rate)*100, max(T.collision_rate)*100);
    
    % 각 조건별로 가장 가까운 것 찾기
    fprintf('각 조건에 가장 가까운 config:\n\n');
    
    % buffer_empty 40% 가장 가까운
    [~, idx1] = min(abs(T.buffer_empty_ratio - 0.40));
    fprintf('  buffer_empty ≈ 40%%:\n');
    fprintf('    Config: L=%.1f, rho=%.1f, mu_on=%.2f, RA=%d\n', ...
        T.L_cell(idx1), T.rho(idx1), T.mu_on(idx1), T.numRU_RA(idx1));
    fprintf('    buffer_empty=%.1f%%, expl=%d, delay=%.1fms\n\n', ...
        T.buffer_empty_ratio(idx1)*100, T.explicit_bsr_count(idx1), T.mean_delay_ms(idx1));
    
    return;
end

%% Sweet Spot 정렬

fprintf('========================================\n');
fprintf('  Sweet Spot 후보 (정렬)\n');
fprintf('========================================\n\n');

% 종합 점수: Explicit BSR 많고, 개선 여지 있는 것
T_sweet.score = T_sweet.explicit_bsr_count + ...
                (T_sweet.mean_delay_ms - 40) * 10 + ...
                T_sweet.collision_rate * 1000;

[~, idx] = sort(T_sweet.score, 'descend');
T_sweet = T_sweet(idx, :);

fprintf('%-4s | %-6s %-6s %-6s %-5s | %-10s %-10s %-10s %-10s\n', ...
    'Rank', 'L_cell', 'rho', 'mu_on', 'RA', 'BufEmpty', 'ExplBSR', 'Delay[ms]', 'Coll[%]');
fprintf('%s\n', repmat('-', 1, 100));

for i = 1:height(T_sweet)
    row = T_sweet(i, :);
    fprintf('%-4d | %-6.1f %-6.1f %-6.2f %-5d | %-10.1f %-10d %-10.1f %-10.1f\n', ...
        i, row.L_cell, row.rho, row.mu_on, row.numRU_RA, ...
        row.buffer_empty_ratio*100, round(row.explicit_bsr_count), ...
        row.mean_delay_ms, row.collision_rate*100);
end

fprintf('\n');

%% Top 3 추천

fprintf('========================================\n');
fprintf('  Top 3 추천 케이스 ⭐\n');
fprintf('========================================\n\n');

for i = 1:min(3, height(T_sweet))
    row = T_sweet(i, :);
    
    fprintf('[추천 %d]\n', i);
    fprintf('  Config: L=%.1f, rho=%.1f, mu_on=%.2f, RA-RU=%d\n', ...
        row.L_cell, row.rho, row.mu_on, row.numRU_RA);
    fprintf('  Baseline 성능:\n');
    fprintf('    Mean Delay: %.1f ms (개선 여지: %s)\n', ...
        row.mean_delay_ms, get_potential(row.mean_delay_ms));
    fprintf('    Collision: %.1f%% (개선 여지: %s)\n', ...
        row.collision_rate*100, get_potential(row.collision_rate*100));
    fprintf('    Buffer Empty: %.1f%% (중간 수준)\n', row.buffer_empty_ratio*100);
    fprintf('    Explicit BSR: %d개 (%.1f%%) ← 최적화 대상\n', ...
        round(row.explicit_bsr_count), row.expl_ratio);
    fprintf('    Implicit BSR: %d개\n', round(row.implicit_bsr_count));
    
    % v3 예상 효과
    fprintf('  v3 예상 효과:\n');
    if row.expl_ratio >= 20
        fprintf('    Explicit BSR: -20~30%% 감소 가능 ⭐\n');
        fprintf('    Delay: -5~10ms 개선 예상\n');
        fprintf('    Collision: -3~5%%p 감소 예상\n');
    else
        fprintf('    Explicit BSR: -10~15%% 감소 가능\n');
        fprintf('    Delay: -2~5ms 개선 예상\n');
        fprintf('    Collision: -1~3%%p 감소 예상\n');
    end
    
    fprintf('\n');
end

%% 함수

function str = get_potential(val)
    if val > 80
        str = '높음 ⭐⭐⭐';
    elseif val > 50
        str = '중간 ⭐⭐';
    else
        str = '낮음 ⭐';
    end
end

fprintf('========================================\n\n');