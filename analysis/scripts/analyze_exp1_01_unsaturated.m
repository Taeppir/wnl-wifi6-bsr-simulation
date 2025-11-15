%% analyze_exp1_1_unsaturated.m
% Experiment 1-1 분석: Unsaturated 환경 찾기
%
% [수정]
%   - Subplot 5: (T_uora / T_total) 비율을 Run별로 계산 (정확도 향상)
%   - Subplot 5: Bar + Errorbar로 시각화

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 1-1: Unsaturated 환경 분석\n');
fprintf('========================================\n\n');

exp = load_experiment('exp1_1_load_sweep');

% 데이터 추출
L_cell = exp.config.sweep_range;
n_points = length(L_cell);

% --- [수정] Raw Data에서 비율을 계산하기 위해 Raw Data 로드 ---
% exp.raw_data.(metric)은 [n_points, num_runs] 크기를 가짐
raw_total_delay = exp.raw_data.mean_delay_ms;
raw_uora_delay = exp.raw_data.mean_uora_delay_ms;

% --- 기존 Summary (다른 그래프용) ---
mean_delay = exp.summary.mean.mean_delay_ms;
std_delay = exp.summary.std.mean_delay_ms;
mean_uora_delay = exp.summary.mean.mean_uora_delay_ms;
std_uora_delay = exp.summary.std.mean_uora_delay_ms;
mean_collision = exp.summary.mean.collision_rate;
mean_completion = exp.summary.mean.completion_rate;

% BSR 관련
if isfield(exp.summary.mean, 'buffer_empty_ratio')
    buffer_empty = exp.summary.mean.buffer_empty_ratio;
    has_buffer_empty = true;
else
    warning('buffer_empty_ratio가 없습니다. implicit_bsr_ratio를 대안으로 사용합니다.');
    buffer_empty = nan(size(L_cell));
    has_buffer_empty = false;
end

if isfield(exp.summary.mean, 'implicit_bsr_ratio')
    implicit_bsr = exp.summary.mean.implicit_bsr_ratio;
else
    implicit_bsr = nan(size(L_cell));
    warning('implicit_bsr_ratio가 결과에 없습니다.');
end

% NaN 값 처리 (오류 방지)
mean_delay(isnan(mean_delay)) = 0;
mean_uora_delay(isnan(mean_uora_delay)) = 0;
raw_total_delay(isnan(raw_total_delay)) = 0;
raw_uora_delay(isnan(raw_uora_delay)) = 0;


%% =====================================================================
%  2. [신규] UORA 비율 계산 (Run별)
%  =====================================================================

% (T_uora / T_total) 비율을 Run별로 계산
% (0/0 방지: T_total이 0일 경우 NaN이 되도록)
raw_total_delay_safe = raw_total_delay;
raw_total_delay_safe(raw_total_delay == 0) = NaN;
raw_uora_ratios_pct = (raw_uora_delay ./ raw_total_delay_safe) * 100; % [n_points, num_runs]

% Run별 비율의 평균 및 표준편차 계산
% 2번째 차원(num_runs)을 기준으로 계산
mean_uora_ratio = mean(raw_uora_ratios_pct, 2, 'omitnan'); % [n_points, 1]
std_uora_ratio = std(raw_uora_ratios_pct, 0, 2, 'omitnan');  % [n_points, 1]


%% =====================================================================
%  3. Unsaturated 조건 판단
%  =====================================================================

fprintf('[Unsaturated 환경 기준]\n');
if has_buffer_empty
    fprintf('  1. 버퍼 비어있음 비율 >= 30%%\n');
    fprintf('  2. UORA 지연 > 0\n');
    fprintf('  3. 완료율 >= 85%%\n');
    fprintf('  4. Implicit BSR 비율 >= 50%%\n\n');
    
    condition1 = buffer_empty >= 0.30;
else
    fprintf('  ⚠️  buffer_empty_ratio 없음 → 대안 기준 사용\n');
    fprintf('  1. Implicit BSR 비율 >= 60%%\n');
    fprintf('  2. UORA 지연 > 0\n');
    fprintf('  3. 완료율 >= 85%%\n');
    fprintf('  4. 충돌률 < 40%%\n\n');
    
    condition1 = implicit_bsr >= 0.60;
