%% analyze_bsr_trace.m
% BSR trace 분석 및 시각화
%
% v3의 "안정화" 효과 검증:
% - BSR variance 비교
% - BSR distribution 비교
% - Time series 비교

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  BSR Trace 분석\n');
fprintf('========================================\n\n');

%% 1. 결과 로드

load_file = 'bsr_trace_results.mat';
if ~exist(load_file, 'file')
    error('결과 파일 없음: %s\n먼저 bsr_trace_test.m을 실행하세요!', load_file);
end

fprintf('결과 로드: %s\n\n', load_file);
load(load_file);

%% 2. BSR Trace 추출

fprintf('========================================\n');
fprintf('  BSR Trace 추출 중...\n');
fprintf('========================================\n\n');

% Baseline trace
if ~isfield(results.baseline, 'bsr_trace') || isempty(results.baseline.bsr_trace)
    error('Baseline BSR trace 없음!');
end

% v3 trace
if ~isfield(results.v3, 'bsr_trace') || isempty(results.v3.bsr_trace)
    error('v3 BSR trace 없음!');
end

trace_base = results.baseline.bsr_trace;
trace_v3 = results.v3.bsr_trace;

fprintf('Baseline trace: %d entries\n', length(trace_base));
fprintf('v3 trace: %d entries\n\n', length(trace_v3));

% Trace 구조 확인
fprintf('Trace 구조:\n');
fprintf('  Fields: %s\n\n', strjoin(fieldnames(trace_base), ', '));

%% 3. BSR Value 추출 및 통계

fprintf('========================================\n');
fprintf('  통계 계산 중...\n');
fprintf('========================================\n\n');

% BSR value 추출 (모든 station의 모든 BSR)
bsr_vals_base = [];
bsr_vals_v3 = [];

for i = 1:length(trace_base)
    if isfield(trace_base(i), 'bsr_value')
        bsr_vals_base = [bsr_vals_base; trace_base(i).bsr_value];
    end
end

for i = 1:length(trace_v3)
    if isfield(trace_v3(i), 'bsr_value')
        bsr_vals_v3 = [bsr_vals_v3; trace_v3(i).bsr_value];
    end
end

% 통계 계산
stats_base.mean = mean(bsr_vals_base);
stats_base.std = std(bsr_vals_base);
stats_base.var = var(bsr_vals_base);
stats_base.cv = stats_base.std / stats_base.mean;  % Coefficient of variation
stats_base.min = min(bsr_vals_base);
stats_base.max = max(bsr_vals_base);
stats_base.median = median(bsr_vals_base);

stats_v3.mean = mean(bsr_vals_v3);
stats_v3.std = std(bsr_vals_v3);
stats_v3.var = var(bsr_vals_v3);
stats_v3.cv = stats_v3.std / stats_v3.mean;
stats_v3.min = min(bsr_vals_v3);
stats_v3.max = max(bsr_vals_v3);
stats_v3.median = median(bsr_vals_v3);

% BSR change magnitude (연속된 BSR 값 차이)
bsr_change_base = abs(diff(bsr_vals_base));
bsr_change_v3 = abs(diff(bsr_vals_v3));

stats_base.change_mean = mean(bsr_change_base);
stats_base.change_std = std(bsr_change_base);
stats_v3.change_mean = mean(bsr_change_v3);
stats_v3.change_std = std(bsr_change_v3);

% 출력
fprintf('%-20s | %-15s %-15s %-15s\n', 'Metric', 'Baseline', 'v3', 'Change');
fprintf('%s\n', repmat('-', 1, 70));

fprintf('%-20s | %15.2f %15.2f %15.2f%%\n', 'Mean BSR', ...
    stats_base.mean, stats_v3.mean, (stats_v3.mean - stats_base.mean)/stats_base.mean*100);
fprintf('%-20s | %15.2f %15.2f %15.2f%%\n', 'Std BSR', ...
    stats_base.std, stats_v3.std, (stats_v3.std - stats_base.std)/stats_base.std*100);
fprintf('%-20s | %15.2f %15.2f %15.2f%%\n', 'Variance BSR', ...
    stats_base.var, stats_v3.var, (stats_v3.var - stats_base.var)/stats_base.var*100);
fprintf('%-20s | %15.4f %15.4f %15.2f%%\n', 'CV (Std/Mean)', ...
    stats_base.cv, stats_v3.cv, (stats_v3.cv - stats_base.cv)/stats_base.cv*100);
fprintf('%-20s | %15.2f %15.2f %15s\n', 'Median BSR', ...
    stats_base.median, stats_v3.median, '-');
