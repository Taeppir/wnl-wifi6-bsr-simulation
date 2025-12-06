%% analyze_exp1_03_on_length_clean.m
% Experiment 1-3: ON-length(μ_on) 영향 분석 (가독성 개선 버전)
%
% - tiledlayout 사용해서 여백/정렬 개선
% - 공통 plot 함수로 코드 중복 제거
% - x축: 로그 스케일 + μ_on 값만 tick 표시
% - BSR bar plot: (μ_on별) explicit / implicit 총합으로 단순화

clear; close all; clc;

fprintf('========================================\n');
fprintf('  Exp 1-3: ON-length 영향 분석 (Clean)\n');
fprintf('========================================\n\n');

%% 1. 데이터 로드
exp = load_experiment('exp1_3_on_length_sweep');

mu_on_range   = exp.config.sweep_range;   % [n_mu, 1]
L_cell_range  = exp.config.sweep_range2;  % [1, n_L]

n_mu = length(mu_on_range);
n_L  = length(L_cell_range);

mean_delay        = exp.summary.mean.mean_delay_ms;
std_delay         = exp.summary.std.mean_delay_ms;
mean_uora_delay   = exp.summary.mean.mean_uora_delay_ms;
std_uora_delay    = exp.summary.std.mean_uora_delay_ms;

mean_explicit_bsr = exp.summary.mean.explicit_bsr_count;
std_explicit_bsr  = exp.summary.std.explicit_bsr_count;
mean_implicit_bsr = exp.summary.mean.implicit_bsr_count;
mean_implicit_ratio = exp.summary.mean.implicit_bsr_ratio;

mean_buffer_empty = exp.summary.mean.buffer_empty_ratio;
mean_collision    = exp.summary.mean.collision_rate;
mean_completion   = exp.summary.mean.completion_rate;

fprintf('  [데이터 확인] n_mu=%d, n_L=%d\n', n_mu, n_L);
fprintf('    μ_on  : %s\n', mat2str(mu_on_range));
fprintf('    L_cell: %s\n\n', mat2str(L_cell_range));

%% 2. 공통 스타일 정의

% 색 / 마커 / 라인스타일
base_colors = [
    0.0 0.4 0.7  ;  % 파랑
    0.8 0.4 0.0  ;  % 주황
    0.0 0.6 0.5  ;  % 청록
    0.9 0.2 0.3  ;  % 빨강
    0.5 0.2 0.6  ;  % 보라
];
markers     = {'o', 's', '^', 'd', 'v'};
line_styles = {'-', '--', '-.', ':', '-'};

% L_cell 개수만큼 자르기 / 늘리기
colors = base_colors;
if n_L > size(base_colors,1)
    colors = lines(n_L);
end
markers     = repmat(markers,     1, ceil(n_L/numel(markers)));
line_styles = repmat(line_styles, 1, ceil(n_L/numel(line_styles)));
markers     = markers(1:n_L);
line_styles = line_styles(1:n_L);

use_log_x = (max(mu_on_range) / min(mu_on_range) > 10);

% x축 tick을 μ_on 값 그대로 사용 (로그 스케일에서도 보이게)
x_ticks = mu_on_range;
x_tick_labels = arrayfun(@(x) sprintf('%.2g', x), mu_on_range, ...
                         'UniformOutput', false);

% ─ Helper: 에러바 라인 플롯 ─────────────────────────────────────────
plot_error_lines = @(ax, y_mean, y_std, y_label, ttl) ...
    local_plot_error_lines(ax, mu_on_range, L_cell_range, y_mean, y_std, ...
                           colors, markers, line_styles, ...
                           use_log_x, x_ticks, x_tick_labels, ...
                           y_label, ttl);

% ─ Helper: 단순 라인 플롯 ───────────────────────────────────────────
plot_lines = @(ax, y, y_label, ttl) ...
    local_plot_lines(ax, mu_on_range, L_cell_range, y, ...
                     colors, markers, line_styles, ...
                     use_log_x, x_ticks, x_tick_labels, ...
                     y_label, ttl);

