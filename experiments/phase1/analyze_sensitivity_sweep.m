%% analyze_sensitivity_sweep.m
% Phase A - Step 2 결과 분석
%
% 출력:
%   1. Sensitivity별 성능
%   2. Line plot (sensitivity vs improvement)
%   3. Best sensitivity 찾기
%   4. Step 1 + Step 2 최종 권장값

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  Phase A - Step 2 결과 분석\n');
fprintf('========================================\n\n');

%% 1. 결과 로드

load_file = 'sensitivity_sweep_results.mat';
if ~exist(load_file, 'file')
    error('결과 파일 없음: %s', load_file);
end

fprintf('결과 로드: %s\n', load_file);
load(load_file);

num_scenarios = length(results_step2.scenarios);
num_sensitivity = length(results_step2.sensitivity_values);
num_runs = results_step2.num_runs;

fprintf('  Scenarios: %d\n', num_scenarios);
fprintf('  Sensitivity configs: %d\n', num_sensitivity);
fprintf('  Runs: %d\n\n', num_runs);

fprintf('고정 파라미터:\n');
fprintf('  burst_threshold: %d bytes\n', results_step2.best_burst_threshold);
fprintf('  reduction_threshold: %d bytes\n', results_step2.best_reduction_threshold);
fprintf('  alpha: %.2f\n', results_step2.v3_alpha);
fprintf('  max_reduction: %.2f\n\n', results_step2.v3_max_red);

%% 2. Metric 추출

fprintf('========================================\n');
fprintf('  Metric 추출 중...\n');
fprintf('========================================\n\n');

metrics = struct();

for s = 1:num_scenarios
    
    sc = results_step2.scenarios(s);
    
    % Baseline 평균
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, ...
        results_step2.baseline(s, :)));
    base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, ...
        results_step2.baseline(s, :)));
    base_coll = mean(cellfun(@(x) x.uora.collision_rate, ...
        results_step2.baseline(s, :)));
    base_expl = mean(cellfun(@(x) x.bsr.total_explicit, ...
        results_step2.baseline(s, :)));
    base_total_bsr = mean(cellfun(@(x) x.bsr.total_bsr, ...
        results_step2.baseline(s, :)));
    
    metrics(s).scenario_name = sc.name;
    metrics(s).base_delay = base_delay;
    metrics(s).base_p90 = base_p90;
    metrics(s).base_coll = base_coll;
    metrics(s).base_expl_ratio = base_expl / base_total_bsr * 100;
    
    % 각 sensitivity의 v3 평균
    for sens_idx = 1:num_sensitivity
        
        sens = results_step2.sensitivity_values(sens_idx);
        
        v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, ...
            squeeze(results_step2.v3(s, sens_idx, :))));
        v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, ...
            squeeze(results_step2.v3(s, sens_idx, :))));
        v3_coll = mean(cellfun(@(x) x.uora.collision_rate, ...
            squeeze(results_step2.v3(s, sens_idx, :))));
        
        metrics(s).sensitivity(sens_idx).value = sens;
        metrics(s).sensitivity(sens_idx).v3_delay = v3_delay;
        metrics(s).sensitivity(sens_idx).v3_p90 = v3_p90;
        metrics(s).sensitivity(sens_idx).v3_coll = v3_coll;
        
        % Improvement
        metrics(s).sensitivity(sens_idx).improve_delay = ...
            (base_delay - v3_delay) / base_delay * 100;
        metrics(s).sensitivity(sens_idx).improve_p90 = ...
            (base_p90 - v3_p90) / base_p90 * 100;
        metrics(s).sensitivity(sens_idx).improve_coll = ...
            (base_coll - v3_coll) / base_coll * 100;
    end
end

fprintf('Metric 추출 완료!\n\n');

%% 3. 시나리오별 결과 요약

fprintf('========================================\n');
fprintf('  시나리오별 결과 요약\n');
fprintf('========================================\n\n');