end

condition2 = mean_uora_delay > 0;
condition3 = mean_completion >= 0.85;

if has_buffer_empty
    condition4 = implicit_bsr >= 0.50;
else
    condition4 = mean_collision < 0.40;
end

unsaturated_mask = condition1 & condition2 & condition3 & condition4;

fprintf('[조건별 분석]\n');
if has_buffer_empty
    fprintf('%-10s | %10s | %10s | %10s | %10s | %s\n', ...
        'L_cell', 'Buf.Empty', 'UORA>0', 'Compl>=85', 'Impl>=50', 'Result');
    fprintf('%s\n', repmat('-', 1, 75));
    
    for i = 1:n_points
        fprintf('%-10.1f | %10s | %10s | %10s | %10s | %s\n', ...
            L_cell(i), ...
            sprintf('%.1f%%', buffer_empty(i)*100), ...
            sprintf('%s', ternary(mean_uora_delay(i) > 0, 'YES', 'NO')), ...
            sprintf('%.1f%%', mean_completion(i)*100), ...
            sprintf('%.1f%%', implicit_bsr(i)*100), ...
            ternary(unsaturated_mask(i), '✓ Unsaturated', '✗ Saturated'));
    end
else
    fprintf('%-10s | %10s | %10s | %10s | %10s | %s\n', ...
        'L_cell', 'Impl>=60', 'UORA>0', 'Compl>=85', 'Coll<40', 'Result');
    fprintf('%s\n', repmat('-', 1, 75));
    
    for i = 1:n_points
        fprintf('%-10.1f | %10s | %10s | %10s | %10s | %s\n', ...
            L_cell(i), ...
            sprintf('%.1f%%', implicit_bsr(i)*100), ...
            sprintf('%s', ternary(mean_uora_delay(i) > 0, 'YES', 'NO')), ...
            sprintf('%.1f%%', mean_completion(i)*100), ...
            sprintf('%.1f%%', mean_collision(i)*100), ...
            ternary(unsaturated_mask(i), '✓ Unsaturated', '✗ Saturated'));
    end
end

fprintf('\n');

%% =====================================================================
%  4. 최적 범위 도출
%  =====================================================================

if any(unsaturated_mask)
    optimal_L_cell = L_cell(unsaturated_mask);
    fprintf('[결과] Unsaturated 조건을 만족하는 L_cell:\n');
    fprintf('  → %.1f ~ %.1f (총 %d개 조건)\n', ...
        min(optimal_L_cell), max(optimal_L_cell), sum(unsaturated_mask));
    
    idx_unsaturated = find(unsaturated_mask);
    
    if has_buffer_empty
        score = buffer_empty(idx_unsaturated) .* mean_uora_delay(idx_unsaturated);
    else
        score = implicit_bsr(idx_unsaturated) .* mean_uora_delay(idx_unsaturated);
    end
    
    [~, best_idx] = max(score);
    best_L_cell = L_cell(idx_unsaturated(best_idx));
    
    fprintf('\n[추천] 가장 균형잡힌 조건:\n');
    fprintf('  L_cell = %.1f\n', best_L_cell);
    if has_buffer_empty
        fprintf('  - 버퍼 비어있음: %.1f%%\n', buffer_empty(idx_unsaturated(best_idx))*100);
    end
    fprintf('  - Implicit BSR: %.1f%%\n', implicit_bsr(idx_unsaturated(best_idx))*100);
    fprintf('  - UORA 지연: %.2f ms\n', mean_uora_delay(idx_unsaturated(best_idx)));
    fprintf('  - 평균 지연: %.2f ms\n', mean_delay(idx_unsaturated(best_idx)));
    fprintf('  - 충돌률: %.1f%%\n\n', mean_collision(idx_unsaturated(best_idx))*100);
else
    fprintf('[결과] ⚠️  Unsaturated 조건을 만족하는 L_cell이 없습니다!\n');
    fprintf('  → 기준을 완화하거나 실험 범위를 조정하세요.\n\n');
end

%% =====================================================================
%  5. 시각화
%  =====================================================================

fprintf('[시각화 생성 중...]\n');

