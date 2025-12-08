%% analyze_indirect_evidence.m
% BSR trace 없이 간접 증거로 v3의 "안정화" 효과 분석
%
% 주요 지표:
% 1. UORA delay std (variance의 증거)
% 2. Packet delay distribution
% 3. 기타 variability 지표

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  간접 증거 분석\n');
fprintf('  (BSR Stabilization Effect)\n');
fprintf('========================================\n\n');

%% 1. 결과 로드

load('bsr_trace_results.mat');

%% 2. UORA Delay 통계 추출

fprintf('========================================\n');
fprintf('  UORA Delay 통계 (10 runs)\n');
fprintf('========================================\n\n');

% Baseline - 각 run 추출
num_runs = length(results.baseline);
base_uora_mean_runs = zeros(num_runs, 1);
base_uora_std_runs = zeros(num_runs, 1);
base_uora_median_runs = zeros(num_runs, 1);
base_uora_p90_runs = zeros(num_runs, 1);

for i = 1:num_runs
    base_uora_mean_runs(i) = results.baseline{i}.bsr.mean_uora_delay * 1000;
    base_uora_std_runs(i) = results.baseline{i}.bsr.std_uora_delay * 1000;
    base_uora_median_runs(i) = results.baseline{i}.bsr.median_uora_delay * 1000;
    base_uora_p90_runs(i) = results.baseline{i}.bsr.p90_uora_delay * 1000;
end

% v3 - 각 run 추출
v3_uora_mean_runs = zeros(num_runs, 1);
v3_uora_std_runs = zeros(num_runs, 1);
v3_uora_median_runs = zeros(num_runs, 1);
v3_uora_p90_runs = zeros(num_runs, 1);

for i = 1:num_runs
    v3_uora_mean_runs(i) = results.v3{i}.bsr.mean_uora_delay * 1000;
    v3_uora_std_runs(i) = results.v3{i}.bsr.std_uora_delay * 1000;
    v3_uora_median_runs(i) = results.v3{i}.bsr.median_uora_delay * 1000;
    v3_uora_p90_runs(i) = results.v3{i}.bsr.p90_uora_delay * 1000;
end

% 평균 및 표준오차
base_uora_mean = mean(base_uora_mean_runs);
base_uora_mean_se = std(base_uora_mean_runs) / sqrt(num_runs);
base_uora_std = mean(base_uora_std_runs);
base_uora_std_se = std(base_uora_std_runs) / sqrt(num_runs);
base_uora_median = mean(base_uora_median_runs);
base_uora_p90 = mean(base_uora_p90_runs);
base_uora_cv = base_uora_std / base_uora_mean;

v3_uora_mean = mean(v3_uora_mean_runs);
v3_uora_mean_se = std(v3_uora_mean_runs) / sqrt(num_runs);
v3_uora_std = mean(v3_uora_std_runs);
v3_uora_std_se = std(v3_uora_std_runs) / sqrt(num_runs);
v3_uora_median = mean(v3_uora_median_runs);
v3_uora_p90 = mean(v3_uora_p90_runs);
v3_uora_cv = v3_uora_std / v3_uora_mean;

fprintf('%-20s | %-15s %-15s %-15s\n', 'Metric', 'Baseline', 'v3', 'Change');
fprintf('%s\n', repmat('-', 1, 70));

fprintf('%-20s | %15.2f %15.2f %15.2f%%\n', 'Mean UORA [ms]', ...
    base_uora_mean, v3_uora_mean, (v3_uora_mean - base_uora_mean)/base_uora_mean*100);
fprintf('%-20s | %15.2f %15.2f %15.2f%%\n', 'Std UORA [ms]', ...
    base_uora_std, v3_uora_std, (v3_uora_std - base_uora_std)/base_uora_std*100);
fprintf('%-20s | %15.4f %15.4f %15.2f%%\n', 'CV (Std/Mean)', ...
    base_uora_cv, v3_uora_cv, (v3_uora_cv - base_uora_cv)/base_uora_cv*100);
fprintf('%-20s | %15.2f %15.2f %15.2f%%\n', 'Median UORA [ms]', ...
    base_uora_median, v3_uora_median, (v3_uora_median - base_uora_median)/base_uora_median*100);
fprintf('%-20s | %15.2f %15.2f %15.2f%%\n', 'P90 UORA [ms]', ...
    base_uora_p90, v3_uora_p90, (v3_uora_p90 - base_uora_p90)/base_uora_p90*100);

