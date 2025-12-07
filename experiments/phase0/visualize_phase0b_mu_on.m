%% visualize_phase0b_mu_on.m
% Phase 0B: mu_on 영향 시각화
%
% 목표:
%   mu_on (burst duration)이 성능에 미치는 영향을 시각화
%
% 그래프:
%   1. Mean Delay vs mu_on (rho별, RA-RU별)
%   2. Collision Rate vs mu_on
%   3. BSR Metrics vs mu_on (Explicit BSR Ratio, Buffer Empty)
%   4. BSR Count vs mu_on (Explicit + Implicit Stacked)

clear; close all; clc;

%% =====================================================================
%  1. 데이터 로드
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  Phase 0B: mu_on 시각화\n');
fprintf('========================================\n\n');

fprintf('[1/5] 데이터 로드...\n');

csv_file = 'results/phase0/csv/baseline_sweep_summary.csv';


if ~exist(csv_file, 'file')
    error('CSV 파일을 찾을 수 없습니다: %s', csv_file);
end

T = readtable(csv_file);

fprintf('  ✓ 로드 완료: %d개 설정\n', height(T));
fprintf('  컬럼: %s\n', strjoin(T.Properties.VariableNames, ', '));

% 파라미터 확인
if ~ismember('mu_on', T.Properties.VariableNames)
    warning('mu_on 컬럼이 없습니다! Config ID로 추정합니다.');
    
    % Config ID로 mu_on 추정 (24 configs 구조)
    % Config 1-8: rho=0.3, mu_on=[0.01,0.01,0.05,0.05,0.1,0.1,0.5,0.5] (RA=1,2 교대)
    % Config 9-16: rho=0.5, mu_on=[0.01,0.01,0.05,0.05,0.1,0.1,0.5,0.5]
    % Config 17-24: rho=0.7, mu_on=[0.01,0.01,0.05,0.05,0.1,0.1,0.5,0.5]
    
    mu_on_pattern = [0.01, 0.01, 0.05, 0.05, 0.1, 0.1, 0.5, 0.5];
    T.mu_on = zeros(height(T), 1);
    
    for i = 1:height(T)
        config_id = T.config_id(i);
        idx = mod(config_id - 1, 8) + 1;  % 1~8 반복
        T.mu_on(i) = mu_on_pattern(idx);
    end
    
    fprintf('  ⚠️  mu_on 값 추정 완료 (Config ID 기반)\n');
end

fprintf('\n');

%% =====================================================================
%  2. 그래프 디렉토리 생성
%  =====================================================================

fig_dir = 'results/phase0b/figures';
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

%% =====================================================================
%  3. 파라미터 값 추출
%  =====================================================================

fprintf('[2/5] 파라미터 추출...\n');

mu_on_vals = unique(T.mu_on);
rho_vals = unique(T.rho);
RA_vals = unique(T.numRU_RA);

fprintf('  mu_on: [%s]\n', strjoin(arrayfun(@(x) sprintf('%.2f', x), mu_on_vals, 'UniformOutput', false), ', '));
fprintf('  rho: [%s]\n', strjoin(arrayfun(@(x) sprintf('%.1f', x), rho_vals, 'UniformOutput', false), ', '));
fprintf('  RA-RU: [%s]\n', strjoin(arrayfun(@num2str, RA_vals, 'UniformOutput', false), ', '));
fprintf('\n');

%% =====================================================================
%  4. Figure 1: Mean Delay vs mu_on
%  =====================================================================

fprintf('[3/5] Mean Delay vs mu_on...\n');

figure('Position', [100, 100, 1400, 600]);