fprintf('%-20s | %15.2f %15.2f %15s\n', 'Min BSR', ...
    stats_base.min, stats_v3.min, '-');
fprintf('%-20s | %15.2f %15.2f %15s\n', 'Max BSR', ...
    stats_base.max, stats_v3.max, '-');
fprintf('\n');
fprintf('%-20s | %15.2f %15.2f %15.2f%%\n', 'Mean |ΔBSR|', ...
    stats_base.change_mean, stats_v3.change_mean, ...
    (stats_v3.change_mean - stats_base.change_mean)/stats_base.change_mean*100);
fprintf('%-20s | %15.2f %15.2f %15.2f%%\n', 'Std |ΔBSR|', ...
    stats_base.change_std, stats_v3.change_std, ...
    (stats_v3.change_std - stats_base.change_std)/stats_base.change_std*100);

fprintf('\n');

%% 4. 시각화

fprintf('========================================\n');
fprintf('  시각화 생성 중...\n');
fprintf('========================================\n\n');

%% 4-1. Time Series

figure('Position', [100, 100, 1600, 800]);

subplot(2, 1, 1);
plot(1:length(bsr_vals_base), bsr_vals_base, '-', 'LineWidth', 1);
xlabel('BSR Event Index');
ylabel('BSR Value');
title(sprintf('Baseline BSR Time Series (Mean=%.1f, Std=%.1f, CV=%.3f)', ...
    stats_base.mean, stats_base.std, stats_base.cv));
grid on;
xlim([1, min(1000, length(bsr_vals_base))]);  % 처음 1000개만

subplot(2, 1, 2);
plot(1:length(bsr_vals_v3), bsr_vals_v3, '-', 'LineWidth', 1);
xlabel('BSR Event Index');
ylabel('BSR Value');
title(sprintf('v3 BSR Time Series (Mean=%.1f, Std=%.1f, CV=%.3f)', ...
    stats_v3.mean, stats_v3.std, stats_v3.cv));
grid on;
xlim([1, min(1000, length(bsr_vals_v3))]);  % 처음 1000개만

sgtitle('BSR Time Series: Baseline vs v3', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'bsr_timeseries.png');
fprintf('저장: bsr_timeseries.png\n');

%% 4-2. Distribution (Histogram)

figure('Position', [100, 100, 1400, 600]);

subplot(1, 2, 1);
histogram(bsr_vals_base, 50, 'Normalization', 'probability', 'FaceAlpha', 0.7, 'DisplayName', 'Baseline');
hold on;
histogram(bsr_vals_v3, 50, 'Normalization', 'probability', 'FaceAlpha', 0.7, 'DisplayName', 'v3');
hold off;
xlabel('BSR Value');
ylabel('Probability');
title('BSR Distribution');
legend('Location', 'best');
grid on;

subplot(1, 2, 2);
histogram(bsr_change_base, 50, 'Normalization', 'probability', 'FaceAlpha', 0.7, 'DisplayName', 'Baseline');
hold on;
histogram(bsr_change_v3, 50, 'Normalization', 'probability', 'FaceAlpha', 0.7, 'DisplayName', 'v3');
hold off;
xlabel('|BSR Change|');
ylabel('Probability');
title('BSR Change Magnitude Distribution');
legend('Location', 'best');
grid on;

sgtitle('BSR Distribution: Baseline vs v3', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'bsr_distribution.png');
fprintf('저장: bsr_distribution.png\n');

%% 4-3. Statistics Comparison

figure('Position', [100, 100, 1400, 600]);

% Variance comparison
subplot(1, 3, 1);
bar([1, 2], [stats_base.var, stats_v3.var]);
set(gca, 'XTickLabel', {'Baseline', 'v3'});
ylabel('BSR Variance');
title('BSR Variance Comparison');
grid on;
% Add values on bars
text(1, stats_base.var, sprintf('%.1f', stats_base.var), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);
text(2, stats_v3.var, sprintf('%.1f', stats_v3.var), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);

% Std comparison
subplot(1, 3, 2);
bar([1, 2], [stats_base.std, stats_v3.std]);
set(gca, 'XTickLabel', {'Baseline', 'v3'});
ylabel('BSR Standard Deviation');
title('BSR Std Comparison');
grid on;
text(1, stats_base.std, sprintf('%.1f', stats_base.std), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);
text(2, stats_v3.std, sprintf('%.1f', stats_v3.std), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);

% CV comparison
subplot(1, 3, 3);
bar([1, 2], [stats_base.cv, stats_v3.cv]);
set(gca, 'XTickLabel', {'Baseline', 'v3'});
ylabel('Coefficient of Variation (CV)');
title('BSR CV Comparison');
grid on;
text(1, stats_base.cv, sprintf('%.3f', stats_base.cv), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);
text(2, stats_v3.cv, sprintf('%.3f', stats_v3.cv), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);

