%% visualize_phase0_rho_centric.m
% 진짜 최선: rho를 중심으로, L_cell X축, RA-RU 비교

clear; close all; clc;

if exist('setup_paths.m', 'file')
    setup_paths;
end

fprintf('\n========================================\n');
fprintf('  Phase 0: rho 중심 시각화\n');
fprintf('========================================\n\n');

%% 데이터 로드

csv_file = 'results/phase0/csv/baseline_sweep_summary.csv';
T = readtable(csv_file);

fprintf('데이터: %d개 설정\n\n', height(T));

fig_dir = 'results/phase0/figures';
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

%% 데이터 정리

L_vals = [0.15, 0.3, 0.5];
rho_vals = [0.3, 0.5, 0.7];

color_ra1 = [0.3 0.5 0.8];
color_ra2 = [0.9 0.4 0.4];

%% Figure 1: Mean Delay (rho별) ⭐⭐⭐

fprintf('  [1/4] Mean Delay (rho별)...\n');

figure('Position', [100, 100, 1800, 500]);

for rho_idx = 1:3
    subplot(1, 3, rho_idx);
    
    rho = rho_vals(rho_idx);
    
    % 이 rho의 데이터
    data_ra1 = zeros(1, 3);
    data_ra2 = zeros(1, 3);
    
    for L_idx = 1:3
        L = L_vals(L_idx);
        
        data_ra1(L_idx) = T.mean_delay_ms((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 1));
        data_ra2(L_idx) = T.mean_delay_ms((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 2));
    end
    
    % Grouped bar
    bar_data = [data_ra1; data_ra2]';
    b = bar(bar_data, 'BarWidth', 0.85);
    b(1).FaceColor = color_ra1;
    b(2).FaceColor = color_ra2;
    
    set(gca, 'XTickLabel', {'0.15', '0.3', '0.5'}, 'FontSize', 12);
    xlabel('L_{cell}', 'FontSize', 13, 'FontWeight', 'bold');
    ylabel('Mean Delay [ms]', 'FontSize', 13, 'FontWeight', 'bold');
    title(sprintf('\\rho = %.1f', rho), 'FontSize', 15, 'FontWeight', 'bold');
    
    if rho_idx == 3
        legend({'RA-RU=1', 'RA-RU=2'}, 'Location', 'best', 'FontSize', 12);
    end
    
    grid on;
    ylim([0, 140]);  % ⭐ 80 → 140으로 수정 (실제 최대: 123ms)
    
    % Y축 값 표시
    for i = 1:3
        text(i-0.15, data_ra1(i)+2, sprintf('%.1f', data_ra1(i)), ...
            'FontSize', 9, 'HorizontalAlignment', 'center');
        text(i+0.15, data_ra2(i)+2, sprintf('%.1f', data_ra2(i)), ...
            'FontSize', 9, 'HorizontalAlignment', 'center');
    end
end

sgtitle('Mean Delay: \rho별 비교 (핵심: \rho=0.7에서 급감!)', ...
    'FontSize', 17, 'FontWeight', 'bold');

saveas(gcf, fullfile(fig_dir, 'RHO_mean_delay.png'));
close;

%% Figure 2: Collision & P90 (rho별) ⭐⭐⭐

fprintf('  [2/4] Collision & P90 (rho별)...\n');

figure('Position', [150, 150, 1800, 900]);

% Row 1: Collision Rate
for rho_idx = 1:3
    subplot(2, 3, rho_idx);
    
    rho = rho_vals(rho_idx);
    
    data_ra1 = zeros(1, 3);
    data_ra2 = zeros(1, 3);
    
    for L_idx = 1:3
        L = L_vals(L_idx);
        
        data_ra1(L_idx) = T.collision_rate((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 1)) * 100;
        data_ra2(L_idx) = T.collision_rate((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 2)) * 100;
    end
    
    bar_data = [data_ra1; data_ra2]';
    b = bar(bar_data, 'BarWidth', 0.85);
    b(1).FaceColor = color_ra1;
    b(2).FaceColor = color_ra2;
    
    set(gca, 'XTickLabel', {'0.15', '0.3', '0.5'}, 'FontSize', 11);
    xlabel('L_{cell}', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Collision Rate [%]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('\\rho = %.1f', rho), 'FontSize', 14, 'FontWeight', 'bold');
    
    if rho_idx == 3
        legend({'RA=1', 'RA=2'}, 'Location', 'best', 'FontSize', 11);
    end
    
    grid on;
    ylim([0, 60]);  % ⭐ 15 → 60으로 수정 (실제 범위: 19~48%)
