%% exp2_03_v3_optimization.m
% Experiment 2-03: v3 핵심 파라미터 최적화
%
% 목적:
%   v3_EMA_alpha × v3_max_reduction 2D 스윕으로 최적 조합 탐색
%
% 구조:
%   EMA_alpha(5) × max_reduction(4) × scheme(2) × runs(10) = 400회
%
% 파라미터 의미:
%   - EMA_alpha: 작을수록 장기 추세, 클수록 최근값 민감
%   - max_reduction: 작을수록 보수적, 클수록 공격적 감산
%
% 고정값 (Exp 2-02 결과):
%   - reduction_threshold = 4000 bytes
%   - burst_threshold = 12000 bytes
%
% 예상 소요 시간: ~20분

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

exp_config = get_exp2_03_config();

%% =====================================================================
%  2. 실험 실행
%  =====================================================================

results = run_exp2_03(exp_config);

%% =====================================================================
%  3. 결과 저장
%  =====================================================================

fprintf('[결과 저장]\n');

% MAT 파일 저장
mat_dir = 'results/mat';
if ~exist(mat_dir, 'dir'), mkdir(mat_dir); end

timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
mat_filename = sprintf('%s/%s_%s.mat', mat_dir, exp_config.name, timestamp_str);

save(mat_filename, 'results', '-v7.3');
fprintf('  ✓ MAT 저장: %s\n', mat_filename);

% CSV 저장
csv_dir = 'results/csv';
if ~exist(csv_dir, 'dir'), mkdir(csv_dir); end

csv_filename = sprintf('%s/%s_summary.csv', csv_dir, exp_config.name);

% 테이블 생성
n_alpha = length(exp_config.sweep_range);
n_maxred = length(exp_config.sweep_range2);
n_schemes = length(exp_config.schemes);
n_rows = n_alpha * n_maxred * n_schemes;

T = table();
alpha_col = zeros(n_rows, 1);
maxred_col = zeros(n_rows, 1);
scheme_col = cell(n_rows, 1);

row_idx = 0;
for a = 1:n_alpha
    for m = 1:n_maxred
        for sc = 1:n_schemes
            row_idx = row_idx + 1;
            alpha_col(row_idx) = exp_config.sweep_range(a);
            maxred_col(row_idx) = exp_config.sweep_range2(m);
            scheme_col{row_idx} = exp_config.scheme_names{sc};
        end
    end
end

T.EMA_alpha = alpha_col;
T.max_reduction = maxred_col;
T.Scheme = scheme_col;

% 주요 지표 추가
key_metrics = exp_config.metrics_to_collect;
for i = 1:length(key_metrics)
    metric = key_metrics{i};
    if isfield(results.summary.mean, metric)
        mean_data = results.summary.mean.(metric);
        std_data = results.summary.std.(metric);
        
        T.([metric '_mean']) = mean_data(:);
        T.([metric '_std']) = std_data(:);
    end
end

writetable(T, csv_filename);
fprintf('  ✓ CSV 저장: %s\n\n', csv_filename);

%% =====================================================================
%  4. 핵심 결과 분석
%  =====================================================================

fprintf('========================================\n');
fprintf('  v3 개선률 (Baseline 대비)\n');
fprintf('========================================\n\n');

mean_delay = results.summary.mean.mean_delay_ms;  % [alpha, maxred, scheme]
std_delay_metric = results.summary.mean.std_delay_ms;
p90_delay = results.summary.mean.p90_delay_ms;    % 🆕 P90
mean_uora = results.summary.mean.mean_uora_delay_ms;
mean_explicit = results.summary.mean.explicit_bsr_count;

alpha_vals = exp_config.sweep_range;
maxred_vals = exp_config.sweep_range2;

% 개선률 계산: [alpha, maxred]
delay_improvement = zeros(n_alpha, n_maxred);     % Mean
p90_improvement = zeros(n_alpha, n_maxred);       % 🆕 P90
std_improvement = zeros(n_alpha, n_maxred);       % Variance
uora_improvement = zeros(n_alpha, n_maxred);
exp_bsr_reduction = zeros(n_alpha, n_maxred);

