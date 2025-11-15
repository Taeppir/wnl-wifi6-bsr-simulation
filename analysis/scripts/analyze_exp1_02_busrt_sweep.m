%% analyze_exp1_02_burst_sweep.m
% Experiment 1-2 분석: 버스트 강도(rho, alpha) 스윕
%
% Research Question: 
%   Pareto 파라미터(rho, alpha)가 UORA 경쟁과 큐잉 지연에 미치는 영향은?
%
% 분석 목표:
%   1. Unsaturated 영역 탐색 (2D 마스크)
%   2. 6개 핵심 지표 히트맵 생성
%   3. Sweet Spot (rho, alpha) 조합 추천

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 1-2: 버스트 강도 스윕 분석\n');
fprintf('========================================\n\n');

exp = load_experiment('exp1_2_burst_sweep');

% 축 정보
rho_range = exp.config.sweep_range;      % rho (On-state Ratio)
alpha_range = exp.config.sweep_range2;   % alpha (Pareto Shape)

n_rho = length(rho_range);
n_alpha = length(alpha_range);

% 데이터 추출 (Summary Mean)
mean_delay = exp.summary.mean.mean_delay_ms;
std_delay = exp.summary.mean.std_delay_ms;
mean_uora_delay = exp.summary.mean.mean_uora_delay_ms;
collision_rate = exp.summary.mean.collision_rate;
completion_rate = exp.summary.mean.completion_rate;
implicit_bsr = exp.summary.mean.implicit_bsr_ratio;

% Buffer Empty (있으면 사용)
if isfield(exp.summary.mean, 'buffer_empty_ratio')
    buffer_empty = exp.summary.mean.buffer_empty_ratio;
    has_buffer_empty = true;
else
    buffer_empty = nan(size(mean_delay));
    has_buffer_empty = false;
    warning('buffer_empty_ratio가 결과에 없습니다.');
end

%% =====================================================================
%  2. Unsaturated 조건 판단 (2D 마스크)
%  =====================================================================

fprintf('[Unsaturated 영역 탐색]\n');
if has_buffer_empty
    fprintf('  기준:\n');
    fprintf('    1. 버퍼 비어있음 비율 >= 30%%\n');
    fprintf('    2. UORA 지연 > 0 ms\n');
    fprintf('    3. 완료율 >= 85%%\n');
    fprintf('    4. Implicit BSR >= 50%%\n\n');
    
    condition1 = buffer_empty >= 0.30;
else
    fprintf('  기준 (대안):\n');
    fprintf('    1. Implicit BSR >= 60%%\n');
    fprintf('    2. UORA 지연 > 0 ms\n');
    fprintf('    3. 완료율 >= 85%%\n');
    fprintf('    4. 충돌률 < 40%%\n\n');
    
    condition1 = implicit_bsr >= 0.60;
end

condition2 = mean_uora_delay > 0;
condition3 = completion_rate >= 0.85;

if has_buffer_empty
    condition4 = implicit_bsr >= 0.50;
else
    condition4 = collision_rate < 0.40;
end

% 2D 마스크 생성 (모든 조건 만족)
unsaturated_mask = condition1 & condition2 & condition3 & condition4;

% 조건 만족하는 (rho, alpha) 조합 출력
num_unsaturated = sum(unsaturated_mask(:));

if num_unsaturated > 0
    fprintf('[결과] Unsaturated 조건을 만족하는 조합:\n');
    fprintf('  총 %d개 / %d개 (%.1f%%)\n\n', num_unsaturated, n_rho * n_alpha, ...
        100 * num_unsaturated / (n_rho * n_alpha));
    
    fprintf('%-8s | %-8s | %10s | %10s | %10s | %10s\n', ...
        'rho', 'alpha', 'Delay(ms)', 'BufEmpty', 'Impl', 'Compl');
    fprintf('%s\n', repmat('-', 1, 70));
    
    [rho_idx, alpha_idx] = find(unsaturated_mask);
    for i = 1:length(rho_idx)
        r_idx = rho_idx(i);
        a_idx = alpha_idx(i);
        
        fprintf('%-8.1f | %-8.1f | %10.2f | %9.1f%% | %9.1f%% | %9.1f%%\n', ...
            rho_range(r_idx), alpha_range(a_idx), ...
            mean_delay(r_idx, a_idx), ...
            buffer_empty(r_idx, a_idx) * 100, ...
            implicit_bsr(r_idx, a_idx) * 100, ...
            completion_rate(r_idx, a_idx) * 100);
    end
    fprintf('\n');