end

% Row 2: P90 Delay
for rho_idx = 1:3
    subplot(2, 3, 3 + rho_idx);
    
    rho = rho_vals(rho_idx);
    
    data_ra1 = zeros(1, 3);
    data_ra2 = zeros(1, 3);
    
    for L_idx = 1:3
        L = L_vals(L_idx);
        
        data_ra1(L_idx) = T.p90_delay_ms((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 1));
        data_ra2(L_idx) = T.p90_delay_ms((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 2));
    end
    
    bar_data = [data_ra1; data_ra2]';
    b = bar(bar_data, 'BarWidth', 0.85);
    b(1).FaceColor = color_ra1;
    b(2).FaceColor = color_ra2;
    
    set(gca, 'XTickLabel', {'0.15', '0.3', '0.5'}, 'FontSize', 11);
    xlabel('L_{cell}', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('P90 Delay [ms]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('\\rho = %.1f', rho), 'FontSize', 14, 'FontWeight', 'bold');
    
    if rho_idx == 3
        legend({'RA=1', 'RA=2'}, 'Location', 'best', 'FontSize', 11);
    end
    
    grid on;
    ylim([0, 300]);  % ⭐ 180 → 300으로 수정 (실제 최대: 281ms)
end

sgtitle('Collision Rate & P90 Delay: \rho별 비교', ...
    'FontSize', 17, 'FontWeight', 'bold');

saveas(gcf, fullfile(fig_dir, 'RHO_collision_p90.png'));
close;

%% Figure 3: BSR 지표 (rho별) ⭐⭐

fprintf('  [3/4] BSR 지표 (rho별)...\n');

figure('Position', [200, 200, 1800, 900]);

% Row 1: Explicit BSR
for rho_idx = 1:3
    subplot(2, 3, rho_idx);
    
    rho = rho_vals(rho_idx);
    
    data_ra1 = zeros(1, 3);
    data_ra2 = zeros(1, 3);
    
    for L_idx = 1:3
        L = L_vals(L_idx);
        
        data_ra1(L_idx) = T.explicit_bsr_ratio((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 1)) * 100;
        data_ra2(L_idx) = T.explicit_bsr_ratio((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 2)) * 100;
    end
    
    bar_data = [data_ra1; data_ra2]';
    b = bar(bar_data, 'BarWidth', 0.85);
    b(1).FaceColor = color_ra1;
    b(2).FaceColor = color_ra2;
    
    set(gca, 'XTickLabel', {'0.15', '0.3', '0.5'}, 'FontSize', 11);
    xlabel('L_{cell}', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Explicit BSR [%]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('\\rho = %.1f', rho), 'FontSize', 14, 'FontWeight', 'bold');
    
    if rho_idx == 3
        legend({'RA=1', 'RA=2'}, 'Location', 'best', 'FontSize', 11);
    end
    
    grid on;
    ylim([0, 40]);  % ⭐ [20,45] → [0,40]으로 수정 (실제 범위: 7.4~36.1%)
end

% Row 2: Buffer Empty
for rho_idx = 1:3
    subplot(2, 3, 3 + rho_idx);
    
    rho = rho_vals(rho_idx);
    
    data_ra1 = zeros(1, 3);
    data_ra2 = zeros(1, 3);
    
    for L_idx = 1:3
        L = L_vals(L_idx);
        
        data_ra1(L_idx) = T.buffer_empty_ratio((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 1)) * 100;
        data_ra2(L_idx) = T.buffer_empty_ratio((T.L_cell == L) & (T.rho == rho) & (T.numRU_RA == 2)) * 100;
    end
    
    bar_data = [data_ra1; data_ra2]';
    b = bar(bar_data, 'BarWidth', 0.85);
    b(1).FaceColor = color_ra1;
    b(2).FaceColor = color_ra2;
    
    set(gca, 'XTickLabel', {'0.15', '0.3', '0.5'}, 'FontSize', 11);
    xlabel('L_{cell}', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Buffer Empty [%]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('\\rho = %.1f', rho), 'FontSize', 14, 'FontWeight', 'bold');
    
    if rho_idx == 3
        legend({'RA=1', 'RA=2'}, 'Location', 'best', 'FontSize', 11);
    end
    
    grid on;
    ylim([0, 80]);  % ⭐ [40,90] → [0,80]으로 수정 (실제 범위: 13.7~71.7%)
end

sgtitle('BSR 지표: \rho별 비교', 'FontSize', 17, 'FontWeight', 'bold');

saveas(gcf, fullfile(fig_dir, 'RHO_bsr_metrics.png'));
close;

%% Figure 4: BSR Count (rho별) - Stacked ⭐ NEW!

fprintf('  [4/4] BSR Count Stacked (rho별)...\n');

figure('Position', [300, 300, 1800, 600]);

% 색상 정의 (Explicit/Implicit 구분)
color_explicit = [0.3 0.5 0.8];  % 파랑 (Explicit)
color_implicit = [0.9 0.7 0.7];  % 연한 빨강 (Implicit)

for rho_idx = 1:3
    subplot(1, 3, rho_idx);
    
    rho = rho_vals(rho_idx);
    
    % 데이터 수집
    explicit_ra1 = zeros(1, 3);
    implicit_ra1 = zeros(1, 3);
    explicit_ra2 = zeros(1, 3);
    implicit_ra2 = zeros(1, 3);
    
    for L_idx = 1:3
        L = L_vals(L_idx);
        
        % ⭐ tolerance 사용한 안전한 비교
        idx_ra1 = find(abs(T.L_cell - L) < 0.01 & abs(T.rho - rho) < 0.01 & T.numRU_RA == 1, 1);
        idx_ra2 = find(abs(T.L_cell - L) < 0.01 & abs(T.rho - rho) < 0.01 & T.numRU_RA == 2, 1);
        
        if ~isempty(idx_ra1)
            explicit_ra1(L_idx) = T.explicit_bsr_count(idx_ra1);
            implicit_ra1(L_idx) = T.implicit_bsr_count(idx_ra1);
        end
        
        if ~isempty(idx_ra2)
            explicit_ra2(L_idx) = T.explicit_bsr_count(idx_ra2);
            implicit_ra2(L_idx) = T.implicit_bsr_count(idx_ra2);
        end
    end
    
    % Stacked bar data: [RA=1 RA=2] for each L_cell
    % Row 1: Explicit, Row 2: Implicit
    bar_data = [explicit_ra1; implicit_ra1; explicit_ra2; implicit_ra2]';
    
    % Grouped stacked bar
    x = 1:3;
    width = 0.35;
    
    % RA=1 bars (왼쪽)
    h1 = bar(x - width/2, [explicit_ra1; implicit_ra1]', width, 'stacked');
    h1(1).FaceColor = [0.3 0.5 0.8];  % Explicit (진한 파랑)
    h1(2).FaceColor = [0.6 0.75 0.95];  % Implicit (연한 파랑)
    
    hold on;
    
    % RA=2 bars (오른쪽)
    h2 = bar(x + width/2, [explicit_ra2; implicit_ra2]', width, 'stacked');
    h2(1).FaceColor = [0.9 0.4 0.4];  % Explicit (진한 빨강)
    h2(2).FaceColor = [1.0 0.7 0.7];  % Implicit (연한 빨강)
    
    % 숫자 표시
    for i = 1:3
        % RA=1 Total
        total_ra1 = explicit_ra1(i) + implicit_ra1(i);
        text(x(i) - width/2, total_ra1 + 500, sprintf('%.0f', total_ra1), ...
            'FontSize', 9, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        
        % RA=2 Total
        total_ra2 = explicit_ra2(i) + implicit_ra2(i);
        text(x(i) + width/2, total_ra2 + 500, sprintf('%.0f', total_ra2), ...
            'FontSize', 9, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        
        % Explicit 값 (아래층 중간)
        text(x(i) - width/2, explicit_ra1(i)/2, sprintf('%.0f', explicit_ra1(i)), ...
            'FontSize', 8, 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold');
        text(x(i) + width/2, explicit_ra2(i)/2, sprintf('%.0f', explicit_ra2(i)), ...
            'FontSize', 8, 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold');
        
        % Implicit 값 (위층 중간)
        text(x(i) - width/2, explicit_ra1(i) + implicit_ra1(i)/2, sprintf('%.0f', implicit_ra1(i)), ...
            'FontSize', 8, 'HorizontalAlignment', 'center', 'Color', 'k', 'FontWeight', 'bold');
        text(x(i) + width/2, explicit_ra2(i) + implicit_ra2(i)/2, sprintf('%.0f', implicit_ra2(i)), ...
            'FontSize', 8, 'HorizontalAlignment', 'center', 'Color', 'k', 'FontWeight', 'bold');
    end
    
    hold off;
    
    % 축 설정
    set(gca, 'XTick', 1:3, 'XTickLabel', {'0.15', '0.3', '0.5'}, 'FontSize', 12);
    xlabel('L_{cell}', 'FontSize', 13, 'FontWeight', 'bold');
    ylabel('BSR Count (Stacked)', 'FontSize', 13, 'FontWeight', 'bold');
    title(sprintf('\\rho = %.1f', rho), 'FontSize', 15, 'FontWeight', 'bold');
    
    % Legend (첫 subplot만)
    if rho_idx == 1
        legend([h1(1), h1(2), h2(1), h2(2)], ...
               {'RA=1 Explicit', 'RA=1 Implicit', 'RA=2 Explicit', 'RA=2 Implicit'}, ...
               'Location', 'northwest', 'FontSize', 9);
    end
    
    grid on;
    xlim([0.5, 3.5]);
    ylim([0, 20000]);
end

sgtitle('BSR Count: Explicit + Implicit Stacked ⭐ NEW!', ...
    'FontSize', 17, 'FontWeight', 'bold');

saveas(gcf, fullfile(fig_dir, 'RHO_bsr_count.png'));
close;

%% 완료

fprintf('\n========================================\n');
fprintf('  완료!\n');
fprintf('========================================\n\n');

fprintf('생성된 Figure (4개): ⭐\n\n');

fprintf('  1. RHO_mean_delay.png ⭐⭐⭐\n');
fprintf('     → rho=0.3, 0.5, 0.7별 subplot\n');
fprintf('     → X축: L_cell (0.1, 0.3, 0.5)\n');
fprintf('     → Bar: RA-RU 비교 (파랑=1, 빨강=2)\n');
fprintf('     → 핵심: rho=0.7에서 delay 급감!\n\n');

fprintf('  2. RHO_collision_p90.png ⭐⭐⭐\n');
fprintf('     → 2×3 grid\n');
fprintf('     → Row 1: Collision Rate\n');
fprintf('     → Row 2: P90 Delay\n\n');

fprintf('  3. RHO_bsr_metrics.png ⭐\n');
fprintf('     → 2×3 grid\n');
fprintf('     → Row 1: Explicit BSR Ratio\n');
fprintf('     → Row 2: Buffer Empty Ratio\n\n');

fprintf('  4. RHO_bsr_count.png ⭐ NEW!\n');
fprintf('     → 1×3 grid (1 row만!)\n');
fprintf('     → Stacked Bar: Explicit (아래) + Implicit (위)\n');
fprintf('     → 숫자 표시: Explicit, Implicit, Total 모두 표시\n');
fprintf('     → 색상: RA=1 (파랑계열), RA=2 (빨강계열)\n\n');

fprintf('핵심 인사이트:\n');
fprintf('  • rho=0.7: 22-26ms (최저!) ← continuous traffic\n');
fprintf('  • rho=0.3: 57-73ms (최고!) ← bursty traffic\n');
fprintf('  • RA-RU=2: rho에 따라 효과 다름\n\n');

fprintf('비교 방법:\n');
fprintf('  • rho 영향: subplot 간 비교 (좌→우)\n');
fprintf('  • L_cell 영향: X축 따라 비교\n');
fprintf('  • RA-RU 영향: 파랑 vs 빨강\n\n');