for a = 1:n_alpha
    for m = 1:n_maxred
        % Baseline (scheme=1) vs v3 (scheme=2)
        baseline_delay = mean_delay(a, m, 1);
        v3_delay = mean_delay(a, m, 2);
        delay_improvement(a, m) = (1 - v3_delay / baseline_delay) * 100;
        
        % 🆕 P90 개선률
        baseline_p90 = p90_delay(a, m, 1);
        v3_p90 = p90_delay(a, m, 2);
        p90_improvement(a, m) = (1 - v3_p90 / baseline_p90) * 100;
        
        baseline_std = std_delay_metric(a, m, 1);
        v3_std = std_delay_metric(a, m, 2);
        std_improvement(a, m) = (1 - v3_std / baseline_std) * 100;
        
        baseline_uora = mean_uora(a, m, 1);
        v3_uora = mean_uora(a, m, 2);
        uora_improvement(a, m) = (1 - v3_uora / baseline_uora) * 100;
        
        baseline_exp = mean_explicit(a, m, 1);
        v3_exp = mean_explicit(a, m, 2);
        exp_bsr_reduction(a, m) = (1 - v3_exp / baseline_exp) * 100;
    end
end

% 테이블 출력: Mean 지연 개선률
fprintf('Mean 지연 개선률 [%%] (행: EMA_alpha, 열: max_reduction)\n');
fprintf('%12s |', '');
for m = 1:n_maxred
    fprintf(' %8.1f', maxred_vals(m));
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 12 + n_maxred * 9));

for a = 1:n_alpha
    fprintf('%12.1f |', alpha_vals(a));
    for m = 1:n_maxred
        fprintf(' %+7.1f%%', delay_improvement(a, m));
    end
    fprintf('\n');
end

% 🆕 테이블 출력: P90 지연 개선률
fprintf('\nP90 지연 개선률 [%%] (행: EMA_alpha, 열: max_reduction)\n');
fprintf('%12s |', '');
for m = 1:n_maxred
    fprintf(' %8.1f', maxred_vals(m));
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 12 + n_maxred * 9));

for a = 1:n_alpha
    fprintf('%12.1f |', alpha_vals(a));
    for m = 1:n_maxred
        fprintf(' %+7.1f%%', p90_improvement(a, m));
    end
    fprintf('\n');
end

% 🆕 테이블 출력: 분산 개선률
fprintf('\n분산(Std) 개선률 [%%] (행: EMA_alpha, 열: max_reduction)\n');
fprintf('%12s |', '');
for m = 1:n_maxred
    fprintf(' %8.1f', maxred_vals(m));
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 12 + n_maxred * 9));

for a = 1:n_alpha
    fprintf('%12.1f |', alpha_vals(a));
    for m = 1:n_maxred
        fprintf(' %+7.1f%%', std_improvement(a, m));
    end
    fprintf('\n');
end

%% =====================================================================
%  5. 최적 조합 찾기
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  최적 파라미터 조합\n');
fprintf('========================================\n\n');

[best_impr, best_idx] = max(delay_improvement(:));
[best_a, best_m] = ind2sub([n_alpha, n_maxred], best_idx);

fprintf('[최적 조합 - Mean 지연 기준]\n');
fprintf('  EMA_alpha: %.1f\n', alpha_vals(best_a));
fprintf('  max_reduction: %.1f\n', maxred_vals(best_m));
fprintf('  Mean 개선률: %.1f%%\n', best_impr);
fprintf('  P90 개선률: %.1f%%\n', p90_improvement(best_a, best_m));
fprintf('  분산 개선률: %.1f%%\n', std_improvement(best_a, best_m));
fprintf('  T_uora 개선률: %.1f%%\n', uora_improvement(best_a, best_m));
fprintf('  Explicit BSR 감소: %.1f%%\n', exp_bsr_reduction(best_a, best_m));

