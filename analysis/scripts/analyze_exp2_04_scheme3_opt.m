%% analyze_exp2_04_scheme3_opt.m
% Experiment 2-4: Scheme 3 파라미터 최적화 분석
%
% 스윕 변수:
%   - EMA_alpha: EMA 평활 계수
%   - max_reduction: 최대 감소 비율
%
% 출력:
%   - 2D 히트맵 (Mean Delay, Collision, Explicit BSR)
%   - 최적 파라미터 도출

clear; close all; clc;

fprintf('========================================\n');
fprintf('  Exp 2-4: Scheme 3 최적화 분석\n');
fprintf('========================================\n\n');

%% =====================================================================
%  1. 데이터 로드
%  =====================================================================

try
    exp = load_experiment('exp2_4_scheme3_optimization');
catch ME
    fprintf('💥 [오류] 실험 결과를 찾을 수 없습니다.\n');
    fprintf('   먼저 exp2_04_scheme3_optimization.m을 실행하세요.\n');
    rethrow(ME);
end

ema_alpha_range = exp.config.sweep_range;
max_reduction_range = exp.config.sweep_range2;

n_alpha = length(ema_alpha_range);
n_max = length(max_reduction_range);

fprintf('  [데이터 확인]\n');
fprintf('    EMA_alpha: %s\n', mat2str(ema_alpha_range));
fprintf('    max_reduction: %s\n', mat2str(max_reduction_range));
fprintf('    Grid 크기: %d × %d\n\n', n_alpha, n_max);

%% =====================================================================
%  2. Summary 추출
%  =====================================================================

% Summary [n_alpha, n_max]
mean_delay = exp.summary.mean.mean_delay_ms;
std_delay = exp.summary.std.mean_delay_ms;
mean_collision = exp.summary.mean.collision_rate;
mean_explicit_bsr = exp.summary.mean.explicit_bsr_count;
mean_buffer_empty = exp.summary.mean.buffer_empty_ratio;
mean_throughput = exp.summary.mean.throughput_mbps;
mean_completion = exp.summary.mean.completion_rate;

% Baseline (있으면)
if isfield(exp.raw_data, 'baseline_delay')
    baseline_delay = exp.raw_data.baseline_delay;
    has_baseline = true;
    fprintf('  Baseline 평균 지연: %.2f ms\n\n', baseline_delay);
else
    has_baseline = false;
end

%% =====================================================================
%  3. 시각화
%  =====================================================================

fprintf('[시각화 생성 중...]\n');

fig = figure('Position', [100, 100, 1800, 1000]);

