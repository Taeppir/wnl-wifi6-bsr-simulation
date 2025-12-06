%% analyze_exp2_03_scheme2_opt.m
% Experiment 2-3: Scheme 2 파라미터 최적화 분석

clear; close all; clc;

fprintf('========================================\n');
fprintf('  Exp 2-3: Scheme 2 최적화 분석\n');
fprintf('========================================\n\n');

%% =====================================================================
%  1. 데이터 로드
%  =====================================================================

exp = load_experiment('exp2_3_scheme2_optimization');

max_reduction_range = exp.config.sweep_range;
sensitivity_range = exp.config.sweep_range2;

mean_delay = exp.summary.mean.mean_delay_ms;
mean_collision = exp.summary.mean.collision_rate;


% Summary [n_fixed, n_sens]
mean_delay = exp.summary.mean.mean_delay_ms;
mean_collision = exp.summary.mean.collision_rate;
mean_explicit_bsr = exp.summary.mean.explicit_bsr_count;

%% =====================================================================
%  2. 시각화
%  =====================================================================

fprintf('[시각화 생성 중...]\n');

fig = figure('Position', [100, 100, 1600, 500]);

% Subplot 1: Mean Delay Heatmap
subplot(1, 3, 1);
imagesc(mean_delay');
colorbar;
set(gca, 'XTick', 1:n_fixed, ...
    'XTickLabel', arrayfun(@(x) sprintf('%d', x), fixed_reduction_range, 'UniformOutput', false));
set(gca, 'YTick', 1:n_sens, ...
    'YTickLabel', arrayfun(@(x) sprintf('%.1f', x), sensitivity_range, 'UniformOutput', false));
xlabel('Fixed Reduction [bytes]');
ylabel('Sensitivity');
title('Mean Delay [ms]');

% Baseline 비교선
if isfield(exp.raw_data, 'baseline_delay')
    hold on;
    contour(mean_delay', [exp.raw_data.baseline_delay, exp.raw_data.baseline_delay], ...
        'r--', 'LineWidth', 2);
    hold off;
end

% Subplot 2: Collision Rate
subplot(1, 3, 2);
imagesc(mean_collision' * 100);
colorbar;
set(gca, 'XTick', 1:n_fixed, ...
    'XTickLabel', arrayfun(@(x) sprintf('%d', x), fixed_reduction_range, 'UniformOutput', false));
set(gca, 'YTick', 1:n_sens, ...
    'YTickLabel', arrayfun(@(x) sprintf('%.1f', x), sensitivity_range, 'UniformOutput', false));
xlabel('Fixed Reduction [bytes]');
ylabel('Sensitivity');
title('Collision Rate [%]');

% Subplot 3: Explicit BSR Count
subplot(1, 3, 3);
imagesc(mean_explicit_bsr');
colorbar;
set(gca, 'XTick', 1:n_fixed, ...
    'XTickLabel', arrayfun(@(x) sprintf('%d', x), fixed_reduction_range, 'UniformOutput', false));
set(gca, 'YTick', 1:n_sens, ...
    'YTickLabel', arrayfun(@(x) sprintf('%.1f', x), sensitivity_range, 'UniformOutput', false));
xlabel('Fixed Reduction [bytes]');
ylabel('Sensitivity');
title('Explicit BSR Count');

sgtitle('Exp 2-2: Scheme 1 파라미터 최적화', 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  3. 최적값 찾기
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  최적 파라미터\n');
fprintf('========================================\n\n');

[min_delay, min_idx] = min(mean_delay(:));
[opt_i, opt_j] = ind2sub(size(mean_delay), min_idx);

fprintf('[최적 조합 (Mean Delay 기준)]\n');
fprintf('  fixed_reduction: %d bytes\n', fixed_reduction_range(opt_i));
fprintf('  sensitivity: %.1f\n', sensitivity_range(opt_j));
fprintf('  평균 지연: %.2f ms\n', min_delay);
fprintf('  충돌률: %.1f%%\n', mean_collision(opt_i, opt_j) * 100);
fprintf('  Explicit BSR: %.0f회\n', mean_explicit_bsr(opt_i, opt_j));

if isfield(exp.raw_data, 'baseline_delay')
    baseline = exp.raw_data.baseline_delay;
    improvement = (1 - min_delay / baseline) * 100;
    fprintf('\n  Baseline: %.2f ms\n', baseline);
    fprintf('  개선률: %.1f%%\n', improvement);
end

%% =====================================================================
%  4. 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fig_filename = sprintf('%s/exp2_2_scheme1_optimization.png', fig_dir);
saveas(fig, fig_filename);
exportgraphics(fig, [fig_filename(1:end-3), 'pdf'], 'ContentType', 'vector');

fprintf('\n  ✓ Figure 저장: %s\n', fig_filename);
fprintf('\n🎉 분석 완료!\n\n');