% 절대 지연 값
fprintf('\n[절대 지연 값]\n');
fprintf('  Baseline Mean: %.2f ms\n', mean_delay(best_a, best_m, 1));
fprintf('  v3 Mean:       %.2f ms\n', mean_delay(best_a, best_m, 2));
fprintf('  Baseline P90:  %.2f ms\n', p90_delay(best_a, best_m, 1));
fprintf('  v3 P90:        %.2f ms\n', p90_delay(best_a, best_m, 2));

% 🆕 P90 기준 최적 조합
[best_p90_impr, best_p90_idx] = max(p90_improvement(:));
[best_p90_a, best_p90_m] = ind2sub([n_alpha, n_maxred], best_p90_idx);

fprintf('\n[최적 조합 - P90 지연 기준]\n');
fprintf('  EMA_alpha: %.1f\n', alpha_vals(best_p90_a));
fprintf('  max_reduction: %.1f\n', maxred_vals(best_p90_m));
fprintf('  P90 개선률: %.1f%%\n', best_p90_impr);
fprintf('  v3:       %.2f ms\n', mean_delay(best_a, best_m, 2));

% 분산 최적도 확인
[best_std_impr, best_std_idx] = max(std_improvement(:));
[best_std_a, best_std_m] = ind2sub([n_alpha, n_maxred], best_std_idx);

fprintf('\n[최적 조합 - 분산 기준]\n');
fprintf('  EMA_alpha: %.1f\n', alpha_vals(best_std_a));
fprintf('  max_reduction: %.1f\n', maxred_vals(best_std_m));
fprintf('  분산 개선률: %.1f%%\n', best_std_impr);

%% =====================================================================
%  6. 파라미터별 경향 분석
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  파라미터별 경향 분석\n');
fprintf('========================================\n\n');

% EMA_alpha 고정 시 max_reduction 영향
fprintf('[max_reduction 영향 (EMA_alpha=%.1f 고정)]\n', alpha_vals(best_a));
for m = 1:n_maxred
    fprintf('  max_red=%.1f: 개선률 %+.1f%%\n', maxred_vals(m), delay_improvement(best_a, m));
end

% max_reduction 고정 시 EMA_alpha 영향
fprintf('\n[EMA_alpha 영향 (max_reduction=%.1f 고정)]\n', maxred_vals(best_m));
for a = 1:n_alpha
    fprintf('  alpha=%.1f: 개선률 %+.1f%%\n', alpha_vals(a), delay_improvement(a, best_m));
end

%% =====================================================================
%  7. 시각화 - 핵심 지표 (Heatmap 6개: 2x3 레이아웃)
%  =====================================================================

fprintf('\n[시각화 생성]\n');

fig = figure('Position', [100, 100, 1600, 900], 'Visible', 'on');

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: Mean 지연 개선률 Heatmap
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 1);
imagesc(delay_improvement);
colorbar;
colormap(subplot(2,3,1), flipud(hot));
caxis([min(delay_improvement(:))-0.5, max(delay_improvement(:))+0.5]);

set(gca, 'XTick', 1:n_maxred, 'XTickLabel', arrayfun(@(x) sprintf('%.1f', x), maxred_vals, 'UniformOutput', false));
set(gca, 'YTick', 1:n_alpha, 'YTickLabel', arrayfun(@(x) sprintf('%.1f', x), alpha_vals, 'UniformOutput', false));
xlabel('max\_reduction');
ylabel('EMA\_alpha');
title('Mean 지연 개선률 [%]');

% 값 표시
for a = 1:n_alpha
    for m = 1:n_maxred
        text(m, a, sprintf('%.1f', delay_improvement(a, m)), ...
            'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
    end
end

% 최적점 표시
hold on;
plot(best_m, best_a, 'go', 'MarkerSize', 25, 'LineWidth', 3);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: P90 지연 개선률 Heatmap (🆕)
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 2);
imagesc(p90_improvement);
colorbar;
colormap(subplot(2,3,2), flipud(hot));
caxis([min(p90_improvement(:))-0.5, max(p90_improvement(:))+0.5]);

