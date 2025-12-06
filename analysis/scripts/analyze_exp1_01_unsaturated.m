%% analyze_exp1_01_unsaturated.m
% Experiment 1-1 분석: Unsaturated 환경 찾기

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 1-1: Unsaturated 환경 분석 (v2)\n');
fprintf('========================================\n\n');

exp = load_experiment('exp1_1_load_sweep');

% 데이터 추출
L_cell = exp.config.sweep_range;
n_points = length(L_cell);

% Raw Data
raw_total_delay = exp.raw_data.mean_delay_ms;
raw_uora_delay = exp.raw_data.mean_uora_delay_ms;

% Summary (Mean ± Std)
mean_delay = exp.summary.mean.mean_delay_ms;
std_delay = exp.summary.std.mean_delay_ms;
mean_uora_delay = exp.summary.mean.mean_uora_delay_ms;
std_uora_delay = exp.summary.std.mean_uora_delay_ms;
mean_collision = exp.summary.mean.collision_rate;
mean_completion = exp.summary.mean.completion_rate;

% ⭐⭐⭐ [수정] 실제 데이터 길이 확인 및 조정
actual_n_points = length(mean_delay);
if actual_n_points ~= n_points
    warning('데이터 포인트 개수(%d)와 sweep_range 길이(%d)가 다릅니다. 데이터 길이로 조정합니다.', ...
        actual_n_points, n_points);
    L_cell = L_cell(1:actual_n_points);
    n_points = actual_n_points;
end

% ⭐⭐⭐ [추가] L_cell을 column vector로 변환 (bar 함수 호환)
L_cell = L_cell(:);

% ⭐ [v2] BSR 절대 횟수 추출
if isfield(exp.summary.mean, 'explicit_bsr_count')
    explicit_bsr_count = exp.summary.mean.explicit_bsr_count;
    implicit_bsr_count = exp.summary.mean.implicit_bsr_count;
    
    % ⭐⭐⭐ [추가] 데이터 길이 맞추기
    if length(explicit_bsr_count) ~= n_points
        explicit_bsr_count = explicit_bsr_count(1:n_points);
        implicit_bsr_count = implicit_bsr_count(1:n_points);
    end
    
    has_bsr_counts = true;
else
    % 데이터가 없으면 계산 시도
    warning('BSR count 데이터가 없습니다. 비율로 추정합니다.');
    has_bsr_counts = false;
end

% Buffer Empty
if isfield(exp.summary.mean, 'buffer_empty_ratio')
    buffer_empty = exp.summary.mean.buffer_empty_ratio;
    
    % ⭐⭐⭐ [추가] 데이터 길이 맞추기
    if length(buffer_empty) ~= n_points
        buffer_empty = buffer_empty(1:n_points);
    end
    
    has_buffer_empty = true;
else
    warning('buffer_empty_ratio가 없습니다.');
    buffer_empty = nan(size(L_cell));
    has_buffer_empty = false;
end

if isfield(exp.summary.mean, 'implicit_bsr_ratio')
    implicit_bsr = exp.summary.mean.implicit_bsr_ratio;
    
    % ⭐⭐⭐ [추가] 데이터 길이 맞추기
    if length(implicit_bsr) ~= n_points
        implicit_bsr = implicit_bsr(1:n_points);
    end
else
    implicit_bsr = nan(size(L_cell));
end

% NaN 처리
mean_delay(isnan(mean_delay)) = 0;
mean_uora_delay(isnan(mean_uora_delay)) = 0;

%% =====================================================================
%  2. Unsaturated 조건 판단
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

% 결과 출력
fprintf('[조건별 분석]\n');
if has_buffer_empty
    fprintf('%-10s | %10s | %10s | %10s | %s\n', ...
        'L_cell', 'Buf.Empty', 'UORA[ms]', 'Compl', 'Result');
    fprintf('%s\n', repmat('-', 1, 65));
    
    for i = 1:n_points
        fprintf('%-10.1f | %9.1f%% | %9.2f | %8.1f%% | %s\n', ...
            L_cell(i), ...
            buffer_empty(i)*100, ...
            mean_uora_delay(i), ...
            mean_completion(i)*100, ...
            ternary(unsaturated_mask(i), '✓ Unsat', '✗ Sat'));
    end
end

fprintf('\n');

