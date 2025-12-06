%% analyze_exp2_01_comparison_comprehensive.m
% Experiment 2-1: 정책 비교 - 종합 분석 (모든 지표)
%
% [특징]
%   - 수집된 모든 지표를 시각화
%   - 상세 통계 테이블
%   - 부하별 패턴 자동 분석

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 2-1: 종합 분석 (모든 지표)\n');
fprintf('========================================\n\n');

try
    exp = load_experiment('exp2_1_scheme_comparison');
catch ME
    fprintf('💥 [오류] 실험 결과를 찾을 수 없습니다.\n');
    fprintf('   먼저 exp2_01_scheme_comparison.m을 실행하세요.\n');
    rethrow(ME);
end

%% =====================================================================
%  2. 데이터 추출
%  =====================================================================

n_scenarios = length(exp.config.scenarios);
n_schemes = length(exp.config.schemes);

scenario_names = {exp.config.scenarios.name};
scheme_names = exp.config.scheme_names;

% 모든 지표 추출
metrics_to_plot = {
    'mean_delay_ms', 'Mean Delay [ms]', 'mean'
    'p90_delay_ms', 'P90 Delay [ms]', 'mean'
    'p99_delay_ms', 'P99 Delay [ms]', 'mean'
    'mean_uora_delay_ms', 'UORA Delay [ms]', 'mean'
    'mean_sched_delay_ms', 'Sched Delay [ms]', 'mean'
    'mean_frag_delay_ms', 'Frag Delay [ms]', 'mean'
    'mean_overhead_delay_ms', 'Overhead Delay [ms]', 'mean'
    'collision_rate', 'Collision Rate [%]', 'pct'
    'success_rate', 'Success Rate [%]', 'pct'
    'explicit_bsr_count', 'Explicit BSR Count', 'count'
    'implicit_bsr_count', 'Implicit BSR Count', 'count'
    'implicit_bsr_ratio', 'Implicit BSR Ratio [%]', 'pct'
    'buffer_empty_ratio', 'Buffer Empty [%]', 'pct'
    'throughput_mbps', 'Throughput [Mbps]', 'mean'
    'channel_utilization', 'Channel Util [%]', 'pct'
    'completion_rate', 'Completion Rate [%]', 'pct'
    'jain_index', 'Jain Index', 'mean'
};

fprintf('  데이터 로드 완료: %d 시나리오 × %d 스킴\n', n_scenarios, n_schemes);
fprintf('  총 %d개 지표 분석\n\n', size(metrics_to_plot, 1));

%% =====================================================================
%  3. Figure 1: 핵심 지표 대시보드 (3×3 grid)
%  =====================================================================

fprintf('  [Figure 1] 핵심 지표 대시보드 생성 중...\n');

fig1 = figure('Position', [50, 50, 2000, 1200]);
t1 = tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

colors = [
    [0.6, 0.6, 0.6];   % Baseline: 회색
    [0.0, 0.4, 0.7];   % Scheme 1: 파랑
    [0.8, 0.4, 0.0];   % Scheme 2: 주황
    [0.0, 0.6, 0.5]    % Scheme 3: 청록
];
markers = {'-o', '--s', '-.^', ':d'};

% 핵심 9개 지표 선택
core_metrics = {
    'mean_delay_ms', 'p90_delay_ms', 'p99_delay_ms'
    'collision_rate', 'explicit_bsr_count', 'implicit_bsr_ratio'
    'buffer_empty_ratio', 'throughput_mbps', 'completion_rate'
};

for idx = 1:9
    ax = nexttile(t1, idx);
    hold(ax, 'on');
    
    metric_name = core_metrics{idx};
    
    % 데이터 추출
    if isfield(exp.summary.mean, metric_name)
        data = exp.summary.mean.(metric_name);
        std_data = exp.summary.std.(metric_name);
        
        % Percentage 변환
        metric_info = metrics_to_plot(strcmp(metrics_to_plot(:,1), metric_name), :);
        if strcmp(metric_info{3}, 'pct')
            data = data * 100;
            std_data = std_data * 100;
        end
        
        % Line plot with error bars
        for sc = 1:n_schemes
            errorbar(ax, 1:n_scenarios, data(:, sc), std_data(:, sc), ...
                markers{sc}, 'Color', colors(sc,:), 'LineWidth', 2, ...
                'MarkerFaceColor', colors(sc,:), 'MarkerSize', 8, 'CapSize', 8, ...
                'DisplayName', scheme_names{sc});
        end
        
        set(ax, 'XTick', 1:n_scenarios, 'XTickLabel', scenario_names);
        ylabel(ax, metric_info{2});
        title(ax, metric_info{2}, 'FontWeight', 'bold');
        grid(ax, 'on');
        
        % Legend on first subplot only
        if idx == 1
            legend(ax, 'Location', 'northwest');
        end
    end
    hold(ax, 'off');