for s = 1:num_scenarios
    
    m = metrics(s);
    
    fprintf('[%s] L=%.1f, mu=%.2f, rho=%.1f\n', ...
        results_step2.scenarios(s).name, results_step2.scenarios(s).L_cell, ...
        results_step2.scenarios(s).mu_on, results_step2.scenarios(s).rho);
    fprintf('Baseline: Delay=%.2f ms, Coll=%.2f%%, ExplR=%.1f%%\n', ...
        m.base_delay, m.base_coll*100, m.base_expl_ratio);
    fprintf('\n');
    
    fprintf('%-12s | %-10s | %-10s | %-10s\n', ...
        'Sensitivity', 'Delay Imp', 'P90 Imp', 'Coll Imp');
    fprintf('%s\n', repmat('-', 1, 50));
    
    for sens_idx = 1:num_sensitivity
        s_cfg = m.sensitivity(sens_idx);
        fprintf('%10.1f   | %8.2f%% | %8.2f%% | %8.2f%%\n', ...
            s_cfg.value, s_cfg.improve_delay, s_cfg.improve_p90, s_cfg.improve_coll);
    end
    
    % Best sensitivity 찾기
    [best_improve, best_idx] = max([m.sensitivity.improve_delay]);
    best_sens = m.sensitivity(best_idx);
    
    fprintf('\n✅ Best sensitivity: %.1f\n', best_sens.value);
    fprintf('   Improvement: Delay %.2f%%, P90 %.2f%%, Coll %.2f%%\n', ...
        best_sens.improve_delay, best_sens.improve_p90, best_sens.improve_coll);
    
    fprintf('\n');
end

%% 4. Line Plot 시각화

fprintf('========================================\n');
fprintf('  Line Plot 생성 중...\n');
fprintf('========================================\n\n');

sens_values = results_step2.sensitivity_values;

figure('Position', [100, 100, 1400, 400]);
sgtitle('Sensitivity Sweep Results', 'FontSize', 14, 'FontWeight', 'bold');

colors = lines(num_scenarios);

% 1. Mean Delay Improvement
subplot(1, 3, 1);
hold on;
for s = 1:num_scenarios
    delay_imps = [metrics(s).sensitivity.improve_delay];
    plot(sens_values, delay_imps, '-o', 'LineWidth', 2, 'MarkerSize', 8, ...
        'Color', colors(s, :), 'DisplayName', results_step2.scenarios(s).name);
end
hold off;
xlabel('Sensitivity');
ylabel('Mean Delay Improvement [%]');
title('Mean Delay Improvement');
legend('Location', 'best');
grid on;

% 2. P90 Delay Improvement
subplot(1, 3, 2);
hold on;
for s = 1:num_scenarios
    p90_imps = [metrics(s).sensitivity.improve_p90];
    plot(sens_values, p90_imps, '-o', 'LineWidth', 2, 'MarkerSize', 8, ...
        'Color', colors(s, :), 'DisplayName', results_step2.scenarios(s).name);
end
hold off;
xlabel('Sensitivity');
ylabel('P90 Delay Improvement [%]');
title('P90 Delay Improvement');
legend('Location', 'best');
grid on;

% 3. Collision Improvement
subplot(1, 3, 3);
hold on;
for s = 1:num_scenarios
    coll_imps = [metrics(s).sensitivity.improve_coll];
    plot(sens_values, coll_imps, '-o', 'LineWidth', 2, 'MarkerSize', 8, ...
        'Color', colors(s, :), 'DisplayName', results_step2.scenarios(s).name);
end
hold off;
xlabel('Sensitivity');
ylabel('Collision Improvement [%]');
title('Collision Improvement');
legend('Location', 'best');
grid on;

saveas(gcf, 'sensitivity_sweep_plot.png');
fprintf('저장: sensitivity_sweep_plot.png\n\n');

%% 5. 전체 평균 & Best Sensitivity

fprintf('========================================\n');
fprintf('  전체 평균 & Best Sensitivity\n');
fprintf('========================================\n\n');

% 각 sensitivity의 전체 평균
avg_improvements = zeros(num_sensitivity, 3);  % delay, p90, coll

for sens_idx = 1:num_sensitivity
    delay_imps = [];
    p90_imps = [];
    coll_imps = [];
    
    for s = 1:num_scenarios
        delay_imps(s) = metrics(s).sensitivity(sens_idx).improve_delay;
        p90_imps(s) = metrics(s).sensitivity(sens_idx).improve_p90;
        coll_imps(s) = metrics(s).sensitivity(sens_idx).improve_coll;
    end
    
    avg_improvements(sens_idx, 1) = mean(delay_imps);
    avg_improvements(sens_idx, 2) = mean(p90_imps);
    avg_improvements(sens_idx, 3) = mean(coll_imps);
