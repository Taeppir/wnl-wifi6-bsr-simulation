%% analyze_exp1_02_extended.m
% Experiment 1-2 확장 분석: Throughput & BSR Counts
%
% 기본 분석(analyze_exp1_02_2d_map.m) 이후 추가로 실행

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 1-2: 확장 분석 (Throughput & BSR)\n');
fprintf('========================================\n\n');

exp = load_experiment('exp1_2_2d_map');

% 데이터 추출
L_cell_range = exp.config.sweep_range;
rho_range = exp.config.sweep_range2;

n_L = length(L_cell_range);
n_rho = length(rho_range);

% Summary
mean_throughput = exp.summary.mean.throughput_mbps;
mean_channel_util = exp.summary.mean.channel_utilization;
mean_explicit_bsr = exp.summary.mean.explicit_bsr_count;
mean_implicit_bsr = exp.summary.mean.implicit_bsr_count;
mean_implicit_ratio = exp.summary.mean.implicit_bsr_ratio;

% Std
std_throughput = exp.summary.std.throughput_mbps;
std_explicit_bsr = exp.summary.std.explicit_bsr_count;
std_implicit_bsr = exp.summary.std.implicit_bsr_count;

fprintf('  [데이터 확인] 크기: %s\n', mat2str(size(mean_throughput)));

%% =====================================================================
%  2. 시각화 (6-subplot)
%  =====================================================================

fprintf('[시각화 생성 중...]\n');

fig = figure('Position', [100, 100, 1600, 1200]);

% 색상 및 스타일
colors = {[0.0, 0.4, 0.7], [0.8, 0.4, 0.0], [0.0, 0.6, 0.5], [0.9, 0.2, 0.3]};
markers = {'o', 's', '^', 'd'};
line_styles = {'-', '--', '-.', ':'};

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: Throughput
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 1);
hold on;