end

sgtitle(t1, 'Exp 2-1: 핵심 성능 지표 종합', 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  4. Figure 2: 지연 분포 상세 (P50/P90/P99)
%  =====================================================================

fprintf('  [Figure 2] 지연 분포 분석 생성 중...\n');

fig2 = figure('Position', [100, 50, 1600, 500]);
t2 = tiledlayout(1, n_scenarios, 'TileSpacing', 'compact', 'Padding', 'compact');

delay_percentiles = {'mean_delay_ms', 'p90_delay_ms', 'p99_delay_ms'};
delay_labels = {'Mean', 'P90', 'P99'};

for s = 1:n_scenarios
    ax = nexttile(t2, s);
    
    % Extract delay data
    data_matrix = zeros(n_schemes, 3);
    for i = 1:3
        data_matrix(:, i) = exp.summary.mean.(delay_percentiles{i})(s, :);
    end
    
    % Grouped bar
    b = bar(ax, data_matrix);
    for i = 1:3
        b(i).FaceColor = [0.2, 0.4, 0.8-i*0.2];
    end
    
    set(ax, 'XTickLabel', scheme_names, 'XTickLabelRotation', 15);
    ylabel(ax, 'Delay [ms]');
    title(ax, sprintf('%s Scenario', scenario_names{s}), 'FontWeight', 'bold');
    legend(ax, delay_labels, 'Location', 'northwest');
    grid(ax, 'on');
end

sgtitle(t2, 'Exp 2-1: 지연 분포 상세 분석', 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  5. Figure 3: BSR 상세 분석
%  =====================================================================

fprintf('  [Figure 3] BSR 분석 생성 중...\n');

fig3 = figure('Position', [150, 50, 1600, 800]);
t3 = tiledlayout(2, n_scenarios, 'TileSpacing', 'compact', 'Padding', 'compact');

for s = 1:n_scenarios
    % Subplot 1: Explicit vs Implicit BSR (Stacked)
    ax1 = nexttile(t3, s);
    
    explicit_data = exp.summary.mean.explicit_bsr_count(s, :);
    implicit_data = exp.summary.mean.implicit_bsr_count(s, :);
    
    bar_data = [explicit_data', implicit_data'];
    b = bar(ax1, bar_data, 'stacked');
    b(1).FaceColor = [0.9, 0.3, 0.3];  % Explicit: red
    b(2).FaceColor = [0.3, 0.6, 0.9];  % Implicit: blue
    
    set(ax1, 'XTickLabel', scheme_names, 'XTickLabelRotation', 15);
    ylabel(ax1, 'BSR Count');
    title(ax1, sprintf('%s: BSR Breakdown', scenario_names{s}), 'FontWeight', 'bold');
    legend(ax1, {'Explicit', 'Implicit'}, 'Location', 'northwest');
    grid(ax1, 'on');
    
    % Subplot 2: Buffer Empty Ratio
    ax2 = nexttile(t3, s + n_scenarios);
    
    buffer_empty = exp.summary.mean.buffer_empty_ratio(s, :) * 100;
    
    bar(ax2, buffer_empty, 'FaceColor', [0.5, 0.5, 0.5]);
    yline(ax2, 30, 'r--', 'LineWidth', 1.5);
    
    set(ax2, 'XTickLabel', scheme_names, 'XTickLabelRotation', 15);
    ylabel(ax2, 'Buffer Empty [%]');
    title(ax2, sprintf('%s: Buffer Empty Ratio', scenario_names{s}), 'FontWeight', 'bold');
    ylim(ax2, [0, 100]);
    grid(ax2, 'on');
end

sgtitle(t3, 'Exp 2-1: BSR 상세 분석', 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  6. Figure 4: 지연 분해
%  =====================================================================

fprintf('  [Figure 4] 지연 분해 그래프 생성 중...\n');

fig4 = figure('Position', [200, 50, 1600, 600]);
t4 = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

mean_uora_delay = exp.summary.mean.mean_uora_delay_ms;
mean_sched_delay = exp.summary.mean.mean_sched_delay_ms;
mean_overhead_delay = exp.summary.mean.mean_overhead_delay_ms;
mean_frag_delay = exp.summary.mean.mean_frag_delay_ms;
mean_delay_total = exp.summary.mean.mean_delay_ms;

stack_data = cat(3, mean_uora_delay, mean_sched_delay, ...
    mean_overhead_delay, mean_frag_delay);

legend_labels = {'T_{uora}', 'T_{sched}', 'T_{overhead}', 'T_{frag}'};
stack_colors = [
    [0.9, 0.5, 0.2];  % UORA: 주황
    [0.2, 0.5, 0.9];  % Sched: 파랑
    [0.7, 0.7, 0.7];  % Overhead: 회색
    [0.5, 0.3, 0.7]   % Frag: 보라
];

for s = 1:n_scenarios
    ax = nexttile(t4, s);
    
    data_scenario = squeeze(stack_data(s, :, :));
    b_stack = bar(ax, data_scenario, 'stacked');
    
    for k = 1:length(legend_labels)
        b_stack(k).FaceColor = stack_colors(k, :);
    end
    
    hold on;
    % ⭐ Line 객체를 명시적으로 저장
    h_line = plot(ax, 1:n_schemes, mean_delay_total(s, :), ...
        'r-o', 'LineWidth', 2.5, 'MarkerFaceColor', 'r');
    hold off;
    
    set(ax, 'XTick', 1:n_schemes, 'XTickLabel', scheme_names, ...
        'XTickLabelRotation', 15);
    ylabel(ax, 'Delay [ms]');
    title(ax, sprintf('Scenario: %s', scenario_names{s}), 'FontWeight', 'bold');
    grid(ax, 'on');
    
    % ⭐ Legend 수정 (마지막 subplot에만)
    if s == n_scenarios
        legend(ax, [b_stack, h_line], ...
            [legend_labels, {'D_{total}'}], 'Location', 'eastoutside');
    end
end

sgtitle(t4, 'Exp 2-1: 지연 분해 분석', 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  7. 상세 통계 테이블 (콘솔)
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  상세 통계 테이블\n');
fprintf('========================================\n\n');

% 모든 지표에 대해 테이블 출력
for s = 1:n_scenarios
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    fprintf(' Scenario: %s (L_cell=%.2f)\n', ...
        scenario_names{s}, exp.config.scenarios(s).L_cell);
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');
    
    % 지연 지표
    fprintf('[지연 지표]\n');
    fprintf('%-25s | %10s | %10s | %10s | %10s\n', ...
        'Metric', 'Baseline', 'Scheme 1', 'Scheme 2', 'Scheme 3');
    fprintf('%s\n', repmat('-', 1, 80));
    
    delay_metrics = {
        'mean_delay_ms', 'Mean Delay [ms]'
        'p90_delay_ms', 'P90 Delay [ms]'
        'p99_delay_ms', 'P99 Delay [ms]'
        'mean_uora_delay_ms', 'UORA Delay [ms]'
        'mean_sched_delay_ms', 'Sched Delay [ms]'
        'mean_frag_delay_ms', 'Frag Delay [ms]'
    };
    
    for i = 1:size(delay_metrics, 1)
        metric = delay_metrics{i, 1};
        label = delay_metrics{i, 2};
        data = exp.summary.mean.(metric)(s, :);
        
        fprintf('%-25s | %10.2f | %10.2f | %10.2f | %10.2f\n', ...
            label, data(1), data(2), data(3), data(4));
    end
    
    % BSR 지표
    fprintf('\n[BSR 지표]\n');
    fprintf('%-25s | %10s | %10s | %10s | %10s\n', ...
        'Metric', 'Baseline', 'Scheme 1', 'Scheme 2', 'Scheme 3');
    fprintf('%s\n', repmat('-', 1, 80));
    
    bsr_metrics = {
        'explicit_bsr_count', 'Explicit BSR [count]'
        'implicit_bsr_count', 'Implicit BSR [count]'
        'implicit_bsr_ratio', 'Implicit Ratio [%]'
        'buffer_empty_ratio', 'Buffer Empty [%]'
    };
    
    for i = 1:size(bsr_metrics, 1)
        metric = bsr_metrics{i, 1};
        label = bsr_metrics{i, 2};
        data = exp.summary.mean.(metric)(s, :);
        
        if contains(label, '[%]')
            data = data * 100;
            fprintf('%-25s | %10.1f | %10.1f | %10.1f | %10.1f\n', ...
                label, data(1), data(2), data(3), data(4));
        else
            fprintf('%-25s | %10.0f | %10.0f | %10.0f | %10.0f\n', ...
                label, data(1), data(2), data(3), data(4));
        end
    end
    
    % 네트워크 지표
    fprintf('\n[네트워크 지표]\n');
    fprintf('%-25s | %10s | %10s | %10s | %10s\n', ...
        'Metric', 'Baseline', 'Scheme 1', 'Scheme 2', 'Scheme 3');
    fprintf('%s\n', repmat('-', 1, 80));
    
    net_metrics = {
        'collision_rate', 'Collision Rate [%]'
        'throughput_mbps', 'Throughput [Mbps]'
        'completion_rate', 'Completion [%]'
        'jain_index', 'Jain Index'
    };
    
    for i = 1:size(net_metrics, 1)
        metric = net_metrics{i, 1};
        label = net_metrics{i, 2};
        data = exp.summary.mean.(metric)(s, :);
        
        if contains(label, '[%]')
            data = data * 100;
            fprintf('%-25s | %10.1f | %10.1f | %10.1f | %10.1f\n', ...
                label, data(1), data(2), data(3), data(4));
        else
            fprintf('%-25s | %10.2f | %10.2f | %10.2f | %10.2f\n', ...
                label, data(1), data(2), data(3), data(4));
        end
    end
    
    fprintf('\n');
end

%% =====================================================================
%  8. 개선률 요약
%  =====================================================================

fprintf('========================================\n');
fprintf('  개선률 요약 (Baseline 대비)\n');
fprintf('========================================\n\n');

baseline_idx = 1;

for s = 1:n_scenarios
    fprintf('[%s Scenario]\n', scenario_names{s});
    fprintf('%-25s | %12s | %12s | %12s\n', ...
        'Metric', 'Scheme 1', 'Scheme 2', 'Scheme 3');
    fprintf('%s\n', repmat('-', 1, 70));
    
    % 핵심 지표만
    key_metrics = {
        'mean_delay_ms', 'Delay'
        'collision_rate', 'Collision'
        'explicit_bsr_count', 'Explicit BSR'
    };
    
    for i = 1:size(key_metrics, 1)
        metric = key_metrics{i, 1};
        label = key_metrics{i, 2};
        
        baseline = exp.summary.mean.(metric)(s, baseline_idx);
        
        reductions = zeros(1, 3);
        for sc = 2:n_schemes
            reductions(sc-1) = (1 - exp.summary.mean.(metric)(s, sc) / baseline) * 100;
        end
        
        fprintf('%-25s | %11.1f%% | %11.1f%% | %11.1f%%\n', ...
            label, reductions(1), reductions(2), reductions(3));
    end
    fprintf('\n');
end

%% =====================================================================
%  9. 결과 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

figures = {fig1, fig2, fig3, fig4};
fig_names = {
    'exp2_1_comprehensive_dashboard'
    'exp2_1_delay_distribution'
    'exp2_1_bsr_analysis'
    'exp2_1_delay_decomposition'
};

fprintf('========================================\n');
fprintf('  Figure 저장 중...\n');
fprintf('========================================\n\n');

for i = 1:length(figures)
    png_file = sprintf('%s/%s.png', fig_dir, fig_names{i});
    pdf_file = sprintf('%s/%s.pdf', fig_dir, fig_names{i});
    
    saveas(figures{i}, png_file);
    exportgraphics(figures{i}, pdf_file, 'ContentType', 'vector');
    
    fprintf('  ✓ Figure %d 저장: %s\n', i, fig_names{i});
end

fprintf('\n🎉 종합 분석 완료!\n');
fprintf('   총 %d개 Figure 생성\n', length(figures));
fprintf('   - 17개 지표 시각화\n');
fprintf('   - 상세 통계 테이블\n\n');