%% =====================================================================
%  3. 최적 범위 도출
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
    fprintf('  - UORA 지연: %.2f ms\n', mean_uora_delay(idx_unsaturated(best_idx)));
    fprintf('  - 평균 지연: %.2f ms\n', mean_delay(idx_unsaturated(best_idx)));
    
    if has_bsr_counts
        fprintf('  - Explicit BSR: %.0f회\n', explicit_bsr_count(idx_unsaturated(best_idx)));
        fprintf('  - Implicit BSR: %.0f회\n', implicit_bsr_count(idx_unsaturated(best_idx)));
    end
    fprintf('\n');
else
    fprintf('[결과] ⚠️  Unsaturated 조건을 만족하는 L_cell이 없습니다!\n\n');
end

%% =====================================================================
%  4. 시각화 (절대값 중심)
%  =====================================================================

fprintf('[시각화 생성 중...]\n');

fig = figure('Position', [100, 100, 1600, 1000]);

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: 평균 큐잉 지연 (절대값, Mean ± Std)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 3, 1);
errorbar(L_cell, mean_delay, std_delay, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
grid on;
xlabel('L_{cell}', 'FontSize', 11);
ylabel('Mean Delay [ms]', 'FontSize', 11);
title('평균 큐잉 지연 (절대값)', 'FontSize', 12, 'FontWeight', 'bold');

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: UORA 지연 (절대값, Mean ± Std) ⭐
% ─────────────────────────────────────────────────────────────────────
subplot(3, 3, 2);
errorbar(L_cell, mean_uora_delay, std_uora_delay, 'm-o', 'LineWidth', 2, 'MarkerFaceColor', 'm');
grid on;
xlabel('L_{cell}', 'FontSize', 11);
ylabel('UORA Delay [ms]', 'FontSize', 11);
title('UORA 지연 (절대값)', 'FontSize', 12, 'FontWeight', 'bold');

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: BSR 절대 횟수 (Stacked Bar) ⭐⭐⭐
% ─────────────────────────────────────────────────────────────────────
subplot(3, 3, 3);
if has_bsr_counts
    % Stacked Bar: Explicit (빨강) + Implicit (파랑)
    bar_data = [explicit_bsr_count(:), implicit_bsr_count(:)];
    
    b = bar(L_cell, bar_data, 'grouped');
    b(1).FaceColor = [0.9, 0.3, 0.3];  % Explicit: 빨강
    b(2).FaceColor = [0.3, 0.6, 0.9];  % Implicit: 파랑
    
    grid on;
    xlabel('L_{cell}', 'FontSize', 11);
    ylabel('BSR Count', 'FontSize', 11);
    title('BSR 절대 횟수 (Stacked)', 'FontSize', 12, 'FontWeight', 'bold');
    legend({'Explicit BSR', 'Implicit BSR'}, 'Location', 'northwest');
else
    text(0.5, 0.5, 'BSR count data not available', ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'r');
    title('BSR 절대 횟수 (N/A)', 'FontSize', 12);
    set(gca, 'XTick', [], 'YTick', []);
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: Explicit BSR 단독 (Line + Marker) ⭐
% ─────────────────────────────────────────────────────────────────────
subplot(3, 3, 4);
if has_bsr_counts
    plot(L_cell, explicit_bsr_count, 'r-s', 'LineWidth', 2, ...
        'MarkerSize', 8, 'MarkerFaceColor', 'r');
    grid on;
    xlabel('L_{cell}', 'FontSize', 11);
    ylabel('Explicit BSR Count', 'FontSize', 11);
    title('Explicit BSR 발생 횟수', 'FontSize', 12, 'FontWeight', 'bold');
else
    text(0.5, 0.5, 'Data N/A', 'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'r');
    title('Explicit BSR (N/A)', 'FontSize', 12);
    set(gca, 'XTick', [], 'YTick', []);
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 5: 완료율 & 충돌률
% ─────────────────────────────────────────────────────────────────────
subplot(3, 3, 5);
yyaxis left;
plot(L_cell, mean_completion * 100, 'g-o', 'LineWidth', 2, 'MarkerFaceColor', 'g');
ylabel('Completion Rate [%]', 'FontSize', 11);
ylim([0, 105]);

yyaxis right;
plot(L_cell, mean_collision * 100, 'r-s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
ylabel('Collision Rate [%]', 'FontSize', 11);

grid on;
xlabel('L_{cell}', 'FontSize', 11);
title('완료율 & 충돌률', 'FontSize', 12, 'FontWeight', 'bold');
legend({'Completion', 'Collision'}, 'Location', 'best');

% ─────────────────────────────────────────────────────────────────────
% Subplot 6: 버퍼 비어있음 비율
% ─────────────────────────────────────────────────────────────────────
subplot(3, 3, 6);
if has_buffer_empty
    plot(L_cell, buffer_empty * 100, 'k-o', 'LineWidth', 2, 'MarkerFaceColor', 'k');
    grid on;
    xlabel('L_{cell}', 'FontSize', 11);
    ylabel('Buffer Empty [%]', 'FontSize', 11);
    title('버퍼 비어있음 비율', 'FontSize', 12, 'FontWeight', 'bold');
    ylim([0, 100]);
    yline(30, 'r--', '30% 기준', 'LineWidth', 1.5);
else
    text(0.5, 0.5, 'buffer_empty_ratio data not found', ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'r');
    title('버퍼 비어있음 비율 (N/A)', 'FontSize', 12);
    set(gca, 'XTick', [], 'YTick', []);
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 7: 지연 분해 (Stacked Bar) ⭐
% ─────────────────────────────────────────────────────────────────────
subplot(3, 3, 7);

% T_total = T_uora + T_other
T_other = mean_delay - mean_uora_delay;
T_other(T_other < 0) = 0;

bar_delay = [mean_uora_delay, T_other];
b_delay = bar(L_cell, bar_delay, 'stacked');
b_delay(1).FaceColor = [0.9, 0.5, 0.2];  % UORA: 주황
b_delay(2).FaceColor = [0.5, 0.5, 0.5];  % Other: 회색

grid on;
xlabel('L_{cell}', 'FontSize', 11);
ylabel('Delay [ms]', 'FontSize', 11);
title('지연 분해 (Stacked)', 'FontSize', 12, 'FontWeight', 'bold');
legend({'T_{UORA}', 'T_{Other}'}, 'Location', 'northwest');

% ─────────────────────────────────────────────────────────────────────
% Subplot 8: Implicit BSR 비율 (참고용)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 3, 8);
plot(L_cell, implicit_bsr * 100, 'c-o', 'LineWidth', 2, 'MarkerFaceColor', 'c');
hold on;
plot(L_cell, (1 - implicit_bsr) * 100, 'r-s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
grid on;
xlabel('L_{cell}', 'FontSize', 11);
ylabel('BSR Ratio [%]', 'FontSize', 11);
title('BSR 비율 (참고)', 'FontSize', 12, 'FontWeight', 'bold');
legend({'Implicit', 'Explicit'}, 'Location', 'best');
ylim([0, 100]);

% ─────────────────────────────────────────────────────────────────────
% Subplot 9: Unsaturated 영역 표시
% ─────────────────────────────────────────────────────────────────────
subplot(3, 3, 9);
if has_buffer_empty
    % Buffer Empty vs UORA Delay
    scatter(buffer_empty * 100, mean_uora_delay, 100, L_cell, 'filled');
    hold on;
    
    % Unsaturated 영역 표시
    if any(unsaturated_mask)
        scatter(buffer_empty(unsaturated_mask) * 100, ...
            mean_uora_delay(unsaturated_mask), 150, 'r', 'filled', 'MarkerEdgeColor', 'k');
    end
    
    % 기준선
    xline(30, 'r--', 'LineWidth', 1.5);
    
    grid on;
    xlabel('Buffer Empty [%]', 'FontSize', 11);
    ylabel('UORA Delay [ms]', 'FontSize', 11);
    title('Unsaturated 영역', 'FontSize', 12, 'FontWeight', 'bold');
    colorbar;
    caxis([min(L_cell), max(L_cell)]);
    ylabel(colorbar, 'L_{cell}');
    legend({'All', 'Unsaturated', '30% 기준'}, 'Location', 'best');
else
    text(0.5, 0.5, 'Data N/A', 'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'r');
    title('Unsaturated 영역 (N/A)', 'FontSize', 12);
    set(gca, 'XTick', [], 'YTick', []);
end

% ─────────────────────────────────────────────────────────────────────
% 전체 제목
% ─────────────────────────────────────────────────────────────────────
sgtitle('Exp 1-1: Unsaturated 환경 분석 (절대값 중심)', ...
    'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  5. 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fig_filename = sprintf('%s/exp1_1_unsaturated_analysis_v2.png', fig_dir);
saveas(fig, fig_filename);
fprintf('  ✓ Figure 저장: %s\n', fig_filename);

% PDF도 저장 (고품질)
fig_filename_pdf = sprintf('%s/exp1_1_unsaturated_analysis_v2.pdf', fig_dir);
exportgraphics(fig, fig_filename_pdf, 'ContentType', 'vector');
fprintf('  ✓ PDF 저장: %s\n', fig_filename_pdf);

fprintf('\n🎉 분석 완료! (v2 - 절대값 중심)\n\n');

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