for j = 1:n_rho
    errorbar(L_cell_range, mean_throughput(:, j), std_throughput(:, j), ...
        'Color', colors{mod(j-1, 4)+1}, ...
        'LineStyle', line_styles{mod(j-1, 4)+1}, ...
        'Marker', markers{mod(j-1, 4)+1}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'CapSize', 6, ...
        'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end

grid on;
xlabel('L_{cell}', 'FontSize', 12);
ylabel('Throughput [Mbps]', 'FontSize', 12);
title('System Throughput', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: Channel Utilization
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 2);
hold on;

for j = 1:n_rho
    plot(L_cell_range, mean_channel_util(:, j) * 100, ...
        'Color', colors{mod(j-1, 4)+1}, ...
        'LineStyle', line_styles{mod(j-1, 4)+1}, ...
        'Marker', markers{mod(j-1, 4)+1}, ...
        'LineWidth', 2, 'MarkerSize', 8, ...
        'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end

grid on;
xlabel('L_{cell}', 'FontSize', 12);
ylabel('Channel Utilization [%]', 'FontSize', 12);
title('Channel Utilization', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: Explicit BSR Count
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 3);
hold on;

for j = 1:n_rho
    errorbar(L_cell_range, mean_explicit_bsr(:, j), std_explicit_bsr(:, j), ...
        'Color', colors{mod(j-1, 4)+1}, ...
        'LineStyle', line_styles{mod(j-1, 4)+1}, ...
        'Marker', markers{mod(j-1, 4)+1}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'CapSize', 6, ...
        'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end

grid on;
xlabel('L_{cell}', 'FontSize', 12);
ylabel('Explicit BSR Count', 'FontSize', 12);
title('Explicit BSR (RA-RU 경쟁)', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: Implicit BSR Count
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 4);
hold on;

for j = 1:n_rho
    errorbar(L_cell_range, mean_implicit_bsr(:, j), std_implicit_bsr(:, j), ...
        'Color', colors{mod(j-1, 4)+1}, ...
        'LineStyle', line_styles{mod(j-1, 4)+1}, ...
        'Marker', markers{mod(j-1, 4)+1}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'CapSize', 6, ...
        'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end

grid on;
xlabel('L_{cell}', 'FontSize', 12);
ylabel('Implicit BSR Count', 'FontSize', 12);
title('Implicit BSR (Piggyback)', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 5: Implicit BSR Ratio
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 5);
hold on;

for j = 1:n_rho
    plot(L_cell_range, mean_implicit_ratio(:, j) * 100, ...
        'Color', colors{mod(j-1, 4)+1}, ...
        'LineStyle', line_styles{mod(j-1, 4)+1}, ...
        'Marker', markers{mod(j-1, 4)+1}, ...
        'LineWidth', 2, 'MarkerSize', 8, ...
        'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end

grid on;
xlabel('L_{cell}', 'FontSize', 12);
ylabel('Implicit BSR Ratio [%]', 'FontSize', 12);
title('Implicit BSR Ratio', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
ylim([0, 100]);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 6: Total BSR Count (Stacked Bar - 대표 케이스만)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 6);

% L_cell별로 ρ=0.5 케이스만 표시 (예시)
if n_rho >= 2
    rho_idx = 2;  % ρ=0.5 (두 번째)
    
    bar_data = [mean_explicit_bsr(:, rho_idx), mean_implicit_bsr(:, rho_idx)];
    b = bar(bar_data, 'stacked');
    
    b(1).FaceColor = [0.9, 0.3, 0.3];  % Explicit: 빨강
    b(2).FaceColor = [0.3, 0.6, 0.9];  % Implicit: 파랑
    
    set(gca, 'XTickLabel', arrayfun(@(x) sprintf('%.1f', x), L_cell_range, 'UniformOutput', false));
    
    grid on;
    xlabel('L_{cell}', 'FontSize', 12);
    ylabel('BSR Count', 'FontSize', 12);
    title(sprintf('BSR Breakdown (\\rho=%.1f)', rho_range(rho_idx)), ...
        'FontSize', 14, 'FontWeight', 'bold');
    legend({'Explicit BSR', 'Implicit BSR'}, 'Location', 'northwest');
else
    text(0.5, 0.5, 'N/A', 'HorizontalAlignment', 'center');
end

% ─────────────────────────────────────────────────────────────────────
% 전체 제목
% ─────────────────────────────────────────────────────────────────────
sgtitle('Exp 1-2: Throughput & BSR Analysis', 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  3. 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fig_filename = sprintf('%s/exp1_2_extended_analysis.png', fig_dir);
saveas(fig, fig_filename);
fprintf('  ✓ Figure 저장: %s\n', fig_filename);

fig_filename_pdf = sprintf('%s/exp1_2_extended_analysis.pdf', fig_dir);
exportgraphics(fig, fig_filename_pdf, 'ContentType', 'vector');
fprintf('  ✓ PDF 저장: %s\n', fig_filename_pdf);

%% =====================================================================
%  4. 통계 분석
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  Throughput & BSR 통계\n');
fprintf('========================================\n\n');

fprintf('[조건별 상세]\n');
fprintf('%-10s | %-8s | %10s | %12s | %12s | %10s\n', ...
    'L_cell', 'rho', 'Tput[Mbps]', 'Exp_BSR', 'Imp_BSR', 'Imp_Ratio[%]');
fprintf('%s\n', repmat('-', 1, 80));

for i = 1:n_L
    for j = 1:n_rho
        fprintf('%-10.1f | %-8.1f | %10.2f | %12.0f | %12.0f | %10.1f\n', ...
            L_cell_range(i), rho_range(j), ...
            mean_throughput(i,j), ...
            mean_explicit_bsr(i,j), ...
            mean_implicit_bsr(i,j), ...
            mean_implicit_ratio(i,j)*100);
    end
    if i < n_L
        fprintf('%s\n', repmat('-', 1, 80));
    end
end

%% =====================================================================
%  5. ρ 영향 분석 (BSR 중심)
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  ρ 영향 분석 (BSR)\n');
fprintf('========================================\n\n');

fprintf('[Observation]\n');

% L_cell 고정 시 ρ 변화 효과
fprintf('  1. L_cell 고정 시 ρ 증가 효과 (Explicit BSR):\n');
for i = 1:n_L
    exp_bsr_min = min(mean_explicit_bsr(i,:));
    exp_bsr_max = max(mean_explicit_bsr(i,:));
    exp_bsr_change = exp_bsr_max - exp_bsr_min;
    
    fprintf('     L_cell=%.1f: %.0f → %.0f (변화: +%.0f)\n', ...
        L_cell_range(i), exp_bsr_min, exp_bsr_max, exp_bsr_change);
end

fprintf('\n  2. ρ가 클수록 (burst가 심할수록):\n');
% ρ 최소 vs 최대 비교
if n_rho >= 2
    rho_min_idx = 1;
    rho_max_idx = n_rho;
    
    fprintf('     [Explicit BSR 변화]\n');
    for i = 1:n_L
        change_pct = (mean_explicit_bsr(i, rho_max_idx) / mean_explicit_bsr(i, rho_min_idx) - 1) * 100;
        fprintf('       L=%.1f: %.0f%% %s\n', ...
            L_cell_range(i), abs(change_pct), ...
            ternary(change_pct > 0, '증가', '감소'));
    end
    
    fprintf('\n     [Implicit BSR 변화]\n');
    for i = 1:n_L
        change_pct = (mean_implicit_bsr(i, rho_max_idx) / mean_implicit_bsr(i, rho_min_idx) - 1) * 100;
        fprintf('       L=%.1f: %.0f%% %s\n', ...
            L_cell_range(i), abs(change_pct), ...
            ternary(change_pct > 0, '증가', '감소'));
    end
end

fprintf('\n🎉 확장 분석 완료!\n\n');

%% =====================================================================
%  Helper Functions
%  =====================================================================

function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end