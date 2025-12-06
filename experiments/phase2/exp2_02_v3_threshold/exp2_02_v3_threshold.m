%% exp2_02_v3_threshold.m
% Experiment 2-02: v3 Threshold 2D 스윕
%
% 목적:
%   reduction_threshold × burst_threshold 조합이 v3 성능에 미치는 영향 확인
%   → 핵심 파라미터 스윕 전 적절한 threshold 조합 결정
%
% 구조:
%   reduction_threshold(4) × burst_threshold(3) × scheme(2) × runs(10) = 240회
%
% 패킷 크기 = 2000 bytes 기준:
%   - reduction_threshold: [2000, 4000, 6000, 8000] (패킷 1~4개 수준)
%   - burst_threshold: [4000, 6000, 8000] (패킷 2~4개 급증)
%
% 예상 소요 시간: ~12분

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

exp_config = get_exp2_02_config();

%% =====================================================================
%  2. 실험 실행
%  =====================================================================

results = run_exp2_02(exp_config);

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
n_red = length(exp_config.sweep_range);
n_burst = length(exp_config.sweep_range2);
n_schemes = length(exp_config.schemes);
n_rows = n_red * n_burst * n_schemes;

T = table();
red_col = zeros(n_rows, 1);
burst_col = zeros(n_rows, 1);
scheme_col = cell(n_rows, 1);

row_idx = 0;
for r = 1:n_red
    for b = 1:n_burst
        for sc = 1:n_schemes
            row_idx = row_idx + 1;
            red_col(row_idx) = exp_config.sweep_range(r);
            burst_col(row_idx) = exp_config.sweep_range2(b);
            scheme_col{row_idx} = exp_config.scheme_names{sc};
        end
    end
end

T.reduction_threshold = red_col;
T.burst_threshold = burst_col;
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
%  4. 핵심 결과 분석: v3 개선률 Heatmap
%  =====================================================================

fprintf('========================================\n');
fprintf('  v3 개선률 (Baseline 대비)\n');
fprintf('========================================\n\n');

mean_delay = results.summary.mean.mean_delay_ms;  % [red, burst, scheme]
std_delay_metric = results.summary.mean.std_delay_ms;
mean_uora = results.summary.mean.mean_uora_delay_ms;
mean_explicit = results.summary.mean.explicit_bsr_count;

red_vals = exp_config.sweep_range;
burst_vals = exp_config.sweep_range2;

% 개선률 계산: [red, burst]
delay_improvement = zeros(n_red, n_burst);
std_improvement = zeros(n_red, n_burst);
uora_improvement = zeros(n_red, n_burst);

for r = 1:n_red
    for b = 1:n_burst
        % Baseline (scheme=1) vs v3 (scheme=2)
        baseline_delay = mean_delay(r, b, 1);
        v3_delay = mean_delay(r, b, 2);
        delay_improvement(r, b) = (1 - v3_delay / baseline_delay) * 100;
        
        baseline_std = std_delay_metric(r, b, 1);
        v3_std = std_delay_metric(r, b, 2);
        std_improvement(r, b) = (1 - v3_std / baseline_std) * 100;
        
        baseline_uora = mean_uora(r, b, 1);
        v3_uora = mean_uora(r, b, 2);
        uora_improvement(r, b) = (1 - v3_uora / baseline_uora) * 100;
    end
end

% 테이블 출력
fprintf('지연 개선률 [%%] (행: reduction_thresh, 열: burst_thresh)\n');
fprintf('%12s |', '');
for b = 1:n_burst
    fprintf(' %8d', burst_vals(b));
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 12 + n_burst * 9));

for r = 1:n_red
    fprintf('%12d |', red_vals(r));
    for b = 1:n_burst
        fprintf(' %+7.1f%%', delay_improvement(r, b));
    end
    fprintf('\n');
end

%% =====================================================================
%  5. 최적 조합 찾기
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  최적 Threshold 조합\n');
fprintf('========================================\n\n');

[best_impr, best_idx] = max(delay_improvement(:));
[best_r, best_b] = ind2sub([n_red, n_burst], best_idx);

fprintf('[최적 조합]\n');
fprintf('  reduction_threshold: %d bytes\n', red_vals(best_r));
fprintf('  burst_threshold: %d bytes\n', burst_vals(best_b));
fprintf('  지연 개선률: %.1f%%\n', best_impr);
fprintf('  분산 개선률: %.1f%%\n', std_improvement(best_r, best_b));
fprintf('  T_uora 개선률: %.1f%%\n', uora_improvement(best_r, best_b));

% 절대 지연 값 출력
fprintf('\n[절대 지연 값]\n');
fprintf('  Baseline: %.2f ms\n', mean_delay(best_r, best_b, 1));
fprintf('  v3:       %.2f ms\n', mean_delay(best_r, best_b, 2));

%% =====================================================================
%  6. 시각화
%  =====================================================================