end

fprintf('전체 평균 Improvement (3 scenarios):\n\n');
fprintf('%-12s | %-10s | %-10s | %-10s\n', ...
    'Sensitivity', 'Delay', 'P90', 'Coll');
fprintf('%s\n', repmat('-', 1, 50));

for sens_idx = 1:num_sensitivity
    fprintf('%10.1f   | %8.2f%% | %8.2f%% | %8.2f%%\n', ...
        sens_values(sens_idx), avg_improvements(sens_idx, 1), ...
        avg_improvements(sens_idx, 2), avg_improvements(sens_idx, 3));
end

% Best overall sensitivity
[best_delay, best_idx] = max(avg_improvements(:, 1));
best_sens = sens_values(best_idx);

fprintf('\n✅✅ Overall Best Sensitivity: %.1f\n', best_sens);
fprintf('   평균 Improvement:\n');
fprintf('     Delay: %.2f%%\n', avg_improvements(best_idx, 1));
fprintf('     P90:   %.2f%%\n', avg_improvements(best_idx, 2));
fprintf('     Coll:  %.2f%%\n\n', avg_improvements(best_idx, 3));

%% 6. 최종 권장값 (Step 1 + Step 2)

fprintf('========================================\n');
fprintf('  Phase A 최종 권장 파라미터\n');
fprintf('========================================\n\n');

fprintf('✅✅✅ 최적 파라미터:\n\n');
fprintf('  burst_threshold:     %d bytes (%.0fk)\n', ...
    results_step2.best_burst_threshold, results_step2.best_burst_threshold/1000);
fprintf('  reduction_threshold: %d bytes\n', results_step2.best_reduction_threshold);
fprintf('  sensitivity:         %.1f\n', best_sens);
fprintf('\n');
fprintf('  (고정 파라미터)\n');
fprintf('  alpha:               %.2f\n', results_step2.v3_alpha);
fprintf('  max_reduction:       %.2f\n\n', results_step2.v3_max_red);

fprintf('예상 효과 (Best 3 scenarios 평균):\n');
fprintf('  Mean Delay: %.2f%% 개선\n', avg_improvements(best_idx, 1));
fprintf('  P90 Delay:  %.2f%% 개선\n', avg_improvements(best_idx, 2));
fprintf('  Collision:  %.2f%% 개선\n\n', avg_improvements(best_idx, 3));

%% 7. 기본값과 비교

default_sens_idx = find(sens_values == 1.0);
if ~isempty(default_sens_idx)
    fprintf('========================================\n');
    fprintf('  기본값 vs 최적값 비교\n');
    fprintf('========================================\n\n');
    
    fprintf('기본값 (sensitivity=1.0):\n');
    fprintf('  평균 Improvement: Delay %.2f%%, P90 %.2f%%, Coll %.2f%%\n\n', ...
        avg_improvements(default_sens_idx, 1), avg_improvements(default_sens_idx, 2), ...
        avg_improvements(default_sens_idx, 3));
    
    fprintf('최적값 (sensitivity=%.1f):\n', best_sens);
    fprintf('  평균 Improvement: Delay %.2f%%, P90 %.2f%%, Coll %.2f%%\n\n', ...
        avg_improvements(best_idx, 1), avg_improvements(best_idx, 2), ...
        avg_improvements(best_idx, 3));
    
    gain_delay = avg_improvements(best_idx, 1) - avg_improvements(default_sens_idx, 1);
    gain_p90 = avg_improvements(best_idx, 2) - avg_improvements(default_sens_idx, 2);
    gain_coll = avg_improvements(best_idx, 3) - avg_improvements(default_sens_idx, 3);
    
    fprintf('추가 개선 (최적값 - 기본값):\n');
    fprintf('  Delay: %+.2f%% point\n', gain_delay);
    fprintf('  P90:   %+.2f%% point\n', gain_p90);
    fprintf('  Coll:  %+.2f%% point\n\n', gain_coll);
end

fprintf('========================================\n');
fprintf('  분석 완료!\n');
fprintf('========================================\n\n');

fprintf('생성된 파일:\n');
fprintf('  - sensitivity_sweep_plot.png\n\n');