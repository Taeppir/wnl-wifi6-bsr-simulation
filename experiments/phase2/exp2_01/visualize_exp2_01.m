%% visualize_exp2_01.m
% Exp 2-1 결과 시각화 (subplot 통합 버전)
%
% 특징:
%   - Line plot으로 추이 비교
%   - 2x2 subplot 구성
%   - Legend가 그래프를 가리지 않음

function visualize_exp2_01(results)
    
    % 데이터 추출
    exp_config = results.config;
    n_scenarios = length(exp_config.scenarios);
    n_schemes = length(exp_config.schemes);
    
    scenario_names = {exp_config.scenarios.name};
    scheme_names_short = {'v0 (Baseline)', 'v1 (Fixed)', 'v2 (Prop)', 'v3 (EMA)'};
    
    % 메트릭 추출
    mean_delay = results.summary.mean.mean_delay_ms;
    std_delay = results.summary.mean.std_delay_ms;
    mean_uora = results.summary.mean.mean_uora_delay_ms;
    mean_explicit = results.summary.mean.explicit_bsr_count;
    
    % 색상 및 마커 설정
    colors = [0.5 0.5 0.5;    % v0: 회색
              0.9 0.3 0.3;    % v1: 빨강
              0.3 0.7 0.3;    % v2: 초록
              0.3 0.3 0.9];   % v3: 파랑
    markers = {'o', 's', '^', 'd'};
    
    %% =====================================================================
    %  Figure: 2x2 subplot
    %  =====================================================================
    
    fig = figure('Position', [100, 100, 1000, 700], 'Name', 'Exp 2-1: 기법 비교');
    
    x = 1:n_scenarios;
    
    % Subplot 1: 평균 지연
    subplot(2, 2, 1);
    hold on;
    for sc = 1:n_schemes
        plot(x, mean_delay(:, sc), '-', ...
            'Color', colors(sc, :), ...
            'Marker', markers{sc}, ...
            'MarkerFaceColor', colors(sc, :), ...
            'MarkerSize', 10, ...
            'LineWidth', 2);
    end
    hold off;
    set(gca, 'XTick', x, 'XTickLabel', scenario_names, 'FontSize', 11);
    xlabel('시나리오', 'FontSize', 12);
    ylabel('Mean Delay [ms]', 'FontSize', 12);
    title('평균 큐잉 지연', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    xlim([0.5, n_scenarios + 0.5]);
    
    % Subplot 2: 지연 분산
    subplot(2, 2, 2);
    hold on;
    for sc = 1:n_schemes
        plot(x, std_delay(:, sc), '-', ...
            'Color', colors(sc, :), ...
            'Marker', markers{sc}, ...
            'MarkerFaceColor', colors(sc, :), ...
            'MarkerSize', 10, ...
            'LineWidth', 2);
    end
    hold off;
    set(gca, 'XTick', x, 'XTickLabel', scenario_names, 'FontSize', 11);
    xlabel('시나리오', 'FontSize', 12);
    ylabel('Delay Std [ms]', 'FontSize', 12);
    title('지연 분산', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    xlim([0.5, n_scenarios + 0.5]);
    
    % Subplot 3: T_uora
    subplot(2, 2, 3);
    hold on;
    for sc = 1:n_schemes
        plot(x, mean_uora(:, sc), '-', ...
            'Color', colors(sc, :), ...
            'Marker', markers{sc}, ...
            'MarkerFaceColor', colors(sc, :), ...
            'MarkerSize', 10, ...
            'LineWidth', 2);
    end
    hold off;
    set(gca, 'XTick', x, 'XTickLabel', scenario_names, 'FontSize', 11);
    xlabel('시나리오', 'FontSize', 12);
    ylabel('T_{uora} [ms]', 'FontSize', 12);
    title('UORA 지연', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    xlim([0.5, n_scenarios + 0.5]);
    
    % Subplot 4: Explicit BSR
    subplot(2, 2, 4);
    hold on;
    for sc = 1:n_schemes
        plot(x, mean_explicit(:, sc), '-', ...
            'Color', colors(sc, :), ...
            'Marker', markers{sc}, ...
            'MarkerFaceColor', colors(sc, :), ...
            'MarkerSize', 10, ...
            'LineWidth', 2);
    end
    hold off;
    set(gca, 'XTick', x, 'XTickLabel', scenario_names, 'FontSize', 11);
    xlabel('시나리오', 'FontSize', 12);
    ylabel('Count', 'FontSize', 12);
    title('Explicit BSR 발생 횟수', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    xlim([0.5, n_scenarios + 0.5]);
    
    % 공통 Legend (Figure 하단)
    lgd = legend(scheme_names_short, 'Orientation', 'horizontal', 'Location', 'southoutside');
    lgd.Position = [0.25, 0.01, 0.5, 0.04];
    
    sgtitle('Exp 2-1: 기법별 성능 비교 (rho=0.5, mu_{on}=0.05)', 'FontSize', 16, 'FontWeight', 'bold');
    
    %% =====================================================================
    %  저장
    %  =====================================================================
    
    plot_dir = 'results/figures';
    if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
    
    saveas(fig, sprintf('%s/exp2_01_comparison.png', plot_dir));
    saveas(fig, sprintf('%s/exp2_01_comparison.pdf', plot_dir));
    
    fprintf('  ✓ Figure 저장 완료\n');
    fprintf('    - %s/exp2_01_comparison.png\n', plot_dir);
    fprintf('    - %s/exp2_01_comparison.pdf\n', plot_dir);
    
end