fprintf('\n');
fprintf('Standard Error:\n');
fprintf('  Baseline Mean SE: %.2f ms\n', base_uora_mean_se);
fprintf('  v3 Mean SE: %.2f ms\n', v3_uora_mean_se);
fprintf('  Baseline Std SE: %.2f ms\n', base_uora_std_se);
fprintf('  v3 Std SE: %.2f ms\n', v3_uora_std_se);

fprintf('\n');

%% 3. Statistical Significance Test

fprintf('========================================\n');
fprintf('  Statistical Significance Test\n');
fprintf('========================================\n\n');

% Manual paired t-test implementation
% UORA Std
diff_uora_std = base_uora_std_runs - v3_uora_std_runs;
mean_diff_std = mean(diff_uora_std);
std_diff_std = std(diff_uora_std);
se_diff_std = std_diff_std / sqrt(num_runs);
t_stat_std = mean_diff_std / se_diff_std;
df = num_runs - 1;

% p-value approximation (two-tailed)
% For df=9: critical values approximately ±2.262 (p=0.05), ±3.250 (p=0.01)
if abs(t_stat_std) > 3.250
    p_std = 0.01;
    p_std_str = '< 0.01';
elseif abs(t_stat_std) > 2.821
    p_std = 0.02;
    p_std_str = '< 0.02';
elseif abs(t_stat_std) > 2.262
    p_std = 0.05;
    p_std_str = '< 0.05';
elseif abs(t_stat_std) > 1.833
    p_std = 0.10;
    p_std_str = '< 0.10';
else
    p_std = 0.20;
    p_std_str = '> 0.10';
end

fprintf('UORA Std paired t-test:\n');
fprintf('  Baseline: %.2f ± %.2f ms\n', mean(base_uora_std_runs), std(base_uora_std_runs));
fprintf('  v3:       %.2f ± %.2f ms\n', mean(v3_uora_std_runs), std(v3_uora_std_runs));
fprintf('  Difference: %.2f ± %.2f ms\n', mean_diff_std, std_diff_std);
fprintf('  t-statistic: %.3f (df=%d)\n', t_stat_std, df);
fprintf('  p-value: %s\n', p_std_str);

if abs(t_stat_std) > 3.250
    fprintf('  Result: ✅ 매우 유의함 (p < 0.01)\n');
elseif abs(t_stat_std) > 2.262
    fprintf('  Result: ✅ 유의함 (p < 0.05)\n');
elseif abs(t_stat_std) > 1.833
    fprintf('  Result: ⚠️  약간 유의함 (p < 0.10)\n');
else
    fprintf('  Result: ❌ 유의하지 않음 (p > 0.10)\n');
end
fprintf('\n');

% Mean delay
base_delay_runs = zeros(num_runs, 1);
v3_delay_runs = zeros(num_runs, 1);
for i = 1:num_runs
    base_delay_runs(i) = results.baseline{i}.summary.mean_delay_ms;
    v3_delay_runs(i) = results.v3{i}.summary.mean_delay_ms;
end

diff_delay = base_delay_runs - v3_delay_runs;
mean_diff_delay = mean(diff_delay);
std_diff_delay = std(diff_delay);
se_diff_delay = std_diff_delay / sqrt(num_runs);
t_stat_delay = mean_diff_delay / se_diff_delay;

% p-value approximation
if abs(t_stat_delay) > 3.250
    p_delay = 0.01;
    p_delay_str = '< 0.01';
elseif abs(t_stat_delay) > 2.821
    p_delay = 0.02;
    p_delay_str = '< 0.02';
elseif abs(t_stat_delay) > 2.262
    p_delay = 0.05;
    p_delay_str = '< 0.05';
elseif abs(t_stat_delay) > 1.833
    p_delay = 0.10;
    p_delay_str = '< 0.10';
else
    p_delay = 0.20;
    p_delay_str = '> 0.10';
end

fprintf('Mean Delay paired t-test:\n');
fprintf('  Baseline: %.2f ± %.2f ms\n', mean(base_delay_runs), std(base_delay_runs));
fprintf('  v3:       %.2f ± %.2f ms\n', mean(v3_delay_runs), std(v3_delay_runs));
fprintf('  Difference: %.2f ± %.2f ms\n', mean_diff_delay, std_diff_delay);
fprintf('  t-statistic: %.3f (df=%d)\n', t_stat_delay, df);
fprintf('  p-value: %s\n', p_delay_str);

if abs(t_stat_delay) > 3.250
    fprintf('  Result: ✅ 매우 유의함 (p < 0.01)\n');
