%% explore_exp1_03.m
% Exp 1-3 빠른 탐색 (Notebook 스타일)

clear; close all; clc;

%% 로드
exp = load_experiment('exp1_3_on_length_sweep');

%% 데이터 추출
mu_on = exp.config.sweep_range;
L_cell = exp.config.sweep_range2;

n_mu = length(mu_on);
n_L = length(L_cell);

% Summary [n_mu, n_L]
delay = exp.summary.mean.mean_delay_ms;
uora_delay = exp.summary.mean.mean_uora_delay_ms;
explicit_bsr = exp.summary.mean.explicit_bsr_count;
implicit_ratio = exp.summary.mean.implicit_bsr_ratio;
buffer_empty = exp.summary.mean.buffer_empty_ratio;
collision = exp.summary.mean.collision_rate;
completion = exp.summary.mean.completion_rate;

%% 빠른 확인
fprintf('\n========================================\n');
fprintf('  Exp 1-3 빠른 확인\n');
fprintf('========================================\n\n');

fprintf('Grid: %d μ_on × %d L_cell = %d 조합\n', n_mu, n_L, n_mu * n_L);
fprintf('Data 크기: %s\n\n', mat2str(size(delay)));

%% L_cell별로 출력
for j = 1:n_L
    fprintf('[L_cell = %.2f]\n', L_cell(j));
    fprintf('%-10s | %8s | %8s | %10s | %8s | %8s\n', ...
        'μ_on', 'Delay', 'UORA', 'Exp_BSR', 'Impl.', 'BufEmpty');
    fprintf('%s\n', repmat('-', 1, 70));

    for i = 1:n_mu
        fprintf('%-10.2f | %8.2f | %8.2f | %10.0f | %7.1f%% | %7.1f%%\n', ...
            mu_on(i), ...
            delay(i, j), ...
            uora_delay(i, j), ...
            explicit_bsr(i, j), ...
            implicit_ratio(i, j) * 100, ...
            buffer_empty(i, j) * 100);
    end
    
    fprintf('\n');
end

%% 통계
fprintf('[통계]\n');
fprintf('  Delay 범위: %.2f ~ %.2f ms\n', min(delay(:)), max(delay(:)));
fprintf('  Explicit BSR 범위: %.0f ~ %.0f회\n', ...
    min(explicit_bsr(:)), max(explicit_bsr(:)));
fprintf('  Buffer Empty 범위: %.1f%% ~ %.1f%%\n', ...
    min(buffer_empty(:))*100, max(buffer_empty(:))*100);

%% 간단한 플롯
figure('Position', [100, 100, 1400, 500]);

colors = {
    [0.0, 0.4, 0.7],   % 파랑
    [0.8, 0.4, 0.0],   % 주황  
    [0.0, 0.6, 0.5],   % 청록
    [0.9, 0.2, 0.3],   % 빨강
    [0.5, 0.2, 0.6]    % 보라
};
markers = {'o', 's', '^', 'd', 'v'};

% 안전장치: n_L이 colors 길이를 초과하면 자동 생성
if n_L > length(colors)
    extra_colors = lines(n_L);
    colors = cell(1, n_L);
    for k = 1:n_L
        colors{k} = extra_colors(k, :);
    end
    markers = repmat({'o', 's', '^', 'd', 'v'}, 1, ceil(n_L/5));
    markers = markers(1:n_L);
end

% Subplot 1: Explicit BSR
subplot(1, 3, 1);
hold on;
for j = 1:n_L
    plot(mu_on, explicit_bsr(:, j), ...
        'Color', colors{j}, 'Marker', markers{j}, ...
        'LineWidth', 2, 'DisplayName', sprintf('L=%.2f', L_cell(j)));
end
grid on;
xlabel('\mu_{on} [s]');
ylabel('Explicit BSR Count');
title('Explicit BSR vs μ_{on}');
legend('Location', 'best');
hold off;

% Subplot 2: Buffer Empty
subplot(1, 3, 2);
hold on;
for j = 1:n_L
    plot(mu_on, buffer_empty(:, j) * 100, ...
        'Color', colors{j}, 'Marker', markers{j}, ...
        'LineWidth', 2, 'DisplayName', sprintf('L=%.2f', L_cell(j)));
end
grid on;
xlabel('\mu_{on} [s]');
ylabel('Buffer Empty [%]');
title('Buffer Empty Ratio vs μ_{on}');
legend('Location', 'best');
hold off;

% Subplot 3: Mean Delay
subplot(1, 3, 3);
hold on;
for j = 1:n_L
    plot(mu_on, delay(:, j), ...
        'Color', colors{j}, 'Marker', markers{j}, ...
        'LineWidth', 2, 'DisplayName', sprintf('L=%.2f', L_cell(j)));
end
grid on;
xlabel('\mu_{on} [s]');
ylabel('Mean Delay [ms]');
title('Mean Delay vs μ_{on}');
legend('Location', 'best');
hold off;

sgtitle('Exp 1-3 빠른 탐색', 'FontSize', 14, 'FontWeight', 'bold');

fprintf('\n');