set(gca, 'XTick', 1:n_maxred, 'XTickLabel', arrayfun(@(x) sprintf('%.1f', x), maxred_vals, 'UniformOutput', false));
set(gca, 'YTick', 1:n_alpha, 'YTickLabel', arrayfun(@(x) sprintf('%.1f', x), alpha_vals, 'UniformOutput', false));
xlabel('max\_reduction');
ylabel('EMA\_alpha');
title('P90 지연 개선률 [%]');

for a = 1:n_alpha
    for m = 1:n_maxred
        text(m, a, sprintf('%.1f', p90_improvement(a, m)), ...
            'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
    end
end

% P90 최적점 표시
hold on;
plot(best_p90_m, best_p90_a, 'co', 'MarkerSize', 25, 'LineWidth', 3);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: 분산 개선률 Heatmap
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 3);
imagesc(std_improvement);
colorbar;
colormap(subplot(2,3,3), flipud(hot));

set(gca, 'XTick', 1:n_maxred, 'XTickLabel', arrayfun(@(x) sprintf('%.1f', x), maxred_vals, 'UniformOutput', false));
set(gca, 'YTick', 1:n_alpha, 'YTickLabel', arrayfun(@(x) sprintf('%.1f', x), alpha_vals, 'UniformOutput', false));
xlabel('max\_reduction');
ylabel('EMA\_alpha');
title('지연 분산 개선률 [%]');

for a = 1:n_alpha
    for m = 1:n_maxred
        text(m, a, sprintf('%.1f', std_improvement(a, m)), ...
            'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
    end
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: T_uora 개선률 Heatmap
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 4);
imagesc(uora_improvement);
colorbar;
colormap(subplot(2,3,4), flipud(hot));

set(gca, 'XTick', 1:n_maxred, 'XTickLabel', arrayfun(@(x) sprintf('%.1f', x), maxred_vals, 'UniformOutput', false));
set(gca, 'YTick', 1:n_alpha, 'YTickLabel', arrayfun(@(x) sprintf('%.1f', x), alpha_vals, 'UniformOutput', false));
xlabel('max\_reduction');
ylabel('EMA\_alpha');
title('T_{uora} 개선률 [%]');

for a = 1:n_alpha
    for m = 1:n_maxred
        text(m, a, sprintf('%.1f', uora_improvement(a, m)), ...
            'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
    end
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 5: Line plot - Mean (alpha별 max_reduction 영향)
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 5);
hold on;

colors = lines(n_alpha);
markers = {'o', 's', '^', 'd', 'v'};

for a = 1:n_alpha
    plot(maxred_vals, delay_improvement(a, :), '-', ...
        'Color', colors(a, :), ...
        'Marker', markers{a}, ...
        'MarkerFaceColor', colors(a, :), ...
        'MarkerSize', 10, 'LineWidth', 2, ...
        'DisplayName', sprintf('\\alpha=%.1f', alpha_vals(a)));
end
hold off;

xlabel('max\_reduction');
ylabel('Mean Delay Improvement [%]');
title('Mean: alpha별 max\_reduction 영향');
legend('Location', 'best');
grid on;

% ─────────────────────────────────────────────────────────────────────
% Subplot 6: Line plot - P90 (alpha별 max_reduction 영향)
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 6);
hold on;

for a = 1:n_alpha
    plot(maxred_vals, p90_improvement(a, :), '-', ...
        'Color', colors(a, :), ...
        'Marker', markers{a}, ...
        'MarkerFaceColor', colors(a, :), ...
        'MarkerSize', 10, 'LineWidth', 2, ...
        'DisplayName', sprintf('\\alpha=%.1f', alpha_vals(a)));
end
hold off;

xlabel('max\_reduction');
ylabel('P90 Delay Improvement [%]');
title('P90: alpha별 max\_reduction 영향');
legend('Location', 'best');
grid on;

sgtitle(sprintf('Exp 2-03: v3 핵심 파라미터 최적화 (L_{cell}=%.2f)', ...
    exp_config.scenario.L_cell), 'FontSize', 14, 'FontWeight', 'bold');