else
    fprintf('[결과] ⚠️  Unsaturated 조건을 만족하는 조합이 없습니다!\n');
    fprintf('  → 기준을 완화하거나 실험 범위를 조정하세요.\n\n');
end

%% =====================================================================
%  3. Sweet Spot 추천 (최적 조합 선정)
%  =====================================================================

if num_unsaturated > 0
    fprintf('[Sweet Spot 추천]\n');
    
    % 점수 계산: Buffer Empty × UORA Delay (높을수록 좋음)
    if has_buffer_empty
        score = buffer_empty .* mean_uora_delay;
    else
        score = implicit_bsr .* mean_uora_delay;
    end
    
    % Unsaturated가 아닌 영역은 NaN 처리
    score(~unsaturated_mask) = NaN;
    
    % 최댓값 찾기
    [max_score, max_idx] = max(score(:));
    
    if ~isnan(max_score)
        [best_rho_idx, best_alpha_idx] = ind2sub(size(score), max_idx);
        best_rho = rho_range(best_rho_idx);
        best_alpha = alpha_range(best_alpha_idx);
        
        fprintf('  추천 조합: rho=%.1f, alpha=%.1f\n', best_rho, best_alpha);
        if has_buffer_empty
            fprintf('    - 버퍼 비어있음: %.1f%%\n', buffer_empty(best_rho_idx, best_alpha_idx) * 100);
        end
        fprintf('    - Implicit BSR: %.1f%%\n', implicit_bsr(best_rho_idx, best_alpha_idx) * 100);
        fprintf('    - UORA 지연: %.2f ms\n', mean_uora_delay(best_rho_idx, best_alpha_idx));
        fprintf('    - 평균 지연: %.2f ms\n', mean_delay(best_rho_idx, best_alpha_idx));
        fprintf('    - 충돌률: %.1f%%\n', collision_rate(best_rho_idx, best_alpha_idx) * 100);
        fprintf('\n');
    end
end

%% =====================================================================
%  4. 시각화 (6-Panel Heatmap)
%  =====================================================================

fprintf('[시각화 생성 중...]\n');

fig = figure('Position', [100, 100, 1400, 1000]);

