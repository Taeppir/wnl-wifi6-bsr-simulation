%% analyze_exp1_02_2d_map.m
% Experiment 1-2 분석: (L_cell, ρ) 2D 맵
%
% [최종 버전] summary는 항상 [n_L, n_rho] 2D matrix

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 1-2: 2D 맵 분석 (Line Plots)\n');
fprintf('========================================\n\n');

exp = load_experiment('exp1_2_2d_map');

% 데이터 추출
L_cell_range = exp.config.sweep_range;
rho_range = exp.config.sweep_range2;

n_L = length(L_cell_range);
n_rho = length(rho_range);

% ⭐ Summary는 무조건 [n_L, n_rho] 형태
mean_completion = exp.summary.mean.completion_rate;
mean_delay = exp.summary.mean.mean_delay_ms;
mean_collision = exp.summary.mean.collision_rate;
mean_buffer_empty = exp.summary.mean.buffer_empty_ratio;

std_completion = exp.summary.std.completion_rate;
std_delay = exp.summary.std.mean_delay_ms;
std_collision = exp.summary.std.collision_rate;
std_buffer_empty = exp.summary.std.buffer_empty_ratio;

fprintf('  [데이터 확인]\n');
fprintf('    n_L=%d, n_rho=%d\n', n_L, n_rho);
fprintf('    mean_completion 크기: %s\n', mat2str(size(mean_completion)));

% 크기 검증
expected_size = [n_L, n_rho];
if ~isequal(size(mean_completion), expected_size)
    error('Summary 크기(%s)가 예상(%s)과 다릅니다!', ...
        mat2str(size(mean_completion)), mat2str(expected_size));
end

%% =====================================================================
%  2. 시각화 (Line Plots)
%  =====================================================================

fprintf('\n[시각화 생성 중...]\n');

fig = figure('Position', [100, 100, 1600, 1000]);

% 색상 및 스타일
colors = {[0.0, 0.4, 0.7], [0.8, 0.4, 0.0], [0.0, 0.6, 0.5], [0.9, 0.2, 0.3]};
markers = {'o', 's', '^', 'd'};
line_styles = {'-', '--', '-.', ':'};

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: Completion Rate
% ─────────────────────────────────────────────────────────────────────
subplot(2, 2, 1);
hold on;

for j = 1:n_rho
    plot(L_cell_range, mean_completion(:, j) * 100, ...
        'Color', colors{mod(j-1, 4)+1}, ...
        'LineStyle', line_styles{mod(j-1, 4)+1}, ...
        'Marker', markers{mod(j-1, 4)+1}, ...
        'LineWidth', 2, 'MarkerSize', 8, ...
        'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end

yline(98, 'r--', '98%', 'LineWidth', 1.5);
yline(90, 'r-', '90%', 'LineWidth', 1.5);

grid on;
xlabel('L_{cell}', 'FontSize', 12);
ylabel('Completion Rate [%]', 'FontSize', 12);
title('Completion Rate', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southwest', 'FontSize', 10);
ylim([0, 105]);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: Mean Delay
% ─────────────────────────────────────────────────────────────────────
subplot(2, 2, 2);
hold on;

for j = 1:n_rho
    errorbar(L_cell_range, mean_delay(:, j), std_delay(:, j), ...
        'Color', colors{mod(j-1, 4)+1}, ...
        'LineStyle', line_styles{mod(j-1, 4)+1}, ...
        'Marker', markers{mod(j-1, 4)+1}, ...
        'LineWidth', 2, 'MarkerSize', 8, 'CapSize', 6, ...
        'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end

grid on;
xlabel('L_{cell}', 'FontSize', 12);
ylabel('Mean Delay [ms]', 'FontSize', 12);
title('Mean Delay', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: Collision Rate
% ─────────────────────────────────────────────────────────────────────
subplot(2, 2, 3);
hold on;

for j = 1:n_rho
    plot(L_cell_range, mean_collision(:, j) * 100, ...
        'Color', colors{mod(j-1, 4)+1}, ...
        'LineStyle', line_styles{mod(j-1, 4)+1}, ...
        'Marker', markers{mod(j-1, 4)+1}, ...
        'LineWidth', 2, 'MarkerSize', 8, ...
        'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end

grid on;
xlabel('L_{cell}', 'FontSize', 12);
ylabel('Collision Rate [%]', 'FontSize', 12);
title('Collision Rate', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 10);
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: Buffer Empty Ratio
% ─────────────────────────────────────────────────────────────────────
subplot(2, 2, 4);
hold on;

for j = 1:n_rho
    plot(L_cell_range, mean_buffer_empty(:, j) * 100, ...
        'Color', colors{mod(j-1, 4)+1}, ...
        'LineStyle', line_styles{mod(j-1, 4)+1}, ...
        'Marker', markers{mod(j-1, 4)+1}, ...
        'LineWidth', 2, 'MarkerSize', 8, ...
        'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end

grid on;
xlabel('L_{cell}', 'FontSize', 12);
ylabel('Buffer Empty [%]', 'FontSize', 12);
title('Buffer Empty Ratio', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 10);
hold off;

sgtitle('Exp 1-2: (L_{cell}, \rho) Analysis', 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  3. 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fig_filename = sprintf('%s/exp1_2_2d_map_analysis.png', fig_dir);
saveas(fig, fig_filename);
fprintf('  ✓ Figure 저장: %s\n', fig_filename);

fig_filename_pdf = sprintf('%s/exp1_2_2d_map_analysis.pdf', fig_dir);
exportgraphics(fig, fig_filename_pdf, 'ContentType', 'vector');
fprintf('  ✓ PDF 저장: %s\n', fig_filename_pdf);

%% =====================================================================
%  4. 통계 출력
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  결과 통계\n');
fprintf('========================================\n\n');

% 영역 분류
safe = mean_completion >= 0.98;
critical = (mean_completion >= 0.90) & (mean_completion < 0.98);
overload = mean_completion < 0.90;

fprintf('[조건별 상세]\n');
fprintf('%-10s | %-8s | %10s | %10s | %10s | %s\n', ...
    'L_cell', 'rho', 'Compl[%]', 'Delay[ms]', 'Coll[%]', 'Status');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:n_L
    for j = 1:n_rho
        if safe(i, j)
            status = '✓ Safe';
        elseif critical(i, j)
            status = '⚠ Critical';
        else
            status = '✗ Overload';
        end
        
        fprintf('%-10.1f | %-8.1f | %9.1f | %10.2f | %9.1f | %s\n', ...
            L_cell_range(i), rho_range(j), ...
            mean_completion(i,j)*100, mean_delay(i,j), ...
            mean_collision(i,j)*100, status);
    end
end

fprintf('\n========================================\n');
fprintf('  Phase 2 시나리오 추천\n');
fprintf('========================================\n\n');

if any(critical(:))
    [~, idx] = min(mean_completion(critical));
    critical_idx = find(critical);
    [i_c, j_c] = ind2sub([n_L, n_rho], critical_idx(idx));
    
    fprintf('[임계 부하 시나리오]\n');
    fprintf('  추천: L_cell=%.1f, ρ=%.1f\n', L_cell_range(i_c), rho_range(j_c));
    fprintf('  - Completion: %.1f%%\n', mean_completion(i_c, j_c)*100);
    fprintf('  - Delay: %.2f ms\n\n', mean_delay(i_c, j_c));
else
    fprintf('[임계 부하 시나리오] 없음\n\n');
end

fprintf('🎉 분석 완료!\n\n');