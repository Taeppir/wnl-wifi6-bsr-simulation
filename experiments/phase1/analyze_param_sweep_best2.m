%% analyze_param_sweep_best2.m
% v3 파라미터 극단 테스트 결과 분석
%
% Heatmap: alpha × max_reduction
% Best config 찾기
% Baseline vs v3 비교

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  파라미터 Sweep 결과 분석\n');
fprintf('========================================\n\n');

%% 1. 결과 로드

load_file = 'param_sweep_best2_results.mat';
if ~exist(load_file, 'file')
    error('결과 파일 없음: %s\n먼저 param_sweep_best2.m을 실행하세요!', load_file);
end

fprintf('결과 로드: %s\n', load_file);
load(load_file);

num_scenarios = length(results.scenarios);
num_configs = length(results.alpha_values) * length(results.max_red_values);
num_runs = results.num_runs;

fprintf('  Scenarios: %d\n', num_scenarios);
fprintf('  Configs: %d (+ Baseline)\n', num_configs);
fprintf('  Runs per config: %d\n\n', num_runs);

%% 2. Metric 추출

fprintf('========================================\n');
fprintf('  Metric 추출 중...\n');
fprintf('========================================\n\n');

alpha_values = results.alpha_values;
max_red_values = results.max_red_values;
num_alpha = length(alpha_values);
num_max_red = length(max_red_values);