%% 3. 시각화 (tiledlayout)

fig = figure('Position', [100, 100, 1700, 1100]);
t   = tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'Exp 1-3: ON-length(\mu_{on}) Analysis', ...
      'FontSize', 16, 'FontWeight', 'bold');

% (1) Mean Delay
ax1 = nexttile(t, 1);
plot_error_lines(ax1, mean_delay, std_delay, ...
    'Mean Delay [ms]', '평균 큐잉 지연');

% (2) UORA Delay
ax2 = nexttile(t, 2);
plot_error_lines(ax2, mean_uora_delay, std_uora_delay, ...
    'UORA Delay [ms]', 'UORA 지연');

% (3) Explicit BSR Count
ax3 = nexttile(t, 3);
plot_error_lines(ax3, mean_explicit_bsr, std_explicit_bsr, ...
    'Explicit BSR Count', 'Explicit BSR 발생 횟수');

% (4) Implicit BSR Count
ax4 = nexttile(t, 4);
plot_lines(ax4, mean_implicit_bsr, ...
    'Implicit BSR Count', 'Implicit BSR 발생 횟수');

% (5) Implicit BSR Ratio
ax5 = nexttile(t, 5);
plot_lines(ax5, mean_implicit_ratio * 100, ...
    'Implicit BSR Ratio [%]', 'Implicit BSR 비율');
ylim(ax5, [0, 100]);

% (6) Buffer Empty Ratio
ax6 = nexttile(t, 6);
plot_lines(ax6, mean_buffer_empty * 100, ...
    'Buffer Empty Ratio [%]', '버퍼 비어있음 비율');

% (7) Collision Rate
ax7 = nexttile(t, 7);
plot_lines(ax7, mean_collision * 100, ...
    'Collision Rate [%]', '충돌률');

% (8) BSR 구성 (μ_on별 총합 bar plot – 모든 L_cell 합산)
ax8 = nexttile(t, 8);
plot_bsr_bar(ax8, mu_on_range, mean_explicit_bsr, mean_implicit_bsr);

% (9) Completion Rate
ax9 = nexttile(t, 9);
plot_lines(ax9, mean_completion * 100, ...
    'Completion Rate [%]', '패킷 완료율');
yline(ax9, 98, 'r--', '98%', 'LineWidth', 1.2);
yline(ax9, 90, 'r-',  '90%', 'LineWidth', 1.2);
ylim(ax9, [85, 101]);

% 공통 legend (위쪽 서브플롯에 하나만)
lg = legend(ax1, 'Location', 'best');
lg.FontSize = 9;

%% 4. 저장

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

png_name = fullfile(fig_dir, 'exp1_3_on_length_analysis_clean.png');
pdf_name = fullfile(fig_dir, 'exp1_3_on_length_analysis_clean.pdf');

saveas(fig, png_name);
exportgraphics(fig, pdf_name, 'ContentType', 'vector');

fprintf('  ✓ Figure 저장: %s\n', png_name);
fprintf('  ✓ PDF 저장  : %s\n', pdf_name);

%% 5. 텍스트 통계 (표 형태 출력은 기존 코드 재사용 가능)
fprintf('\n========================================\n');
fprintf('  통계 요약 (지연/버퍼/BSR)\n');
fprintf('========================================\n\n');

for j = 1:n_L
    L_val = L_cell_range(j);
    fprintf('[L_cell = %.2f]\n', L_val);
    fprintf('%-10s | %10s | %10s | %10s | %10s | %12s\n', ...
        'μ_on[s]', 'Delay', 'UORA', 'ExpBSR', 'Impl[%]', 'BufEmpty[%]');
    fprintf('%s\n', repmat('-', 1, 78));
    for i = 1:n_mu
        fprintf('%-10.3g | %10.2f | %10.2f | %10.0f | %10.1f | %12.1f\n', ...
            mu_on_range(i), ...
            mean_delay(i, j), ...
            mean_uora_delay(i, j), ...
            mean_explicit_bsr(i, j), ...
            mean_implicit_ratio(i, j) * 100, ...
            mean_buffer_empty(i, j) * 100);
    end
    fprintf('\n');