% 축 레이블
rho_labels = arrayfun(@(x) sprintf('%.1f', x), rho_range, 'UniformOutput', false);
alpha_labels = arrayfun(@(x) sprintf('%.1f', x), alpha_range, 'UniformOutput', false);

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: 평균 큐잉 지연
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 1);
imagesc(mean_delay');
colorbar;
title('평균 큐잉 지연 (ms)');
ylabel('\alpha (Pareto Shape)');
xlabel('\rho (On-state Ratio)');
set(gca, 'XTick', 1:n_rho, 'XTickLabel', rho_labels);
set(gca, 'YTick', 1:n_alpha, 'YTickLabel', alpha_labels);

% Unsaturated 영역 표시
if num_unsaturated > 0
    hold on;
    [rho_idx_plot, alpha_idx_plot] = find(unsaturated_mask);
    plot(rho_idx_plot, alpha_idx_plot, 'wo', 'MarkerSize', 8, 'LineWidth', 2);
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: UORA 지연
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 2);
imagesc(mean_uora_delay');
colorbar;
title('UORA 지연 (경쟁 강도, ms)');
ylabel('\alpha (Pareto Shape)');
xlabel('\rho (On-state Ratio)');
set(gca, 'XTick', 1:n_rho, 'XTickLabel', rho_labels);
set(gca, 'YTick', 1:n_alpha, 'YTickLabel', alpha_labels);

if num_unsaturated > 0
    hold on;
    plot(rho_idx_plot, alpha_idx_plot, 'wo', 'MarkerSize', 8, 'LineWidth', 2);
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: 지연 표준편차 (불안정성)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 3);
imagesc(std_delay');
colorbar;
title('지연 표준편차 (ms) - 낮을수록 안정적');
ylabel('\alpha (Pareto Shape)');
xlabel('\rho (On-state Ratio)');
set(gca, 'XTick', 1:n_rho, 'XTickLabel', rho_labels);
set(gca, 'YTick', 1:n_alpha, 'YTickLabel', alpha_labels);

if num_unsaturated > 0
    hold on;
    plot(rho_idx_plot, alpha_idx_plot, 'wo', 'MarkerSize', 8, 'LineWidth', 2);
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: UORA 충돌률
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 4);
imagesc(collision_rate' * 100);
colorbar;
title('UORA 충돌률 (%)');
ylabel('\alpha (Pareto Shape)');
xlabel('\rho (On-state Ratio)');
set(gca, 'XTick', 1:n_rho, 'XTickLabel', rho_labels);
set(gca, 'YTick', 1:n_alpha, 'YTickLabel', alpha_labels);
caxis([0, max(max(collision_rate(:) * 100), 50)]);

if num_unsaturated > 0
    hold on;
    plot(rho_idx_plot, alpha_idx_plot, 'wo', 'MarkerSize', 8, 'LineWidth', 2);
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 5: Implicit BSR 비율
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 5);
imagesc(implicit_bsr' * 100);
colorbar;
title('Implicit BSR 비율 (%)');
ylabel('\alpha (Pareto Shape)');
xlabel('\rho (On-state Ratio)');
set(gca, 'XTick', 1:n_rho, 'XTickLabel', rho_labels);
set(gca, 'YTick', 1:n_alpha, 'YTickLabel', alpha_labels);
caxis([0, 100]);

if num_unsaturated > 0
    hold on;
    plot(rho_idx_plot, alpha_idx_plot, 'wo', 'MarkerSize', 8, 'LineWidth', 2);
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 6: 버퍼 비어있음 비율
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 6);
if has_buffer_empty
    imagesc(buffer_empty' * 100);
    colorbar;
    title('버퍼 비어있음 비율 (%)');
    ylabel('\alpha (Pareto Shape)');
    xlabel('\rho (On-state Ratio)');
    set(gca, 'XTick', 1:n_rho, 'XTickLabel', rho_labels);
    set(gca, 'YTick', 1:n_alpha, 'YTickLabel', alpha_labels);
    caxis([0, 100]);
    
    if num_unsaturated > 0
        hold on;
        plot(rho_idx_plot, alpha_idx_plot, 'wo', 'MarkerSize', 8, 'LineWidth', 2);
    end
else
    text(0.5, 0.5, 'buffer_empty_ratio data not found', ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'r');
    title('버퍼 비어있음 비율 (Data N/A)');
    set(gca, 'XTick', [], 'YTick', []);
end

% ─────────────────────────────────────────────────────────────────────
% 전체 제목
% ─────────────────────────────────────────────────────────────────────
sgtitle(sprintf('Exp 1-2: 버스트 강도(rho, alpha) 분석 (L_{cell}=%.1f)', ...
    exp.config.fixed.L_cell), 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  5. 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fig_filename = sprintf('%s/exp1_2_burst_sweep_analysis.png', fig_dir);
saveas(fig, fig_filename);
fprintf('  ✓ Figure 저장: %s\n', fig_filename);

% PDF도 저장 (고품질)
fig_filename_pdf = sprintf('%s/exp1_2_burst_sweep_analysis.pdf', fig_dir);
exportgraphics(fig, fig_filename_pdf, 'ContentType', 'vector');
fprintf('  ✓ PDF 저장: %s\n', fig_filename_pdf);

fprintf('\n🎉 분석 완료!\n\n');