% 저장
plot_dir = 'results/figures';
if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end

plot_filename = sprintf('%s/%s.png', plot_dir, exp_config.name);
saveas(fig, plot_filename);
fprintf('  ✓ Figure 저장: %s\n', plot_filename);

pdf_filename = sprintf('%s/%s.pdf', plot_dir, exp_config.name);
saveas(fig, pdf_filename);
fprintf('  ✓ PDF 저장: %s\n', pdf_filename);

%% =====================================================================
%  8. 추가 시각화: 3D Surface
%  =====================================================================

fig2 = figure('Position', [150, 150, 800, 600], 'Visible', 'on');

[X, Y] = meshgrid(maxred_vals, alpha_vals);
surf(X, Y, delay_improvement);
colorbar;
colormap(jet);

xlabel('max\_reduction');
ylabel('EMA\_alpha');
zlabel('Delay Improvement [%]');
title('v3 파라미터 공간에서의 지연 개선률');

% 최적점 표시
hold on;
plot3(maxred_vals(best_m), alpha_vals(best_a), best_impr, ...
    'go', 'MarkerSize', 15, 'MarkerFaceColor', 'g', 'LineWidth', 2);
hold off;

view(45, 30);
grid on;

surf_filename = sprintf('%s/%s_surface.png', plot_dir, exp_config.name);
saveas(fig2, surf_filename);
fprintf('  ✓ Surface 저장: %s\n', surf_filename);

%% =====================================================================
%  9. 추가 시각화: 모든 수집 지표 (tiledlayout)
%  =====================================================================

fprintf('  [모든 지표 시각화 생성...]\n');

% 시각화할 지표 목록 (수집된 모든 지표)
all_metrics = exp_config.metrics_to_collect;
n_metrics = length(all_metrics);

% Figure 크기 계산 (4열로 배치)
n_cols = 4;
n_rows = ceil(n_metrics / n_cols);

fig3 = figure('Position', [50, 50, 1800, 300 * n_rows], 'Visible', 'on');
t = tiledlayout(n_rows, n_cols, 'TileSpacing', 'compact', 'Padding', 'compact');

for i = 1:n_metrics
    metric = all_metrics{i};
    
    ax = nexttile(t, i);
    
    if isfield(results.summary.mean, metric)
        mean_data = results.summary.mean.(metric);
        
        % v3 개선률 계산 (scheme 1 = Baseline, scheme 2 = v3)
        improvement_map = zeros(n_alpha, n_maxred);
        
        for a = 1:n_alpha
            for m = 1:n_maxred
                baseline_val = mean_data(a, m, 1);
                v3_val = mean_data(a, m, 2);
                
                if baseline_val ~= 0 && ~isnan(baseline_val)
                    improvement_map(a, m) = (1 - v3_val / baseline_val) * 100;
                else
                    improvement_map(a, m) = 0;
                end
            end
        end
        
        % Heatmap
        imagesc(ax, improvement_map);
        colorbar(ax);
        
        set(ax, 'XTick', 1:n_maxred, 'XTickLabel', arrayfun(@(x) sprintf('%.1f', x), maxred_vals, 'UniformOutput', false));
        set(ax, 'YTick', 1:n_alpha, 'YTickLabel', arrayfun(@(x) sprintf('%.1f', x), alpha_vals, 'UniformOutput', false));
        
        xlabel(ax, 'max\_red');
        ylabel(ax, '\alpha');
        
        % 지표 이름 정리 (가독성)
        metric_name = strrep(metric, '_', '\_');
        title(ax, metric_name, 'FontSize', 10);
    else
        % 지표가 없으면 빈 플롯
        text(ax, 0.5, 0.5, sprintf('%s\n(N/A)', metric), ...
            'HorizontalAlignment', 'center', 'FontSize', 10);
        axis(ax, 'off');
    end
end

sgtitle(t, 'Exp 2-03: 모든 수집 지표 개선률 [%] (v3 vs Baseline)', ...
    'FontSize', 14, 'FontWeight', 'bold');