elseif abs(t_stat_delay) > 2.262
    fprintf('  Result: ✅ 유의함 (p < 0.05)\n');
elseif abs(t_stat_delay) > 1.833
    fprintf('  Result: ⚠️  약간 유의함 (p < 0.10)\n');
else
    fprintf('  Result: ❌ 유의하지 않음 (p > 0.10)\n');
end

fprintf('\n');

%% 4. packet_level 데이터 확인

fprintf('========================================\n');
fprintf('  packet_level 데이터 탐색\n');
fprintf('========================================\n\n');

if isfield(results.baseline{1}, 'packet_level')
    pl_fields = fieldnames(results.baseline{1}.packet_level);
    fprintf('packet_level 필드:\n');
    for i = 1:length(pl_fields)
        field = pl_fields{i};
        val = results.baseline{1}.packet_level.(field);
        
        if isnumeric(val) || islogical(val)
            fprintf('  %-30s: %s\n', field, mat2str(size(val)));
        else
            fprintf('  %-30s: %s\n', field, class(val));
        end
    end
    fprintf('\n');
    
    % Delay distribution 추출 (모든 runs 합침)
    if isfield(results.baseline{1}.packet_level, 'delays') || ...
       isfield(results.baseline{1}.packet_level, 'delay_samples')
        
        % 필드명 확인
        if isfield(results.baseline{1}.packet_level, 'delay_samples')
            delay_field = 'delay_samples';
        elseif isfield(results.baseline{1}.packet_level, 'delays')
            delay_field = 'delays';
        else
            delay_field = '';
        end
        
        if ~isempty(delay_field)
            base_delays = [];
            v3_delays = [];
            
            for run = 1:num_runs
                base_delays = [base_delays; results.baseline{run}.packet_level.(delay_field)];
                v3_delays = [v3_delays; results.v3{run}.packet_level.(delay_field)];
            end
            
            fprintf('Delay 데이터 발견!\n');
            fprintf('  Baseline: %d delays (all runs)\n', length(base_delays));
            fprintf('  v3: %d delays (all runs)\n', length(v3_delays));
            
            % Delay 통계
            base_delay_mean = mean(base_delays) * 1000;
            base_delay_std = std(base_delays) * 1000;
            base_delay_cv = base_delay_std / base_delay_mean;
            
            v3_delay_mean = mean(v3_delays) * 1000;
            v3_delay_std = std(v3_delays) * 1000;
            v3_delay_cv = v3_delay_std / v3_delay_mean;
            
            fprintf('\n');
            fprintf('Packet Delay 통계 (all delays):\n');
            fprintf('  Baseline: Mean=%.2f ms, Std=%.2f ms, CV=%.4f\n', ...
                base_delay_mean, base_delay_std, base_delay_cv);
            fprintf('  v3:       Mean=%.2f ms, Std=%.2f ms, CV=%.4f\n', ...
                v3_delay_mean, v3_delay_std, v3_delay_cv);
            fprintf('  Std reduction: %.2f%%\n', ...
                (base_delay_std - v3_delay_std)/base_delay_std*100);
            fprintf('  CV reduction: %.2f%%\n', ...
                (base_delay_cv - v3_delay_cv)/base_delay_cv*100);
            fprintf('\n');
        end
    end
end

%% 4. 시각화

fprintf('========================================\n');
fprintf('  시각화 생성 중...\n');
fprintf('========================================\n\n');

%% 4-1. UORA Delay Variability

figure('Position', [100, 100, 1400, 600]);

% Mean & Std
subplot(1, 3, 1);
x = [1, 2];
bar(x, [base_uora_mean, v3_uora_mean]);
hold on;
errorbar(x, [base_uora_mean, v3_uora_mean], [base_uora_std, v3_uora_std], '.k', 'LineWidth', 2);
hold off;
set(gca, 'XTickLabel', {'Baseline', 'v3'});
ylabel('UORA Delay [ms]');
title('UORA Delay (Mean ± Std)');
grid on;
legend('Mean', 'Std', 'Location', 'best');

% Std comparison
subplot(1, 3, 2);
bar([1, 2], [base_uora_std, v3_uora_std]);
hold on;
errorbar([1, 2], [base_uora_std, v3_uora_std], ...
    [base_uora_std_se, v3_uora_std_se], '.k', 'LineWidth', 2, 'MarkerSize', 20);
hold off;
set(gca, 'XTickLabel', {'Baseline', 'v3'});
ylabel('UORA Delay Std [ms]');
title(sprintf('UORA Delay Std (p %s)', p_std_str));
grid on;
text(1, base_uora_std, sprintf('%.2f', base_uora_std), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);
text(2, v3_uora_std, sprintf('%.2f', v3_uora_std), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);

