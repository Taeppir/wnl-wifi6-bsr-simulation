%% analyze_safety_sweep.m
% Phase A 결과 분석
%
% 출력:
%   1. 각 config의 평균 성능
%   2. Best config 찾기 (시나리오별)
%   3. Heatmap (3×3 grid)
%   4. 기본값 vs 최적값 비교

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  Phase A 결과 분석\n');
fprintf('========================================\n\n');

%% 1. 결과 로드

load_file = 'safety_sweep_results.mat';
if ~exist(load_file, 'file')
    error('결과 파일 없음: %s', load_file);
end

fprintf('결과 로드: %s\n', load_file);
load(load_file);

num_scenarios = length(results.scenarios);
num_configs = length(results.config_list);
num_runs = results.num_runs;

fprintf('  Scenarios: %d\n', num_scenarios);
fprintf('  Configs: %d\n', num_configs);
fprintf('  Runs: %d\n\n', num_runs);

%% 2. Metric 추출

fprintf('========================================\n');
fprintf('  Metric 추출 중...\n');
fprintf('========================================\n\n');

metrics = struct();

for s = 1:num_scenarios
    
    sc = results.scenarios(s);
    
    % Baseline 평균
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.baseline(s, :)));
    base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.baseline(s, :)));
    base_coll = mean(cellfun(@(x) x.uora.collision_rate, results.baseline(s, :)));
    base_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.baseline(s, :)));
    base_total_bsr = mean(cellfun(@(x) x.bsr.total_bsr, results.baseline(s, :)));
    
    metrics(s).scenario_name = sc.name;
    metrics(s).base_delay = base_delay;
    metrics(s).base_p90 = base_p90;
    metrics(s).base_coll = base_coll;
    metrics(s).base_expl_ratio = base_expl / base_total_bsr * 100;
    
    % 각 config의 v3 평균
    for c = 1:num_configs
        
        config = results.config_list(c);
        
        v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, ...
            squeeze(results.v3(s, c, :))));
        v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, ...
            squeeze(results.v3(s, c, :))));
        v3_coll = mean(cellfun(@(x) x.uora.collision_rate, ...
            squeeze(results.v3(s, c, :))));
        v3_expl = mean(cellfun(@(x) x.bsr.total_explicit, ...
            squeeze(results.v3(s, c, :))));
        
        metrics(s).config(c).burst_threshold = config.burst_threshold;
        metrics(s).config(c).reduction_threshold = config.reduction_threshold;
        metrics(s).config(c).v3_delay = v3_delay;
        metrics(s).config(c).v3_p90 = v3_p90;
        metrics(s).config(c).v3_coll = v3_coll;
        metrics(s).config(c).v3_expl = v3_expl;
        
        % Improvement
        metrics(s).config(c).improve_delay = (base_delay - v3_delay) / base_delay * 100;
        metrics(s).config(c).improve_p90 = (base_p90 - v3_p90) / base_p90 * 100;
        metrics(s).config(c).improve_coll = (base_coll - v3_coll) / base_coll * 100;
    end
end

fprintf('Metric 추출 완료!\n\n');

%% 3. 각 시나리오별 결과 요약

fprintf('========================================\n');
fprintf('  시나리오별 결과 요약\n');
fprintf('========================================\n\n');

for s = 1:num_scenarios
    
    m = metrics(s);
    
    fprintf('[%s] L=%.1f, mu=%.2f, rho=%.1f\n', ...
        results.scenarios(s).name, results.scenarios(s).L_cell, ...
        results.scenarios(s).mu_on, results.scenarios(s).rho);
    fprintf('Baseline: Delay=%.2f ms, Coll=%.2f%%, ExplR=%.1f%%\n', ...
        m.base_delay, m.base_coll*100, m.base_expl_ratio);
    fprintf('\n');
    
    fprintf('%-8s | %-8s | %-10s | %-10s | %-10s\n', ...
        'Burst', 'RedThres', 'Delay Imp', 'P90 Imp', 'Coll Imp');
    fprintf('%s\n', repmat('-', 1, 60));
    
    for c = 1:num_configs
        cfg = m.config(c);
        fprintf('%6dk | %6d   | %8.2f%% | %8.2f%% | %8.2f%%\n', ...
            cfg.burst_threshold/1000, cfg.reduction_threshold, ...
            cfg.improve_delay, cfg.improve_p90, cfg.improve_coll);
    end
    
    % Best config 찾기
    [best_improve, best_idx] = max([m.config.improve_delay]);
    best_config = m.config(best_idx);
    
    fprintf('\n✅ Best config: burst=%dk, reduction=%d\n', ...
        best_config.burst_threshold/1000, best_config.reduction_threshold);
    fprintf('   Improvement: Delay %.2f%%, P90 %.2f%%, Coll %.2f%%\n', ...
        best_config.improve_delay, best_config.improve_p90, best_config.improve_coll);
    
    fprintf('\n');