end

fprintf('🎉 Exp 1-3 clean 분석 완료\n');

%% ─────────────────────────────────────────────────────────────────────
%  Local helper functions
% ─────────────────────────────────────────────────────────────────────

function local_plot_error_lines(ax, x, L_cell_range, y_mean, y_std, ...
    colors, markers, line_styles, use_log_x, x_ticks, x_tick_labels, ...
    y_label, ttl)

    axes(ax); hold(ax, 'on');
    n_L = length(L_cell_range);

    for j = 1:n_L
        errorbar(ax, x, y_mean(:, j), y_std(:, j), ...
            'Color',      colors(j, :), ...
            'LineStyle',  line_styles{j}, ...
            'Marker',     markers{j}, ...
            'LineWidth',  1.8, ...
            'MarkerSize', 7, ...
            'CapSize',    6, ...
            'DisplayName', sprintf('L_{cell}=%.2f', L_cell_range(j)));
    end

    if use_log_x
        set(ax, 'XScale', 'log');
    end
    set(ax, 'XTick', x_ticks, 'XTickLabel', x_tick_labels);

    grid(ax, 'on');
    xlabel(ax, '\mu_{on} [s]', 'FontSize', 11);
    ylabel(ax, y_label,       'FontSize', 11);
    title(ax, ttl,            'FontSize', 13, 'FontWeight', 'bold');
end

function local_plot_lines(ax, x, L_cell_range, y, ...
    colors, markers, line_styles, use_log_x, x_ticks, x_tick_labels, ...
    y_label, ttl)

    axes(ax); hold(ax, 'on');
    n_L = length(L_cell_range);

    for j = 1:n_L
        plot(ax, x, y(:, j), ...
            'Color',      colors(j, :), ...
            'LineStyle',  line_styles{j}, ...
            'Marker',     markers{j}, ...
            'LineWidth',  1.8, ...
            'MarkerSize', 7, ...
            'DisplayName', sprintf('L_{cell}=%.2f', L_cell_range(j)));
    end

    if use_log_x
        set(ax, 'XScale', 'log');
    end
    set(ax, 'XTick', x_ticks, 'XTickLabel', x_tick_labels);

    grid(ax, 'on');
    xlabel(ax, '\mu_{on} [s]', 'FontSize', 11);
    ylabel(ax, y_label,       'FontSize', 11);
    title(ax, ttl,            'FontSize', 13, 'FontWeight', 'bold');
end

function plot_bsr_bar(ax, mu_on_range, mean_explicit_bsr, mean_implicit_bsr)
    % μ_on별 explicit / implicit BSR 총합 (모든 L_cell 합산)
    axes(ax); hold(ax, 'on');

    exp_sum = sum(mean_explicit_bsr, 2);   % [n_mu, 1]
    imp_sum = sum(mean_implicit_bsr, 2);   % [n_mu, 1]

    bar_data = [exp_sum, imp_sum];
    b = bar(ax, 1:length(mu_on_range), bar_data, 'stacked');

    b(1).FaceColor = [0.9, 0.3, 0.3];  % Explicit
    b(2).FaceColor = [0.3, 0.6, 0.9];  % Implicit

    xticks(ax, 1:length(mu_on_range));
    xticklabels(ax, arrayfun(@(x) sprintf('%.2g', x), mu_on_range, ...
                             'UniformOutput', false));
    xlabel(ax, '\mu_{on} [s]', 'FontSize', 11);
    ylabel(ax, 'BSR Count (sum over L_{cell})', 'FontSize', 11);
    title(ax, 'BSR 구성 (μ_{on}별 합)', 'FontSize', 13, 'FontWeight', 'bold');
    grid(ax, 'on');
    legend(ax, {'Explicit', 'Implicit'}, 'Location', 'northwest', 'FontSize', 9);
end