fig = figure('Position', [100, 100, 1400, 1000]);

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: 평균 큐잉 지연 (Mean ± Std)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 1);
errorbar(L_cell, mean_delay, std_delay, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
grid on;
xlabel('L_{cell}');
ylabel('Mean Delay [ms]');
title('평균 큐잉 지연 (Mean ± Std)');

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: UORA 지연 (Mean ± Std)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 2);
errorbar(L_cell, mean_uora_delay, std_uora_delay, 'm-o', 'LineWidth', 2, 'MarkerFaceColor', 'm');
grid on;
xlabel('L_{cell}');
ylabel('UORA Delay [ms]');
title('UORA 지연 (경쟁 강도, Mean ± Std)');

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: Explicit vs Implicit BSR
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 3);
plot(L_cell, implicit_bsr * 100, 'c-o', 'LineWidth', 2, 'MarkerFaceColor', 'c');
hold on;
plot(L_cell, (1 - implicit_bsr) * 100, 'r-s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
grid on;
xlabel('L_{cell}');
ylabel('BSR Ratio [%]');
title('Explicit vs Implicit BSR');
legend({'Implicit BSR', 'Explicit BSR'}, 'Location', 'best');
ylim([0, 100]);

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: 완료율 & 충돌률
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 4);
yyaxis left;
plot(L_cell, mean_completion * 100, 'g-o', 'LineWidth', 2, 'MarkerFaceColor', 'g');
ylabel('Completion Rate [%]');
ylim([0, 105]);
hold on;

yyaxis right;
plot(L_cell, mean_collision * 100, 'r-s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
ylabel('Collision Rate [%]');
grid on;
xlabel('L_{cell}');
title('완료율 & 충돌률');
legend({'Completion Rate', 'Collision Rate'}, 'Location', 'best');

% ─────────────────────────────────────────────────────────────────────
% Subplot 5: UORA 지연 비율 (Bar + Errorbar) ⭐ (수정된 그래프)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 5);

% 1. Bar 그래프 (평균 비율)
bar(L_cell, mean_uora_ratio, 'FaceColor', [0.5 0.5 0.5]);
hold on;

% 2. Error Bar (비율의 표준편차)
errorbar(L_cell, mean_uora_ratio, std_uora_ratio, ...
    'k.', 'LineWidth', 1.5, 'CapSize', 10, 'HandleVisibility', 'off');

grid on;
xlabel('L_{cell}');
ylabel('Ratio [%]');
title('UORA 지연 비율 (T_{uora} / T_{total}, Run별 계산)');
legend({'평균 비율 (Run별 계산)', '비율의 표준편차'}, 'Location', 'best');
ylim([0, 105]);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 6: 버퍼 비어있음 비율
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 6);
if has_buffer_empty
    plot(L_cell, buffer_empty * 100, 'k-o', 'LineWidth', 2, 'MarkerFaceColor', 'k');
    grid on;
    xlabel('L_{cell}');
    ylabel('Buffer Empty [%]');
    title('버퍼 비어있음 비율 (Buffer Empty Ratio)');
    ylim([0, 100]);
else
    % 데이터가 없을 경우
    text(0.5, 0.5, 'buffer_empty_ratio data not found', ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'r');
    title('버퍼 비어있음 비율 (Data N/A)');
    set(gca, 'XTick', [], 'YTick', []);
end

% ─────────────────────────────────────────────────────────────────────
% 전체 제목
% ─────────────────────────────────────────────────────────────────────
sgtitle('Exp 1-1: Unsaturated 환경 분석', ...
    'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  5. 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fig_filename = sprintf('%s/exp1_1_unsaturated_analysis.png', fig_dir);
saveas(fig, fig_filename);
fprintf('  ✓ Figure 저장: %s\n', fig_filename);

% PDF도 저장 (고품질)
fig_filename_pdf = sprintf('%s/exp1_1_unsaturated_analysis.pdf', fig_dir);
exportgraphics(fig, fig_filename_pdf, 'ContentType', 'vector');
fprintf('  ✓ PDF 저장: %s\n', fig_filename_pdf);

fprintf('\n🎉 분석 완료!\n\n');

%% =====================================================================
%  Helper Functions
%  =====================================================================

function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end