end

%% 4. Heatmap 시각화

fprintf('========================================\n');
fprintf('  Heatmap 생성 중...\n');
fprintf('========================================\n\n');

burst_values = results.burst_threshold_values;
reduction_values = results.reduction_threshold_values;

num_burst = length(burst_values);
num_reduction = length(reduction_values);

for s = 1:num_scenarios
    
    m = metrics(s);
    
    % 데이터 재구성 (3×3 matrix)
    delay_improve_mat = zeros(num_reduction, num_burst);
    p90_improve_mat = zeros(num_reduction, num_burst);
    coll_improve_mat = zeros(num_reduction, num_burst);
    
    c_idx = 0;
    for b_idx = 1:num_burst
        for r_idx = 1:num_reduction
            c_idx = c_idx + 1;
            delay_improve_mat(r_idx, b_idx) = m.config(c_idx).improve_delay;
            p90_improve_mat(r_idx, b_idx) = m.config(c_idx).improve_p90;
            coll_improve_mat(r_idx, b_idx) = m.config(c_idx).improve_coll;
        end
    end
    
    % Figure
    figure('Position', [100, 100, 1400, 400]);
    sgtitle(sprintf('%s: Safety Parameter Sweep (L=%.1f, \\mu=%.2f, \\rho=%.1f)', ...
        results.scenarios(s).name, results.scenarios(s).L_cell, ...
        results.scenarios(s).mu_on, results.scenarios(s).rho), ...
        'FontSize', 14, 'FontWeight', 'bold');
    
    % 1. Mean Delay Improvement
    subplot(1, 3, 1);
    imagesc(delay_improve_mat);
    colorbar;
    colormap(jet);
    
    % 값 표시
    for b = 1:num_burst
        for r = 1:num_reduction
            text(b, r, sprintf('%.2f', delay_improve_mat(r, b)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, ...
                'FontWeight', 'bold', 'Color', 'white');
        end
    end
    
    % Best config 표시
    [~, best_idx] = max(delay_improve_mat(:));
    [best_r, best_b] = ind2sub(size(delay_improve_mat), best_idx);
    hold on;
    plot(best_b, best_r, 'w*', 'MarkerSize', 20, 'LineWidth', 3);
    hold off;
    
    set(gca, 'XTick', 1:num_burst, 'XTickLabel', ...
        arrayfun(@(x) sprintf('%dk', x/1000), burst_values, 'UniformOutput', false));
    set(gca, 'YTick', 1:num_reduction, 'YTickLabel', ...
        arrayfun(@(x) sprintf('%d', x), reduction_values, 'UniformOutput', false));
    xlabel('burst\_threshold [bytes]');
    ylabel('reduction\_threshold [bytes]');
    title('Mean Delay Improvement [%]');
    
    % 2. P90 Delay Improvement
    subplot(1, 3, 2);
    imagesc(p90_improve_mat);
    colorbar;
    colormap(jet);
    
    for b = 1:num_burst
        for r = 1:num_reduction
            text(b, r, sprintf('%.2f', p90_improve_mat(r, b)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, ...
                'FontWeight', 'bold', 'Color', 'white');
        end
    end
    
    set(gca, 'XTick', 1:num_burst, 'XTickLabel', ...
        arrayfun(@(x) sprintf('%dk', x/1000), burst_values, 'UniformOutput', false));
    set(gca, 'YTick', 1:num_reduction, 'YTickLabel', ...
        arrayfun(@(x) sprintf('%d', x), reduction_values, 'UniformOutput', false));
    xlabel('burst\_threshold [bytes]');
    ylabel('reduction\_threshold [bytes]');
    title('P90 Delay Improvement [%]');
    
    % 3. Collision Improvement
    subplot(1, 3, 3);
    imagesc(coll_improve_mat);
    colorbar;
    colormap(jet);
    
    for b = 1:num_burst
        for r = 1:num_reduction
            text(b, r, sprintf('%.2f', coll_improve_mat(r, b)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, ...
                'FontWeight', 'bold', 'Color', 'white');
        end
    end
    
    set(gca, 'XTick', 1:num_burst, 'XTickLabel', ...
        arrayfun(@(x) sprintf('%dk', x/1000), burst_values, 'UniformOutput', false));
    set(gca, 'YTick', 1:num_reduction, 'YTickLabel', ...
        arrayfun(@(x) sprintf('%d', x), reduction_values, 'UniformOutput', false));
    xlabel('burst\_threshold [bytes]');
    ylabel('reduction\_threshold [bytes]');
    title('Collision Improvement [%]');
    
    % 저장
    saveas(gcf, sprintf('safety_heatmap_%s.png', results.scenarios(s).name));
    fprintf('저장: safety_heatmap_%s.png\n', results.scenarios(s).name);
end

%% 5. 전체 평균 & 최적 config

fprintf('\n========================================\n');
fprintf('  전체 평균 & 최적 Config\n');
fprintf('========================================\n\n');

% 각 config의 전체 평균 improvement
avg_improvements = zeros(num_configs, 3);  % delay, p90, coll

for c = 1:num_configs
    delay_imps = [];
    p90_imps = [];
    coll_imps = [];
    
    for s = 1:num_scenarios
        delay_imps(s) = metrics(s).config(c).improve_delay;
        p90_imps(s) = metrics(s).config(c).improve_p90;
        coll_imps(s) = metrics(s).config(c).improve_coll;
    end
    
    avg_improvements(c, 1) = mean(delay_imps);
    avg_improvements(c, 2) = mean(p90_imps);
    avg_improvements(c, 3) = mean(coll_imps);
end

fprintf('전체 평균 Improvement (3 scenarios):\n\n');
fprintf('%-8s | %-8s | %-10s | %-10s | %-10s\n', ...
    'Burst', 'RedThres', 'Delay', 'P90', 'Coll');
fprintf('%s\n', repmat('-', 1, 60));

for c = 1:num_configs
    cfg = results.config_list(c);
    fprintf('%6dk | %6d   | %8.2f%% | %8.2f%% | %8.2f%%\n', ...
        cfg.burst_threshold/1000, cfg.reduction_threshold, ...
        avg_improvements(c, 1), avg_improvements(c, 2), avg_improvements(c, 3));
end

% Best overall config
[best_delay, best_idx] = max(avg_improvements(:, 1));
best_config = results.config_list(best_idx);

fprintf('\n✅✅ Overall Best Config:\n');
fprintf('   burst_threshold: %d bytes (%.0fk)\n', ...
    best_config.burst_threshold, best_config.burst_threshold/1000);
fprintf('   reduction_threshold: %d bytes\n', best_config.reduction_threshold);
fprintf('   평균 Improvement:\n');
fprintf('     Delay: %.2f%%\n', avg_improvements(best_idx, 1));
fprintf('     P90:   %.2f%%\n', avg_improvements(best_idx, 2));
fprintf('     Coll:  %.2f%%\n\n', avg_improvements(best_idx, 3));

%% 6. 기본값 비교

% 기본값 추정 (가장 중간값)
default_burst = 10000;
default_reduction = 1000;

default_idx = find([results.config_list.burst_threshold] == default_burst & ...
                   [results.config_list.reduction_threshold] == default_reduction);

if ~isempty(default_idx)
    fprintf('========================================\n');
    fprintf('  기본값 vs 최적값 비교\n');
    fprintf('========================================\n\n');
    
    fprintf('기본값 (burst=%dk, reduction=%d):\n', ...
        default_burst/1000, default_reduction);
    fprintf('  평균 Improvement: Delay %.2f%%, P90 %.2f%%, Coll %.2f%%\n\n', ...
        avg_improvements(default_idx, 1), avg_improvements(default_idx, 2), ...
        avg_improvements(default_idx, 3));
    
    fprintf('최적값 (burst=%dk, reduction=%d):\n', ...
        best_config.burst_threshold/1000, best_config.reduction_threshold);
    fprintf('  평균 Improvement: Delay %.2f%%, P90 %.2f%%, Coll %.2f%%\n\n', ...
        avg_improvements(best_idx, 1), avg_improvements(best_idx, 2), ...
        avg_improvements(best_idx, 3));
    
    gain_delay = avg_improvements(best_idx, 1) - avg_improvements(default_idx, 1);
    gain_p90 = avg_improvements(best_idx, 2) - avg_improvements(default_idx, 2);
    gain_coll = avg_improvements(best_idx, 3) - avg_improvements(default_idx, 3);
    
    fprintf('추가 개선 (최적값 - 기본값):\n');
    fprintf('  Delay: +%.2f%% point\n', gain_delay);
    fprintf('  P90:   +%.2f%% point\n', gain_p90);
    fprintf('  Coll:  +%.2f%% point\n\n', gain_coll);
end

fprintf('========================================\n');
fprintf('  분석 완료!\n');
fprintf('========================================\n\n');

fprintf('생성된 파일:\n');
for s = 1:num_scenarios
    fprintf('  - safety_heatmap_%s.png\n', results.scenarios(s).name);
end
fprintf('\n');