fprintf('\n[시각화 생성]\n');

fig = figure('Position', [100, 100, 1200, 900], 'Visible', 'on');

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: 지연 개선률 Heatmap
% ─────────────────────────────────────────────────────────────────────
subplot(2, 2, 1);
imagesc(delay_improvement);
colorbar;
colormap(subplot(2,2,1), flipud(hot));  % 높은 개선률 = 밝은 색
caxis([min(delay_improvement(:))-1, max(delay_improvement(:))+1]);

set(gca, 'XTick', 1:n_burst, 'XTickLabel', arrayfun(@num2str, burst_vals, 'UniformOutput', false));
set(gca, 'YTick', 1:n_red, 'YTickLabel', arrayfun(@num2str, red_vals, 'UniformOutput', false));
xlabel('burst\_threshold [bytes]');
ylabel('reduction\_threshold [bytes]');
title('지연 개선률 [%]');

% 값 표시
for r = 1:n_red
    for b = 1:n_burst
        text(b, r, sprintf('%.1f', delay_improvement(r, b)), ...
            'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
    end
end

% 최적점 표시
hold on;
plot(best_b, best_r, 'go', 'MarkerSize', 20, 'LineWidth', 3);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: 분산 개선률 Heatmap
% ─────────────────────────────────────────────────────────────────────
subplot(2, 2, 2);
imagesc(std_improvement);
colorbar;
colormap(subplot(2,2,2), flipud(hot));

set(gca, 'XTick', 1:n_burst, 'XTickLabel', arrayfun(@num2str, burst_vals, 'UniformOutput', false));
set(gca, 'YTick', 1:n_red, 'YTickLabel', arrayfun(@num2str, red_vals, 'UniformOutput', false));
xlabel('burst\_threshold [bytes]');
ylabel('reduction\_threshold [bytes]');
title('지연 분산 개선률 [%]');

for r = 1:n_red
    for b = 1:n_burst
        text(b, r, sprintf('%.1f', std_improvement(r, b)), ...
            'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
    end
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: T_uora 개선률 Heatmap
% ─────────────────────────────────────────────────────────────────────
subplot(2, 2, 3);
imagesc(uora_improvement);
colorbar;
colormap(subplot(2,2,3), flipud(hot));

set(gca, 'XTick', 1:n_burst, 'XTickLabel', arrayfun(@num2str, burst_vals, 'UniformOutput', false));
set(gca, 'YTick', 1:n_red, 'YTickLabel', arrayfun(@num2str, red_vals, 'UniformOutput', false));
xlabel('burst\_threshold [bytes]');
ylabel('reduction\_threshold [bytes]');
title('T_{uora} 개선률 [%]');

for r = 1:n_red
    for b = 1:n_burst
        text(b, r, sprintf('%.1f', uora_improvement(r, b)), ...
            'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
    end
end

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: 절대 지연 비교 (Line plot)
% ─────────────────────────────────────────────────────────────────────
subplot(2, 2, 4);
hold on;

colors = lines(n_burst);
markers = {'o', 's', '^'};

for b = 1:n_burst
    % Baseline
    baseline_vals = squeeze(mean_delay(:, b, 1));
    plot(red_vals, baseline_vals, '--', 'Color', colors(b, :), 'LineWidth', 1.5);
    
    % v3
    v3_vals = squeeze(mean_delay(:, b, 2));
    plot(red_vals, v3_vals, '-', 'Color', colors(b, :), ...
        'Marker', markers{b}, 'MarkerFaceColor', colors(b, :), ...
        'MarkerSize', 8, 'LineWidth', 2);
end
hold off;

xlabel('reduction\_threshold [bytes]');
ylabel('Mean Delay [ms]');
title('절대 지연 (점선=Baseline, 실선=v3)');
legend_entries = {};
for b = 1:n_burst
    legend_entries{end+1} = sprintf('burst=%d (B)', burst_vals(b));
    legend_entries{end+1} = sprintf('burst=%d (v3)', burst_vals(b));
end
legend(legend_entries, 'Location', 'best', 'FontSize', 8);
grid on;

sgtitle(sprintf('Exp 2-02: v3 Threshold 2D 스윕 (Low: L_{cell}=%.2f)', ...
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
%  7. 결론 및 권장 사항
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  결론 및 권장 사항\n');
fprintf('========================================\n\n');

fprintf('[권장 threshold 조합]\n');
fprintf('  reduction_threshold: %d bytes\n', red_vals(best_r));
fprintf('  burst_threshold: %d bytes\n', burst_vals(best_b));
fprintf('\n');

fprintf('→ 이 값들을 Exp 2-03 (핵심 파라미터 스윕)에서 사용\n');
fprintf('→ 다음 단계: exp2_03_v3_optimization.m 실행\n');
fprintf('   - v3_EMA_alpha × v3_max_reduction 스윕\n\n');

fprintf('🎉 Experiment 2-02 완료!\n\n');