% CV comparison
subplot(1, 3, 3);
bar([1, 2], [base_uora_cv, v3_uora_cv]);
set(gca, 'XTickLabel', {'Baseline', 'v3'});
ylabel('Coefficient of Variation');
title('UORA Delay CV Comparison');
grid on;
text(1, base_uora_cv, sprintf('%.4f', base_uora_cv), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);
text(2, v3_uora_cv, sprintf('%.4f', v3_uora_cv), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);

sgtitle('UORA Delay Variability: Baseline vs v3 (10 runs)', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'uora_variability.png');
fprintf('저장: uora_variability.png\n');

%% 4-2. Packet Delay Distribution (if available)

if exist('base_delays', 'var')
    figure('Position', [100, 100, 1400, 600]);
    
    % Histogram overlay
    subplot(1, 2, 1);
    histogram(base_delays * 1000, 100, 'Normalization', 'probability', ...
        'FaceAlpha', 0.7, 'DisplayName', 'Baseline');
    hold on;
    histogram(v3_delays * 1000, 100, 'Normalization', 'probability', ...
        'FaceAlpha', 0.7, 'DisplayName', 'v3');
    hold off;
    xlabel('Packet Delay [ms]');
    ylabel('Probability');
    title('Packet Delay Distribution');
    legend('Location', 'best');
    grid on;
    
    % CDF comparison (manual implementation)
    subplot(1, 2, 2);
    
    % Manual CDF calculation
    x_base_sorted = sort(base_delays * 1000);
    f_base = (1:length(x_base_sorted))' / length(x_base_sorted);
    
    x_v3_sorted = sort(v3_delays * 1000);
    f_v3 = (1:length(x_v3_sorted))' / length(x_v3_sorted);
    
    plot(x_base_sorted, f_base, 'LineWidth', 2, 'DisplayName', 'Baseline');
    hold on;
    plot(x_v3_sorted, f_v3, 'LineWidth', 2, 'DisplayName', 'v3');
    hold off;
    xlabel('Packet Delay [ms]');
    ylabel('CDF');
    title('Packet Delay CDF');
    legend('Location', 'best');
    grid on;
    
    sgtitle('Packet Delay Distribution: Baseline vs v3', 'FontSize', 14, 'FontWeight', 'bold');
    saveas(gcf, 'packet_delay_distribution.png');
    fprintf('저장: packet_delay_distribution.png\n');
end

fprintf('\n');

%% 5. 종합 결론

fprintf('========================================\n');
fprintf('  종합 결론\n');
fprintf('========================================\n\n');

% UORA delay variability reduction
uora_std_reduction = (base_uora_std - v3_uora_std) / base_uora_std * 100;
uora_cv_reduction = (base_uora_cv - v3_uora_cv) / base_uora_cv * 100;

fprintf('v3의 "안정화" 효과 (간접 증거):\n\n');

fprintf('1. UORA Delay Variability:\n');

if uora_std_reduction > 5
    fprintf('   ✅ UORA Std: %.2f%% 감소\n', uora_std_reduction);
elseif uora_std_reduction > 0
    fprintf('   ⚠️  UORA Std: %.2f%% 감소 (미미)\n', uora_std_reduction);
else
    fprintf('   ❌ UORA Std: %.2f%% 증가\n', abs(uora_std_reduction));
end

if uora_cv_reduction > 5
    fprintf('   ✅ UORA CV: %.2f%% 감소\n', uora_cv_reduction);
elseif uora_cv_reduction > 0
    fprintf('   ⚠️  UORA CV: %.2f%% 감소 (미미)\n', uora_cv_reduction);
else
    fprintf('   ❌ UORA CV: %.2f%% 증가\n', abs(uora_cv_reduction));
end

fprintf('\n');

% Packet delay variability (if available)
if exist('base_delays', 'var')
    pkt_std_reduction = (base_delay_std - v3_delay_std) / base_delay_std * 100;
    pkt_cv_reduction = (base_delay_cv - v3_delay_cv) / base_delay_cv * 100;
    
    fprintf('2. Packet Delay Variability:\n');
    
    if pkt_std_reduction > 5
        fprintf('   ✅ Packet Std: %.2f%% 감소\n', pkt_std_reduction);
    elseif pkt_std_reduction > 0
        fprintf('   ⚠️  Packet Std: %.2f%% 감소 (미미)\n', pkt_std_reduction);
    else
        fprintf('   ❌ Packet Std: %.2f%% 증가\n', abs(pkt_std_reduction));
    end
    
    if pkt_cv_reduction > 5
        fprintf('   ✅ Packet CV: %.2f%% 감소\n', pkt_cv_reduction);
    elseif pkt_cv_reduction > 0
        fprintf('   ⚠️  Packet CV: %.2f%% 감소 (미미)\n', pkt_cv_reduction);
    else
        fprintf('   ❌ Packet CV: %.2f%% 증가\n', abs(pkt_cv_reduction));
    end
    
    fprintf('\n');
