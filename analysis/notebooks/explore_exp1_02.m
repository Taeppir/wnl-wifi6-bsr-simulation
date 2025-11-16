%% explore_exp1_02.m
% Exp 1-2 빠른 탐색

clear; close all; clc;

%% 로드
exp = load_experiment('exp1_2_2d_map');

L_cell_range = exp.config.sweep_range;
rho_range = exp.config.sweep_range2;
n_L = length(L_cell_range);
n_rho = length(rho_range);

% Summary는 [n_L, n_rho] 형태
compl = exp.summary.mean.completion_rate;
delay = exp.summary.mean.mean_delay_ms;
coll = exp.summary.mean.collision_rate;

fprintf('\n========================================\n');
fprintf('  Exp 1-2 빠른 확인\n');
fprintf('========================================\n\n');

fprintf('Grid: %d L_cell × %d ρ = %d 조합\n', n_L, n_rho, n_L * n_rho);
fprintf('Data 크기: %s\n', mat2str(size(compl)));

fprintf('\n[통계]\n');
fprintf('  Completion: %.1f%% ~ %.1f%%\n', min(compl(:))*100, max(compl(:))*100);
fprintf('  Delay: %.2f ~ %.2f ms\n', min(delay(:)), max(delay(:)));
fprintf('  Collision: %.1f%% ~ %.1f%%\n', min(coll(:))*100, max(coll(:))*100);

%% 플롯
figure('Position', [100, 100, 1200, 400]);

colors = {[0.0, 0.4, 0.7], [0.8, 0.4, 0.0], [0.0, 0.6, 0.5], [0.9, 0.2, 0.3]};
markers = {'o', 's', '^', 'd'};

subplot(1, 3, 1);
hold on;
for j = 1:n_rho
    plot(L_cell_range, compl(:,j)*100, ...
        'Color', colors{mod(j-1,4)+1}, 'Marker', markers{mod(j-1,4)+1}, ...
        'LineWidth', 2, 'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end
yline(98, 'r--'); yline(90, 'r-');
grid on; xlabel('L_{cell}'); ylabel('Completion [%]');
title('Completion Rate'); legend('Location', 'best');
hold off;

subplot(1, 3, 2);
hold on;
for j = 1:n_rho
    plot(L_cell_range, delay(:,j), ...
        'Color', colors{mod(j-1,4)+1}, 'Marker', markers{mod(j-1,4)+1}, ...
        'LineWidth', 2, 'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end
grid on; xlabel('L_{cell}'); ylabel('Delay [ms]');
title('Mean Delay'); legend('Location', 'best');
hold off;

subplot(1, 3, 3);
hold on;
for j = 1:n_rho
    plot(L_cell_range, coll(:,j)*100, ...
        'Color', colors{mod(j-1,4)+1}, 'Marker', markers{mod(j-1,4)+1}, ...
        'LineWidth', 2, 'DisplayName', sprintf('\\rho=%.1f', rho_range(j)));
end
grid on; xlabel('L_{cell}'); ylabel('Collision [%]');
title('Collision Rate'); legend('Location', 'best');
hold off;

sgtitle('Exp 1-2', 'FontSize', 14, 'FontWeight', 'bold');

fprintf('\n');