all_metrics_filename = sprintf('%s/%s_all_metrics.png', plot_dir, exp_config.name);
saveas(fig3, all_metrics_filename);
fprintf('  ✓ All Metrics 저장: %s\n', all_metrics_filename);

%% =====================================================================
%  10. 절대값 비교 시각화 (주요 지표)
%  =====================================================================

fig4 = figure('Position', [100, 100, 1600, 900], 'Visible', 'on');
t4 = tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

key_metrics_abs = {
    'mean_delay_ms', 'Mean Delay [ms]'
    'std_delay_ms', 'Std Delay [ms]'
    'p10_delay_ms', 'P10 Delay [ms]'
    'p90_delay_ms', 'P90 Delay [ms]'
    'p99_delay_ms', 'P99 Delay [ms]'
    'mean_uora_delay_ms', 'Mean T_{uora} [ms]'
    'p90_uora_delay_ms', 'P90 T_{uora} [ms]'
    'explicit_bsr_count', 'Explicit BSR Count'
    'collision_rate', 'Collision Rate'
};

for i = 1:size(key_metrics_abs, 1)
    metric = key_metrics_abs{i, 1};
    label = key_metrics_abs{i, 2};
    
    ax = nexttile(t4, i);
    
    if isfield(results.summary.mean, metric)
        mean_data = results.summary.mean.(metric);
        
        % Line plot: alpha별로 max_reduction 변화
        hold(ax, 'on');
        
        for a = 1:n_alpha
            % Baseline (점선)
            plot(ax, maxred_vals, squeeze(mean_data(a, :, 1)), '--', ...
                'Color', colors(a, :), 'LineWidth', 1.5);
            % v3 (실선)
            plot(ax, maxred_vals, squeeze(mean_data(a, :, 2)), '-', ...
                'Color', colors(a, :), 'Marker', markers{a}, ...
                'MarkerFaceColor', colors(a, :), 'MarkerSize', 6, 'LineWidth', 2, ...
                'DisplayName', sprintf('v3 \\alpha=%.1f', alpha_vals(a)));
        end
        
        hold(ax, 'off');
        xlabel(ax, 'max\_reduction');
        ylabel(ax, label);
        title(ax, label, 'FontSize', 11, 'FontWeight', 'bold');
        grid(ax, 'on');
        
        if i == 1
            legend(ax, 'Location', 'best', 'FontSize', 7);
        end
    end
end

sgtitle(t4, 'Exp 2-03: 주요 지표 절대값 비교 (점선=Baseline, 실선=v3)', ...
    'FontSize', 14, 'FontWeight', 'bold');

abs_filename = sprintf('%s/%s_absolute.png', plot_dir, exp_config.name);
saveas(fig4, abs_filename);
fprintf('  ✓ Absolute 저장: %s\n', abs_filename);

%% =====================================================================
%  11. 최종 결론
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  최종 결론\n');
fprintf('========================================\n\n');

fprintf('[v3 최적 파라미터]\n');
fprintf('  ┌─────────────────────────────────────┐\n');
fprintf('  │  EMA_alpha:      %.1f               │\n', alpha_vals(best_a));
fprintf('  │  max_reduction:  %.1f               │\n', maxred_vals(best_m));
fprintf('  │  지연 개선률:    %.1f%%              │\n', best_impr);
fprintf('  └─────────────────────────────────────┘\n\n');

fprintf('[고정 파라미터 (Exp 2-02 결과)]\n');
fprintf('  reduction_threshold: %d bytes\n', exp_config.fixed.reduction_threshold);
fprintf('  burst_threshold: %d bytes\n', exp_config.fixed.burst_threshold);
fprintf('  sensitivity: %.1f\n', exp_config.fixed.v3_sensitivity);

fprintf('\n→ 이 파라미터로 다른 환경(Mid, High)에서도 검증 필요\n');
fprintf('→ 다음 단계: 최적 파라미터로 3개 환경 비교 실험\n\n');

fprintf('🎉 Experiment 2-03 완료!\n\n');