end

% 성능 개선 확인
fprintf('2. 성능 개선 (10 runs 평균):\n');
fprintf('   Mean Delay: %.2f%% 개선 (p %s)\n', ...
    (mean(base_delay_runs) - mean(v3_delay_runs)) / mean(base_delay_runs) * 100, p_delay_str);

% Collision
base_coll_runs = zeros(num_runs, 1);
v3_coll_runs = zeros(num_runs, 1);
for i = 1:num_runs
    base_coll_runs(i) = results.baseline{i}.uora.collision_rate;
    v3_coll_runs(i) = results.v3{i}.uora.collision_rate;
end

diff_coll = base_coll_runs - v3_coll_runs;
mean_diff_coll = mean(diff_coll);
std_diff_coll = std(diff_coll);
se_diff_coll = std_diff_coll / sqrt(num_runs);
t_stat_coll = mean_diff_coll / se_diff_coll;

if abs(t_stat_coll) > 2.262
    p_coll_str = '< 0.05';
elseif abs(t_stat_coll) > 1.833
    p_coll_str = '< 0.10';
else
    p_coll_str = '> 0.10';
end

fprintf('   Collision: %.2f%% 개선 (p %s)\n', ...
    (mean(base_coll_runs) - mean(v3_coll_runs)) / mean(base_coll_runs) * 100, p_coll_str);

fprintf('\n');

% 가설 검증
fprintf('3. 가설 검증:\n');
if uora_std_reduction > 3 && abs(t_stat_std) > 2.262
    fprintf('✅ v3는 UORA delay의 변동성을 통계적으로 유의하게 줄임!\n');
    fprintf('   → UORA Std: %.2f%% 감소 (t=%.2f, p %s)\n', uora_std_reduction, t_stat_std, p_std_str);
    fprintf('   → BSR "안정화" 효과 증명! 🎉\n\n');
    fprintf('   메커니즘:\n');
    fprintf('   1. v3의 EMA가 BSR 값을 smoothing\n');
    fprintf('   2. AP가 예측 가능한 BSR 받음\n');
    fprintf('   3. UORA scheduling이 안정화\n');
    fprintf('   4. Contention delay variance 감소\n');
    fprintf('   5. 결과: Delay %.2f%% 개선, Collision %.2f%% 개선\n', ...
        (mean(base_delay_runs) - mean(v3_delay_runs)) / mean(base_delay_runs) * 100, ...
        (mean(base_coll_runs) - mean(v3_coll_runs)) / mean(base_coll_runs) * 100);
elseif uora_std_reduction > 0 && abs(t_stat_std) > 1.833
    fprintf('⚠️  UORA delay 변동성 감소하지만 약한 증거\n');
    fprintf('   → UORA Std: %.2f%% 감소 (t=%.2f, p %s)\n', uora_std_reduction, t_stat_std, p_std_str);
    fprintf('   → 더 많은 runs 필요 또는 효과 미미\n');
elseif abs(t_stat_std) <= 1.833
    fprintf('❌ UORA delay 변동성 감소가 통계적으로 유의하지 않음\n');
    fprintf('   → t-statistic: %.2f (< 1.833)\n', t_stat_std);
    fprintf('   → p-value: %s\n', p_std_str);
    fprintf('   → BSR 안정화 효과 불충분\n');
else
    fprintf('❌ UORA delay 변동성 감소 없음\n');
    fprintf('   → UORA Std: %.2f%% 변화\n', uora_std_reduction);
    fprintf('   → 다른 메커니즘 탐색 필요\n');
end

fprintf('\n');

fprintf('Note:\n');
fprintf('  - BSR trace가 없어 직접 증명 불가\n');
fprintf('  - UORA delay variability는 간접 증거\n');
fprintf('  - 10 runs로 statistical significance 확인\n');
fprintf('  - Manual t-test (df=9): t > 2.262 (p<0.05), t > 1.833 (p<0.10)\n');

fprintf('\n========================================\n\n');