for ra_idx = 1:length(RA_vals)
    subplot(1, 2, ra_idx);
    
    RA = RA_vals(ra_idx);
    
    colors = [0.2 0.4 0.8; 0.8 0.4 0.2; 0.4 0.7 0.4];  % Blue, Orange, Green
    markers = {'o-', 's-', '^-'};
    
    hold on;
    
    for rho_idx = 1:length(rho_vals)
        rho = rho_vals(rho_idx);
        
        % 데이터 추출
        delays = zeros(length(mu_on_vals), 1);
        for mu_idx = 1:length(mu_on_vals)
            mu_on = mu_on_vals(mu_idx);
            
            mask = (abs(T.rho - rho) < 0.01) & (abs(T.mu_on - mu_on) < 0.001) & (T.numRU_RA == RA);
            
            if sum(mask) > 0
                delays(mu_idx) = mean(T.mean_delay_ms(mask));
            else
                delays(mu_idx) = NaN;
            end
        end
        
        % Plot
        plot(mu_on_vals, delays, markers{rho_idx}, ...
            'Color', colors(rho_idx, :), ...
            'MarkerFaceColor', colors(rho_idx, :), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
        
        % 숫자 표시
        for mu_idx = 1:length(mu_on_vals)
            if ~isnan(delays(mu_idx))
                text(mu_on_vals(mu_idx), delays(mu_idx) + 3, ...
                    sprintf('%.1f', delays(mu_idx)), ...
                    'FontSize', 8, 'HorizontalAlignment', 'center');
            end
        end
    end
    
    hold off;
    
    xlabel('\mu_{on} [s]', 'FontSize', 13, 'FontWeight', 'bold');
    ylabel('Mean Delay [ms]', 'FontSize', 13, 'FontWeight', 'bold');
    title(sprintf('RA-RU = %d', RA), 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    set(gca, 'FontSize', 12);
    
    % X축 로그 스케일 (mu_on 범위가 크니까)
    set(gca, 'XScale', 'log');
    set(gca, 'XTick', mu_on_vals);
    set(gca, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_on_vals, 'UniformOutput', false));
end

sgtitle('Mean Delay vs Burst Duration (\mu_{on})', 'FontSize', 17, 'FontWeight', 'bold');

saveas(gcf, fullfile(fig_dir, 'MU_ON_mean_delay.png'));
close;

%% =====================================================================
%  5. Figure 2: Collision Rate & P90 Delay vs mu_on
%  =====================================================================

fprintf('[4/5] Collision & P90 vs mu_on...\n');

figure('Position', [100, 100, 1400, 1000]);

for ra_idx = 1:length(RA_vals)
    RA = RA_vals(ra_idx);
    
    % Subplot 1: Collision Rate
    subplot(2, 2, ra_idx);
    
    hold on;
    for rho_idx = 1:length(rho_vals)
        rho = rho_vals(rho_idx);
        
        collisions = zeros(length(mu_on_vals), 1);
        for mu_idx = 1:length(mu_on_vals)
            mu_on = mu_on_vals(mu_idx);
            mask = (abs(T.rho - rho) < 0.01) & (abs(T.mu_on - mu_on) < 0.001) & (T.numRU_RA == RA);
            
            if sum(mask) > 0
                collisions(mu_idx) = mean(T.collision_rate(mask)) * 100;
            else
                collisions(mu_idx) = NaN;
            end
        end
        
        plot(mu_on_vals, collisions, markers{rho_idx}, ...
            'Color', colors(rho_idx, :), ...
            'MarkerFaceColor', colors(rho_idx, :), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    
    xlabel('\mu_{on} [s]', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Collision Rate [%]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('RA-RU = %d', RA), 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    set(gca, 'XScale', 'log');
    set(gca, 'XTick', mu_on_vals);
    
    % Subplot 2: P90 Delay
    subplot(2, 2, ra_idx + 2);
    
    hold on;
    for rho_idx = 1:length(rho_vals)
        rho = rho_vals(rho_idx);
        
        p90s = zeros(length(mu_on_vals), 1);
        for mu_idx = 1:length(mu_on_vals)
            mu_on = mu_on_vals(mu_idx);
            mask = (abs(T.rho - rho) < 0.01) & (abs(T.mu_on - mu_on) < 0.001) & (T.numRU_RA == RA);
            
            if sum(mask) > 0
                p90s(mu_idx) = mean(T.p90_delay_ms(mask));
            else
                p90s(mu_idx) = NaN;
            end
        end
        
        plot(mu_on_vals, p90s, markers{rho_idx}, ...
            'Color', colors(rho_idx, :), ...
            'MarkerFaceColor', colors(rho_idx, :), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    
    xlabel('\mu_{on} [s]', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('P90 Delay [ms]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('RA-RU = %d', RA), 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    set(gca, 'XScale', 'log');
    set(gca, 'XTick', mu_on_vals);
end

sgtitle('Collision Rate & P90 Delay vs \mu_{on}', 'FontSize', 17, 'FontWeight', 'bold');

saveas(gcf, fullfile(fig_dir, 'MU_ON_collision_p90.png'));
close;

%% =====================================================================
%  6. Figure 3: BSR Metrics vs mu_on
%  =====================================================================

fprintf('[5/5] BSR Metrics vs mu_on...\n');

figure('Position', [100, 100, 1400, 1000]);

for ra_idx = 1:length(RA_vals)
    RA = RA_vals(ra_idx);
    
    % Subplot 1: Explicit BSR Ratio
    subplot(2, 2, ra_idx);
    
    hold on;
    for rho_idx = 1:length(rho_vals)
        rho = rho_vals(rho_idx);
        
        explicit = zeros(length(mu_on_vals), 1);
        for mu_idx = 1:length(mu_on_vals)
            mu_on = mu_on_vals(mu_idx);
            mask = (abs(T.rho - rho) < 0.01) & (abs(T.mu_on - mu_on) < 0.001) & (T.numRU_RA == RA);
            
            if sum(mask) > 0
                explicit(mu_idx) = mean(T.explicit_bsr_ratio(mask)) * 100;
            else
                explicit(mu_idx) = NaN;
            end
        end
        
        plot(mu_on_vals, explicit, markers{rho_idx}, ...
            'Color', colors(rho_idx, :), ...
            'MarkerFaceColor', colors(rho_idx, :), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    
    xlabel('\mu_{on} [s]', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Explicit BSR Ratio [%]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('RA-RU = %d', RA), 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    set(gca, 'XScale', 'log');
    set(gca, 'XTick', mu_on_vals);
    
    % Subplot 2: Buffer Empty
    subplot(2, 2, ra_idx + 2);
    
    hold on;
    for rho_idx = 1:length(rho_vals)
        rho = rho_vals(rho_idx);
        
        bufempty = zeros(length(mu_on_vals), 1);
        for mu_idx = 1:length(mu_on_vals)
            mu_on = mu_on_vals(mu_idx);
            mask = (abs(T.rho - rho) < 0.01) & (abs(T.mu_on - mu_on) < 0.001) & (T.numRU_RA == RA);
            
            if sum(mask) > 0
                bufempty(mu_idx) = mean(T.buffer_empty_ratio(mask)) * 100;
            else
                bufempty(mu_idx) = NaN;
            end
        end
        
        plot(mu_on_vals, bufempty, markers{rho_idx}, ...
            'Color', colors(rho_idx, :), ...
            'MarkerFaceColor', colors(rho_idx, :), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    
    xlabel('\mu_{on} [s]', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Buffer Empty Ratio [%]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('RA-RU = %d', RA), 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    set(gca, 'XScale', 'log');
    set(gca, 'XTick', mu_on_vals);
end

sgtitle('BSR Metrics vs \mu_{on}', 'FontSize', 17, 'FontWeight', 'bold');

saveas(gcf, fullfile(fig_dir, 'MU_ON_bsr_metrics.png'));
close;

%% =====================================================================
%  7. Figure 4: BSR Count vs mu_on (RA별 Grouped, Expl+Impl Stacked)
%     ⭐ Phase 0 스타일: RA별 분리, 각 RA 내 stacked
%  =====================================================================

fprintf('  [Bonus] BSR Count (RA Grouped + Stacked)...\n');

figure('Position', [100, 100, 1800, 500]);

num_mu = length(mu_on_vals);

% 색상 (RA-RU별)
color_RA1_expl = [0.2 0.4 0.8];  % Dark blue (RA=1 Explicit)
color_RA1_impl = [0.5 0.7 1.0];  % Light blue (RA=1 Implicit)
color_RA2_expl = [0.8 0.2 0.2];  % Dark red (RA=2 Explicit)
color_RA2_impl = [1.0 0.5 0.5];  % Light red (RA=2 Implicit)

for rho_idx = 1:length(rho_vals)
    subplot(1, 3, rho_idx);
    
    rho = rho_vals(rho_idx);
    
    % 데이터 준비: RA-RU별로 Explicit/Implicit
    explicit_RA1 = zeros(num_mu, 1);
    implicit_RA1 = zeros(num_mu, 1);
    explicit_RA2 = zeros(num_mu, 1);
    implicit_RA2 = zeros(num_mu, 1);
    
    for mu_idx = 1:num_mu
        mu_on = mu_on_vals(mu_idx);
        
        % RA-RU=1
        mask1 = (abs(T.rho - rho) < 0.01) & (abs(T.mu_on - mu_on) < 0.001) & (T.numRU_RA == 1);
        if sum(mask1) > 0
            explicit_RA1(mu_idx) = mean(T.explicit_bsr_count(mask1));
            implicit_RA1(mu_idx) = mean(T.implicit_bsr_count(mask1));
        end
        
        % RA-RU=2
        mask2 = (abs(T.rho - rho) < 0.01) & (abs(T.mu_on - mu_on) < 0.001) & (T.numRU_RA == 2);
        if sum(mask2) > 0
            explicit_RA2(mu_idx) = mean(T.explicit_bsr_count(mask2));
            implicit_RA2(mu_idx) = mean(T.implicit_bsr_count(mask2));
        end
    end
    
    % Grouped + Stacked bar
    % 각 RA별로 [Explicit; Implicit] stacked
    hold on;
    
    x_positions = 1:num_mu;
    bar_width = 0.35;
    
    % RA=1 막대 (왼쪽, 파랑)
    b1 = bar(x_positions - bar_width/2, [explicit_RA1, implicit_RA1], bar_width, 'stacked');
    b1(1).FaceColor = color_RA1_expl;  % Explicit
    b1(2).FaceColor = color_RA1_impl;  % Implicit
    
    % RA=2 막대 (오른쪽, 빨강)
    b2 = bar(x_positions + bar_width/2, [explicit_RA2, implicit_RA2], bar_width, 'stacked');
    b2(1).FaceColor = color_RA2_expl;  % Explicit
    b2(2).FaceColor = color_RA2_impl;  % Implicit
    
    hold off;
    
    % 숫자 표시 (각 막대 Total)
    for mu_idx = 1:num_mu
        % RA=1 Total
        total1 = explicit_RA1(mu_idx) + implicit_RA1(mu_idx);
        if total1 > 0
            text(x_positions(mu_idx) - bar_width/2, total1 + 200, ...
                sprintf('%d', round(total1)), ...
                'FontSize', 7, 'HorizontalAlignment', 'center');
        end
        
        % RA=2 Total
        total2 = explicit_RA2(mu_idx) + implicit_RA2(mu_idx);
        if total2 > 0
            text(x_positions(mu_idx) + bar_width/2, total2 + 200, ...
                sprintf('%d', round(total2)), ...
                'FontSize', 7, 'HorizontalAlignment', 'center');
        end
    end
    
    xlabel('\mu_{on} [s]', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('BSR Count (Stacked)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('\\rho = %.1f', rho), 'FontSize', 14, 'FontWeight', 'bold');
    
    set(gca, 'XTick', x_positions);
    set(gca, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_on_vals, 'UniformOutput', false));
    
    if rho_idx == 1
        legend([b1(1), b1(2), b2(1), b2(2)], ...
            {'RA=1 Explicit', 'RA=1 Implicit', 'RA=2 Explicit', 'RA=2 Implicit'}, ...
            'Location', 'best', 'FontSize', 9);
    end
    
    grid on;
    ylim([0, max([explicit_RA1 + implicit_RA1; explicit_RA2 + implicit_RA2]) * 1.15]);
end

sgtitle('BSR Count: Explicit + Implicit Stacked ⭐ NEW!', 'FontSize', 17, 'FontWeight', 'bold');

saveas(gcf, fullfile(fig_dir, 'MU_ON_bsr_count.png'));
close;

%% =====================================================================
%  8. 완료
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  시각화 완료!\n');
fprintf('========================================\n\n');

fprintf('생성된 그래프:\n');
fprintf('  1. MU_ON_mean_delay.png - Mean Delay vs mu_on\n');
fprintf('  2. MU_ON_collision_p90.png - Collision & P90 vs mu_on\n');
fprintf('  3. MU_ON_bsr_metrics.png - BSR Metrics vs mu_on\n');
fprintf('  4. MU_ON_bsr_count.png - BSR Count Stacked\n\n');

fprintf('위치: %s\n\n', fig_dir);