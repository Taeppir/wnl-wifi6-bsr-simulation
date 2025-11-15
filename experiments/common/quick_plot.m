function quick_plot(results_grid, exp_config)
% QUICK_PLOT: 실험 직후 빠른 시각화 (3~4개 핵심 지표)
%
% 입력:
%   results_grid - 결과 구조체
%   exp_config   - 실험 설정 구조체
%
% 출력:
%   - results/quick_plots/[exp_name]_quick.png

    fprintf('[Quick Plot 생성]\n');
    
    %% =====================================================================
    %  1. 평균 계산
    %  =====================================================================
    
    is_2d = isfield(exp_config, 'sweep_var2');
    
    % 마지막 차원(runs)에서 평균
    mean_delay = mean(results_grid.mean_delay_ms, ndims(results_grid.mean_delay_ms), 'omitnan');
    std_delay = std(results_grid.mean_delay_ms, 0, ndims(results_grid.mean_delay_ms), 'omitnan');
    
    mean_collision = mean(results_grid.collision_rate, ndims(results_grid.collision_rate), 'omitnan');
    std_collision = std(results_grid.collision_rate, 0, ndims(results_grid.collision_rate), 'omitnan');
    
    mean_completion = mean(results_grid.completion_rate, ndims(results_grid.completion_rate), 'omitnan');
    std_completion = std(results_grid.completion_rate, 0, ndims(results_grid.completion_rate), 'omitnan');
    
    mean_throughput = mean(results_grid.throughput_mbps, ndims(results_grid.throughput_mbps), 'omitnan');
    std_throughput = std(results_grid.throughput_mbps, 0, ndims(results_grid.throughput_mbps), 'omitnan');
    
    %% =====================================================================
    %  2. 시각화
    %  =====================================================================
    
    fig = figure('Position', [100, 100, 1400, 400], 'Visible', 'off');
    
    if is_2d
        % 2D 스윕: Heatmap 사용
        
        subplot(1, 4, 1);
        imagesc(mean_delay');
        colorbar;
        xlabel(exp_config.sweep_var);
        ylabel(exp_config.sweep_var2);
        title('Mean Delay [ms]');
        set(gca, 'XTick', 1:length(exp_config.sweep_range), ...
            'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), exp_config.sweep_range, 'UniformOutput', false));
        set(gca, 'YTick', 1:length(exp_config.sweep_range2), ...
            'YTickLabel', arrayfun(@(x) sprintf('%.2f', x), exp_config.sweep_range2, 'UniformOutput', false));
        
        subplot(1, 4, 2);
        imagesc(mean_collision' * 100);
        colorbar;
        xlabel(exp_config.sweep_var);
        ylabel(exp_config.sweep_var2);
        title('Collision Rate [%]');
        set(gca, 'XTick', 1:length(exp_config.sweep_range), ...
            'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), exp_config.sweep_range, 'UniformOutput', false));
        set(gca, 'YTick', 1:length(exp_config.sweep_range2), ...
            'YTickLabel', arrayfun(@(x) sprintf('%.2f', x), exp_config.sweep_range2, 'UniformOutput', false));
        
        subplot(1, 4, 3);
        imagesc(mean_completion' * 100);
        colorbar;
        xlabel(exp_config.sweep_var);
        ylabel(exp_config.sweep_var2);
        title('Completion Rate [%]');
        set(gca, 'XTick', 1:length(exp_config.sweep_range), ...
            'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), exp_config.sweep_range, 'UniformOutput', false));
        set(gca, 'YTick', 1:length(exp_config.sweep_range2), ...
            'YTickLabel', arrayfun(@(x) sprintf('%.2f', x), exp_config.sweep_range2, 'UniformOutput', false));
        
        subplot(1, 4, 4);
        imagesc(mean_throughput');
        colorbar;
        xlabel(exp_config.sweep_var);
        ylabel(exp_config.sweep_var2);
        title('Throughput [Mbps]');
        set(gca, 'XTick', 1:length(exp_config.sweep_range), ...
            'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), exp_config.sweep_range, 'UniformOutput', false));
        set(gca, 'YTick', 1:length(exp_config.sweep_range2), ...
            'YTickLabel', arrayfun(@(x) sprintf('%.2f', x), exp_config.sweep_range2, 'UniformOutput', false));
        
    else
        % 1D 스윕: Line plot with error bars
        
        x_vals = exp_config.sweep_range;
        
        subplot(1, 4, 1);
        errorbar(x_vals, mean_delay, std_delay, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
        grid on;
        xlabel(exp_config.sweep_var);
        ylabel('Delay [ms]');
        title('Mean Delay');
        
        subplot(1, 4, 2);
        errorbar(x_vals, mean_collision * 100, std_collision * 100, 'r-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
        grid on;
        xlabel(exp_config.sweep_var);
        ylabel('Rate [%]');
        title('Collision Rate');
        
        subplot(1, 4, 3);
        errorbar(x_vals, mean_completion * 100, std_completion * 100, 'g-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
        hold on;
        yline(80, 'r--', 'Threshold');
        grid on;
        xlabel(exp_config.sweep_var);
        ylabel('Rate [%]');
        title('Completion Rate');
        ylim([0, 105]);
        
        subplot(1, 4, 4);
        errorbar(x_vals, mean_throughput, std_throughput, 'm-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'm');
        grid on;
        xlabel(exp_config.sweep_var);
        ylabel('Throughput [Mbps]');
        title('Throughput');
    end
    
    sgtitle(sprintf('Quick Check: %s', exp_config.name), 'FontSize', 14, 'FontWeight', 'bold');
    
    %% =====================================================================
    %  3. 저장
    %  =====================================================================
    
    plot_dir = 'results/quick_plots';
    if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
    
    plot_filename = sprintf('%s/%s_quick.png', plot_dir, exp_config.name);
    saveas(fig, plot_filename);
    close(fig);
    
    fprintf('  ✓ Quick Plot 저장: %s\n\n', plot_filename);
end