% 각 scenario별 분석
for s_idx = 1:num_scenarios
    
    sc = results.scenarios(s_idx);
    
    fprintf('[%s] L=%.1f, mu=%.2f, rho=%.1f, RA=%d\n', ...
        sc.name, sc.L_cell, sc.mu_on, sc.rho, sc.RA_RU);
    
    % Baseline 평균
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.baseline(s_idx, :)));
    base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.baseline(s_idx, :)));
    base_coll = mean(cellfun(@(x) x.uora.collision_rate, results.baseline(s_idx, :)));
    base_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.baseline(s_idx, :)));
    base_total = mean(cellfun(@(x) x.bsr.total_bsr, results.baseline(s_idx, :)));
    base_expl_ratio = base_expl / base_total * 100;
    
    fprintf('  Baseline: Delay=%.2f ms, Coll=%.1f%%, ExplR=%.1f%%\n', ...
        base_delay, base_coll*100, base_expl_ratio);
    
    % v3 configs - heatmap 데이터
    hm_delay = nan(num_alpha, num_max_red);
    hm_p90 = nan(num_alpha, num_max_red);
    hm_coll = nan(num_alpha, num_max_red);
    hm_expl = nan(num_alpha, num_max_red);
    
    hm_delay_abs = nan(num_alpha, num_max_red);
    hm_coll_abs = nan(num_alpha, num_max_red);
    
    config_idx = 0;
    for alpha_idx = 1:num_alpha
        for max_red_idx = 1:num_max_red
            config_idx = config_idx + 1;
            
            % v3 평균
            v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.v3(s_idx, config_idx, :)));
            v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.v3(s_idx, config_idx, :)));
            v3_coll = mean(cellfun(@(x) x.uora.collision_rate, results.v3(s_idx, config_idx, :)));
            v3_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.v3(s_idx, config_idx, :)));
            
            % Improvement
            hm_delay(alpha_idx, max_red_idx) = (base_delay - v3_delay) / base_delay * 100;
            hm_p90(alpha_idx, max_red_idx) = (base_p90 - v3_p90) / base_p90 * 100;
            hm_coll(alpha_idx, max_red_idx) = (base_coll - v3_coll) / base_coll * 100;
            hm_expl(alpha_idx, max_red_idx) = (base_expl - v3_expl) / base_expl * 100;
            
            % Absolute values
            hm_delay_abs(alpha_idx, max_red_idx) = v3_delay;
            hm_coll_abs(alpha_idx, max_red_idx) = v3_coll * 100;
        end
    end
    
    % Best config 찾기
    [max_improve, max_idx] = max(hm_delay(:));
    [best_alpha_idx, best_max_red_idx] = ind2sub([num_alpha, num_max_red], max_idx);
    best_alpha = alpha_values(best_alpha_idx);
    best_max_red = max_red_values(best_max_red_idx);
    
    fprintf('  Best config: alpha=%.2f, max_red=%.1f → Delay improve %.2f%%\n', ...
        best_alpha, best_max_red, max_improve);
    fprintf('               P90 improve: %.2f%%, Coll improve: %.2f%%\n', ...
        hm_p90(best_alpha_idx, best_max_red_idx), ...
        hm_coll(best_alpha_idx, best_max_red_idx));
    fprintf('\n');
    
    %% Heatmap 시각화
    
    figure('Position', [100, 100, 1400, 1000]);
    sgtitle(sprintf('v3 Parameter Sweep [%s: L=%.1f, \\mu=%.2f, \\rho=%.1f, RA=%d]', ...
        sc.name, sc.L_cell, sc.mu_on, sc.rho, sc.RA_RU), ...
        'FontSize', 14, 'FontWeight', 'bold');
    
    % 1. Mean Delay Improvement
    subplot(2, 3, 1);
    imagesc(hm_delay');
    colorbar;
    colormap(gca, jet);
    caxis([0 10]);
    set(gca, 'XTick', 1:num_alpha, 'XTickLabel', arrayfun(@num2str, alpha_values, 'UniformOutput', false));
    set(gca, 'YTick', 1:num_max_red, 'YTickLabel', arrayfun(@num2str, max_red_values, 'UniformOutput', false));
    xlabel('EMA \alpha');
    ylabel('Max Reduction');
    title('Mean Delay Improvement [%]');
    for i = 1:num_alpha
        for j = 1:num_max_red
            text(i, j, sprintf('%.1f', hm_delay(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
        end
    end
    % Mark best
    hold on;
    plot(best_alpha_idx, best_max_red_idx, 'w*', 'MarkerSize', 20, 'LineWidth', 3);
    hold off;
    
    % 2. P90 Delay Improvement
    subplot(2, 3, 2);
    imagesc(hm_p90');
    colorbar;
    colormap(gca, jet);
    caxis([0 10]);
    set(gca, 'XTick', 1:num_alpha, 'XTickLabel', arrayfun(@num2str, alpha_values, 'UniformOutput', false));
    set(gca, 'YTick', 1:num_max_red, 'YTickLabel', arrayfun(@num2str, max_red_values, 'UniformOutput', false));
    xlabel('EMA \alpha');
    ylabel('Max Reduction');
    title('P90 Delay Improvement [%]');
    for i = 1:num_alpha
        for j = 1:num_max_red
            text(i, j, sprintf('%.1f', hm_p90(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
        end
    end
    
    % 3. Collision Improvement
    subplot(2, 3, 3);
    imagesc(hm_coll');
    colorbar;
    colormap(gca, jet);
    caxis([0 10]);
    set(gca, 'XTick', 1:num_alpha, 'XTickLabel', arrayfun(@num2str, alpha_values, 'UniformOutput', false));
    set(gca, 'YTick', 1:num_max_red, 'YTickLabel', arrayfun(@num2str, max_red_values, 'UniformOutput', false));
    xlabel('EMA \alpha');
    ylabel('Max Reduction');
    title('Collision Improvement [%]');
    for i = 1:num_alpha
        for j = 1:num_max_red
            text(i, j, sprintf('%.1f', hm_coll(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
        end
    end
    
    % 4. Explicit BSR Reduction
    subplot(2, 3, 4);
    imagesc(hm_expl');
    colorbar;
    colormap(gca, jet);
    caxis([-5 10]);
    set(gca, 'XTick', 1:num_alpha, 'XTickLabel', arrayfun(@num2str, alpha_values, 'UniformOutput', false));
    set(gca, 'YTick', 1:num_max_red, 'YTickLabel', arrayfun(@num2str, max_red_values, 'UniformOutput', false));
    xlabel('EMA \alpha');
    ylabel('Max Reduction');
    title('Explicit BSR Reduction [%]');
    for i = 1:num_alpha
        for j = 1:num_max_red
            text(i, j, sprintf('%.1f', hm_expl(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
        end
    end
    
    % 5. Absolute Delay
    subplot(2, 3, 5);
    imagesc(hm_delay_abs');
    colorbar;
    colormap(gca, hot);
    set(gca, 'XTick', 1:num_alpha, 'XTickLabel', arrayfun(@num2str, alpha_values, 'UniformOutput', false));
    set(gca, 'YTick', 1:num_max_red, 'YTickLabel', arrayfun(@num2str, max_red_values, 'UniformOutput', false));
    xlabel('EMA \alpha');
    ylabel('Max Reduction');
    title('Absolute Mean Delay [ms]');
    for i = 1:num_alpha
        for j = 1:num_max_red
            text(i, j, sprintf('%.1f', hm_delay_abs(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'white');
        end
    end
    
    % 6. Absolute Collision
    subplot(2, 3, 6);
    imagesc(hm_coll_abs');
    colorbar;
    colormap(gca, hot);
    set(gca, 'XTick', 1:num_alpha, 'XTickLabel', arrayfun(@num2str, alpha_values, 'UniformOutput', false));
    set(gca, 'YTick', 1:num_max_red, 'YTickLabel', arrayfun(@num2str, max_red_values, 'UniformOutput', false));
    xlabel('EMA \alpha');
    ylabel('Max Reduction');
    title('Absolute Collision Rate [%]');
    for i = 1:num_alpha
        for j = 1:num_max_red
            text(i, j, sprintf('%.1f', hm_coll_abs(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'white');
        end
    end
    
    saveas(gcf, sprintf('param_heatmap_%s.png', sc.name));
    fprintf('저장: param_heatmap_%s.png\n', sc.name);
end

fprintf('\n');

%% 3. 종합 결론

fprintf('========================================\n');
fprintf('  종합 결론\n');
fprintf('========================================\n\n');

fprintf('파라미터 최적화 결과:\n');
for s_idx = 1:num_scenarios
    sc = results.scenarios(s_idx);
    
    % 재계산
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.baseline(s_idx, :)));
    
    hm_delay = nan(num_alpha, num_max_red);
    config_idx = 0;
    for alpha_idx = 1:num_alpha
        for max_red_idx = 1:num_max_red
            config_idx = config_idx + 1;
            v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.v3(s_idx, config_idx, :)));
            hm_delay(alpha_idx, max_red_idx) = (base_delay - v3_delay) / base_delay * 100;
        end
    end
    
    [max_improve, max_idx] = max(hm_delay(:));
    [best_alpha_idx, best_max_red_idx] = ind2sub([num_alpha, num_max_red], max_idx);
    best_alpha = alpha_values(best_alpha_idx);
    best_max_red = max_red_values(best_max_red_idx);
    
    fprintf('  %s: Best alpha=%.2f, max_red=%.1f → %.2f%% improvement\n', ...
        sc.name, best_alpha, best_max_red, max_improve);
end

fprintf('\n');

% 원래 파라미터와 비교
fprintf('기존 파라미터 (alpha=0.10, max_red=0.70)와 비교:\n');
for s_idx = 1:num_scenarios
    sc = results.scenarios(s_idx);
    
    % 기존: alpha=0.10, max_red=0.70
    old_alpha_idx = find(alpha_values == 0.05);  % 가장 가까운 것
    if isempty(old_alpha_idx)
        old_alpha_idx = 1;
    end
    old_max_red_idx = 2;  % 0.9가 가까움
    
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.baseline(s_idx, :)));
    
    hm_delay = nan(num_alpha, num_max_red);
    config_idx = 0;
    for alpha_idx = 1:num_alpha
        for max_red_idx = 1:num_max_red
            config_idx = config_idx + 1;
            v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.v3(s_idx, config_idx, :)));
            hm_delay(alpha_idx, max_red_idx) = (base_delay - v3_delay) / base_delay * 100;
        end
    end
    
    [max_improve, max_idx] = max(hm_delay(:));
    
    fprintf('  %s: 기존 대비 최대 %.2f%% 추가 개선 가능\n', sc.name, max_improve);
end

fprintf('\n========================================\n\n');