% 색상 설정
cmap = parula;

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: Mean Delay Heatmap
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 1);
imagesc(ema_alpha_range, max_reduction_range, mean_delay');
colorbar;
colormap(cmap);
set(gca, 'YDir', 'normal');
xlabel('EMA \alpha', 'FontSize', 11);
ylabel('Max Reduction', 'FontSize', 11);
title('Mean Delay [ms]', 'FontSize', 13, 'FontWeight', 'bold');

% Baseline 등고선 추가
if has_baseline
    hold on;
    contour(ema_alpha_range, max_reduction_range, mean_delay', ...
        [baseline_delay, baseline_delay], 'r--', 'LineWidth', 2);
    hold off;
end

% 최적점 표시
[min_delay, min_idx] = min(mean_delay(:));
[opt_i, opt_j] = ind2sub(size(mean_delay), min_idx);
hold on;
plot(ema_alpha_range(opt_i), max_reduction_range(opt_j), ...
    'r*', 'MarkerSize', 15, 'LineWidth', 2);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: Std Delay
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 2);
imagesc(ema_alpha_range, max_reduction_range, std_delay');
colorbar;
colormap(cmap);
set(gca, 'YDir', 'normal');
xlabel('EMA \alpha', 'FontSize', 11);
ylabel('Max Reduction', 'FontSize', 11);
title('Delay Std Dev [ms]', 'FontSize', 13, 'FontWeight', 'bold');

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: Collision Rate
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 3);
imagesc(ema_alpha_range, max_reduction_range, mean_collision' * 100);
colorbar;
colormap(cmap);
set(gca, 'YDir', 'normal');
xlabel('EMA \alpha', 'FontSize', 11);
ylabel('Max Reduction', 'FontSize', 11);
title('Collision Rate [%]', 'FontSize', 13, 'FontWeight', 'bold');

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: Explicit BSR Count
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 4);
imagesc(ema_alpha_range, max_reduction_range, mean_explicit_bsr');
colorbar;
colormap(cmap);
set(gca, 'YDir', 'normal');
xlabel('EMA \alpha', 'FontSize', 11);
ylabel('Max Reduction', 'FontSize', 11);
title('Explicit BSR Count', 'FontSize', 13, 'FontWeight', 'bold');

% ─────────────────────────────────────────────────────────────────────
% Subplot 5: Buffer Empty Ratio
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 5);
imagesc(ema_alpha_range, max_reduction_range, mean_buffer_empty' * 100);
colorbar;
colormap(cmap);
set(gca, 'YDir', 'normal');
xlabel('EMA \alpha', 'FontSize', 11);
ylabel('Max Reduction', 'FontSize', 11);
title('Buffer Empty Ratio [%]', 'FontSize', 13, 'FontWeight', 'bold');

% ─────────────────────────────────────────────────────────────────────
% Subplot 6: Completion Rate
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 6);
imagesc(ema_alpha_range, max_reduction_range, mean_completion' * 100);
colorbar;
colormap(cmap);
set(gca, 'YDir', 'normal');
xlabel('EMA \alpha', 'FontSize', 11);
ylabel('Max Reduction', 'FontSize', 11);
title('Completion Rate [%]', 'FontSize', 13, 'FontWeight', 'bold');

sgtitle('Exp 2-4: Scheme 3 (EMA-based) 파라미터 최적화', ...
    'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  4. 최적 파라미터 도출
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  최적 파라미터\n');
fprintf('========================================\n\n');

% 최소 지연 기준
[min_delay, min_idx] = min(mean_delay(:));
[opt_i, opt_j] = ind2sub(size(mean_delay), min_idx);

fprintf('[최적 조합 (Mean Delay 기준)]\n');
fprintf('  EMA_alpha: %.2f\n', ema_alpha_range(opt_i));
fprintf('  max_reduction: %.1f\n', max_reduction_range(opt_j));
fprintf('  평균 지연: %.2f ms (±%.2f ms)\n', ...
    min_delay, std_delay(opt_i, opt_j));
fprintf('  충돌률: %.1f%%\n', mean_collision(opt_i, opt_j) * 100);
fprintf('  Explicit BSR: %.0f회\n', mean_explicit_bsr(opt_i, opt_j));
fprintf('  Buffer Empty: %.1f%%\n', mean_buffer_empty(opt_i, opt_j) * 100);
fprintf('  완료율: %.1f%%\n', mean_completion(opt_i, opt_j) * 100);

if has_baseline
    improvement = (1 - min_delay / baseline_delay) * 100;
    fprintf('\n  Baseline: %.2f ms\n', baseline_delay);
    fprintf('  개선률: %.1f%%\n', improvement);
end

%% =====================================================================
%  5. 통계 테이블 출력
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  상세 통계 (전체 조합)\n');
fprintf('========================================\n\n');

fprintf('%-10s | %-12s | %10s | %10s | %10s | %12s\n', ...
    'EMA_alpha', 'max_reduc', 'Delay[ms]', 'Coll[%]', 'Exp_BSR', 'BufEmpty[%]');
fprintf('%s\n', repmat('-', 1, 85));

for i = 1:n_alpha
    for j = 1:n_max
        fprintf('%-10.2f | %-12.1f | %10.2f | %10.1f | %10.0f | %12.1f', ...
            ema_alpha_range(i), ...
            max_reduction_range(j), ...
            mean_delay(i, j), ...
            mean_collision(i, j) * 100, ...
            mean_explicit_bsr(i, j), ...
            mean_buffer_empty(i, j) * 100);
        
        % 최적점 표시
        if i == opt_i && j == opt_j
            fprintf('  ⭐ 최적');
        end
        
        fprintf('\n');
    end
end

%% =====================================================================
%  6. EMA_alpha 영향 분석
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  EMA_alpha 영향 분석\n');
fprintf('========================================\n\n');

fprintf('EMA_alpha가 작을수록: 장기 추세 (느린 반응)\n');
fprintf('EMA_alpha가 클수록: 단기 변동 (빠른 반응)\n\n');

% max_reduction 고정 (중간값) 후 EMA_alpha 변화 관찰
mid_j = ceil(n_max / 2);

fprintf('[max_reduction=%.1f 고정 시]\n', max_reduction_range(mid_j));
fprintf('%-10s | %10s | %10s | %10s\n', ...
    'EMA_alpha', 'Delay[ms]', 'Coll[%]', 'Exp_BSR');
fprintf('%s\n', repmat('-', 1, 50));

for i = 1:n_alpha
    fprintf('%-10.2f | %10.2f | %10.1f | %10.0f\n', ...
        ema_alpha_range(i), ...
        mean_delay(i, mid_j), ...
        mean_collision(i, mid_j) * 100, ...
        mean_explicit_bsr(i, mid_j));
end

%% =====================================================================
%  7. max_reduction 영향 분석
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  max_reduction 영향 분석\n');
fprintf('========================================\n\n');

% EMA_alpha 고정 (최적값) 후 max_reduction 변화 관찰
fprintf('[EMA_alpha=%.2f 고정 시]\n', ema_alpha_range(opt_i));
fprintf('%-12s | %10s | %10s | %10s\n', ...
    'max_reduc', 'Delay[ms]', 'Coll[%]', 'Exp_BSR');
fprintf('%s\n', repmat('-', 1, 50));

for j = 1:n_max
    fprintf('%-12.1f | %10.2f | %10.1f | %10.0f\n', ...
        max_reduction_range(j), ...
        mean_delay(opt_i, j), ...
        mean_collision(opt_i, j) * 100, ...
        mean_explicit_bsr(opt_i, j));
end

%% =====================================================================
%  8. Line Plot 추가 (경향 분석)
%  =====================================================================

fprintf('\n[추가 시각화 생성 중...]\n');

fig2 = figure('Position', [200, 200, 1400, 500]);

% Subplot 1: EMA_alpha 고정, max_reduction 변화
subplot(1, 2, 1);
hold on;
for i = 1:n_alpha
    plot(max_reduction_range, mean_delay(i, :), '-o', ...
        'LineWidth', 2, 'MarkerSize', 8, ...
        'DisplayName', sprintf('\\alpha=%.2f', ema_alpha_range(i)));
end
hold off;
xlabel('Max Reduction', 'FontSize', 11);
ylabel('Mean Delay [ms]', 'FontSize', 11);
title('Max Reduction 영향 (EMA_alpha별)', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best');
grid on;

% Subplot 2: max_reduction 고정, EMA_alpha 변화
subplot(1, 2, 2);
hold on;
for j = 1:n_max
    plot(ema_alpha_range, mean_delay(:, j), '-s', ...
        'LineWidth', 2, 'MarkerSize', 8, ...
        'DisplayName', sprintf('max\\_reduc=%.1f', max_reduction_range(j)));
end
hold off;
xlabel('EMA \alpha', 'FontSize', 11);
ylabel('Mean Delay [ms]', 'FontSize', 11);
title('EMA_alpha 영향 (max_reduction별)', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best');
grid on;

sgtitle('Exp 2-4: 파라미터 경향 분석', 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  9. 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

% Figure 1 저장
fig1_filename = sprintf('%s/exp2_4_scheme3_optimization.png', fig_dir);
saveas(fig, fig1_filename);
exportgraphics(fig, [fig1_filename(1:end-3), 'pdf'], 'ContentType', 'vector');
fprintf('\n  ✓ Figure 1 저장: %s\n', fig1_filename);

% Figure 2 저장
fig2_filename = sprintf('%s/exp2_4_scheme3_optimization_trends.png', fig_dir);
saveas(fig2, fig2_filename);
exportgraphics(fig2, [fig2_filename(1:end-3), 'pdf'], 'ContentType', 'vector');
fprintf('  ✓ Figure 2 저장: %s\n', fig2_filename);

%% =====================================================================
%  10. 권장사항 출력
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  권장사항\n');
fprintf('========================================\n\n');

fprintf('✅ 최적 파라미터:\n');
fprintf('   - EMA_alpha = %.2f\n', ema_alpha_range(opt_i));
fprintf('   - max_reduction = %.1f\n', max_reduction_range(opt_j));
fprintf('\n');

fprintf('📊 특성:\n');
if ema_alpha_range(opt_i) < 0.3
    fprintf('   - 낮은 alpha → 장기 추세 기반, 안정적\n');
else
    fprintf('   - 높은 alpha → 단기 변동 민감, 반응적\n');
end

if max_reduction_range(opt_j) < 0.5
    fprintf('   - 보수적 감소 → 안전성 우선\n');
else
    fprintf('   - 적극적 감소 → 효율성 우선\n');
end

fprintf('\n💡 다음 단계:\n');
fprintf('   1. Exp 2-1의 Scheme 3 파라미터를 최적값으로 업데이트\n');
fprintf('   2. 다양한 부하(Low/Mid/High)에서 robustness 검증\n');
fprintf('   3. Scheme 1, 2와 성능 비교\n');

fprintf('\n🎉 분석 완료!\n\n');