sgtitle('BSR Variability: Baseline vs v3', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'bsr_variability.png');
fprintf('저장: bsr_variability.png\n');

%% 4-4. BSR Change Magnitude

figure('Position', [100, 100, 1400, 600]);

subplot(1, 2, 1);
bar([1, 2], [stats_base.change_mean, stats_v3.change_mean]);
set(gca, 'XTickLabel', {'Baseline', 'v3'});
ylabel('Mean |BSR Change|');
title('Mean BSR Change Magnitude');
grid on;
text(1, stats_base.change_mean, sprintf('%.1f', stats_base.change_mean), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);
text(2, stats_v3.change_mean, sprintf('%.1f', stats_v3.change_mean), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);

subplot(1, 2, 2);
bar([1, 2], [stats_base.change_std, stats_v3.change_std]);
set(gca, 'XTickLabel', {'Baseline', 'v3'});
ylabel('Std of |BSR Change|');
title('Std of BSR Change Magnitude');
grid on;
text(1, stats_base.change_std, sprintf('%.1f', stats_base.change_std), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);
text(2, stats_v3.change_std, sprintf('%.1f', stats_v3.change_std), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);

sgtitle('BSR Change Magnitude: Baseline vs v3', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'bsr_change.png');
fprintf('저장: bsr_change.png\n');

fprintf('\n');

%% 5. 결론

fprintf('========================================\n');
fprintf('  종합 결론\n');
fprintf('========================================\n\n');

% Variance reduction
var_reduction = (stats_base.var - stats_v3.var) / stats_base.var * 100;
std_reduction = (stats_base.std - stats_v3.std) / stats_base.std * 100;
cv_reduction = (stats_base.cv - stats_v3.cv) / stats_base.cv * 100;
change_reduction = (stats_base.change_mean - stats_v3.change_mean) / stats_base.change_mean * 100;

fprintf('v3의 "안정화" 효과:\n');

if var_reduction > 5
    var_mark = '✅';
elseif var_reduction > 0
    var_mark = '⚠️';
else
    var_mark = '❌';
end

if std_reduction > 5
    std_mark = '✅';
elseif std_reduction > 0
    std_mark = '⚠️';
else
    std_mark = '❌';
end

if cv_reduction > 5
    cv_mark = '✅';
elseif cv_reduction > 0
    cv_mark = '⚠️';
else
    cv_mark = '❌';
end

if change_reduction > 5
    change_mark = '✅';
elseif change_reduction > 0
    change_mark = '⚠️';
else
    change_mark = '❌';
end

fprintf('  BSR Variance: %.2f%% 감소 %s\n', var_reduction, var_mark);
fprintf('  BSR Std: %.2f%% 감소 %s\n', std_reduction, std_mark);
fprintf('  CV: %.2f%% 감소 %s\n', cv_reduction, cv_mark);
fprintf('  Mean |ΔBSR|: %.2f%% 감소 %s\n', change_reduction, change_mark);
fprintf('\n');

% Mean comparison
mean_change = (stats_v3.mean - stats_base.mean) / stats_base.mean * 100;
fprintf('BSR 평균 변화: %.2f%%\n', mean_change);
fprintf('\n');

% 가설 검증
fprintf('가설 검증:\n');
if abs(mean_change) < 5 && var_reduction > 10
    fprintf('✅ v3는 BSR 평균을 유지하면서 변동성을 줄임!\n');
    fprintf('   → BSR "안정화" 가설 성립!\n');
elseif abs(mean_change) > 10
    fprintf('⚠️  v3가 BSR 평균도 크게 바꿈 (%.1f%%)\n', mean_change);
    fprintf('   → BSR "감소" 효과도 있음\n');
else
    fprintf('❌ v3의 안정화 효과 미미\n');
    fprintf('   → 다른 메커니즘?\n');
end

fprintf('\n');

% Performance vs Variability
fprintf('성능 개선 vs 변동성 감소:\n');
fprintf('  Delay 개선: %.2f%%\n', ...
    (results.baseline.summary.mean_delay_ms - results.v3.summary.mean_delay_ms) / ...
    results.baseline.summary.mean_delay_ms * 100);
fprintf('  Variance 감소: %.2f%%\n', var_reduction);
fprintf('  Collision 개선: %.2f%%\n', ...
    (results.baseline.uora.collision_rate - results.v3.uora.collision_rate) / ...
    results.baseline.uora.collision_rate * 100);

fprintf('\n========================================\n\n');