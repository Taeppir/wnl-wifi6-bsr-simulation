%% analyze_v3_sweep.m
% v3 sweep 결과 분석 및 시각화
%
% Line plots & Bar charts:
% - Scenario별 bar chart (overview)
% - mu_on에 따른 line plot (L_cell별 subplot)
% - RA-RU 비교 grouped bar
% - Explicit BSR ratio vs improvement scatter

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  v3 Sweep 결과 분석\n');
fprintf('========================================\n\n');

%% 1. 결과 로드

load_file = 'v3_sweep_results.mat';
if ~exist(load_file, 'file')
    error('결과 파일 없음: %s\n먼저 run_v3_sweep.m을 실행하세요!', load_file);
end

fprintf('결과 로드: %s\n', load_file);
load(load_file);

num_scenarios = length(results.scenarios);
num_runs = results.num_runs;

fprintf('  Scenarios: %d\n', num_scenarios);
fprintf('  Runs per scenario: %d\n', num_runs);
fprintf('  v3 alpha: %.2f\n', results.v3_alpha);
fprintf('  v3 max_red: %.2f\n\n', results.v3_max_red);

%% 2. Metric 추출

fprintf('========================================\n');
fprintf('  Metric 추출 중...\n');
fprintf('========================================\n\n');

% 각 scenario별 평균 계산
metrics = struct();

for s = 1:num_scenarios
    
    sc = results.scenarios(s);
    
    % Baseline 평균
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.baseline(s, :)));
    base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.baseline(s, :)));
    base_coll = mean(cellfun(@(x) x.uora.collision_rate, results.baseline(s, :)));
    base_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.baseline(s, :)));
    base_impl = mean(cellfun(@(x) x.bsr.total_implicit, results.baseline(s, :)));
    base_total = mean(cellfun(@(x) x.bsr.total_bsr, results.baseline(s, :)));
    base_buf_empty = mean(cellfun(@(x) x.summary.buffer_empty_ratio, results.baseline(s, :)));
    
    % v3 평균
    v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.v3(s, :)));
    v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.v3(s, :)));
    v3_coll = mean(cellfun(@(x) x.uora.collision_rate, results.v3(s, :)));
    v3_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.v3(s, :)));
    v3_impl = mean(cellfun(@(x) x.bsr.total_implicit, results.v3(s, :)));
    v3_total = mean(cellfun(@(x) x.bsr.total_bsr, results.v3(s, :)));
    v3_buf_empty = mean(cellfun(@(x) x.summary.buffer_empty_ratio, results.v3(s, :)));
    
    % 저장
    metrics(s).L_cell = sc.L_cell;
    metrics(s).mu_on = sc.mu_on;
    metrics(s).rho = sc.rho;
    metrics(s).RA_RU = sc.RA_RU;
    
    metrics(s).base_delay = base_delay;
    metrics(s).base_p90 = base_p90;
    metrics(s).base_coll = base_coll;
    metrics(s).base_expl = base_expl;
    metrics(s).base_impl = base_impl;
    metrics(s).base_total = base_total;
    metrics(s).base_buf_empty = base_buf_empty;
    metrics(s).base_expl_ratio = base_expl / base_total * 100;
    
    metrics(s).v3_delay = v3_delay;
    metrics(s).v3_p90 = v3_p90;
    metrics(s).v3_coll = v3_coll;
    metrics(s).v3_expl = v3_expl;
    metrics(s).v3_impl = v3_impl;
    metrics(s).v3_total = v3_total;
    metrics(s).v3_buf_empty = v3_buf_empty;
    metrics(s).v3_expl_ratio = v3_expl / v3_total * 100;
    
    % Improvement (양수 = 개선)
    metrics(s).improve_delay = (base_delay - v3_delay) / base_delay * 100;
    metrics(s).improve_p90 = (base_p90 - v3_p90) / base_p90 * 100;
    metrics(s).improve_coll = (base_coll - v3_coll) / base_coll * 100;
    metrics(s).improve_expl = (base_expl - v3_expl) / base_expl * 100;
    metrics(s).improve_buf_empty = (base_buf_empty - v3_buf_empty) / base_buf_empty * 100;
end

fprintf('Metric 추출 완료!\n\n');

%% 3. 전체 요약 테이블

fprintf('========================================\n');
fprintf('  전체 결과 요약\n');
fprintf('========================================\n\n');

fprintf('%-4s | L_cell mu_on rho RA | ExplR%% | MeanD  P90D   Coll  | Improve: MeanD  P90D   Coll   ExplBSR\n', 'Idx');
fprintf('%s\n', repmat('-', 1, 115));

for s = 1:num_scenarios
    m = metrics(s);
    
    % Color coding for improvement
    if m.improve_delay > 5
        delay_mark = '✅';
    elseif m.improve_delay > 0
        delay_mark = '⚠️';
    else
        delay_mark = '❌';
    end
    
    fprintf('%2d  | %4.1f  %5.2f %3.1f %2d | %5.1f%% | %6.2f %6.2f %5.1f%% | %s %5.1f%% %5.1f%% %6.1f%% %7.1f%%\n', ...
        s, m.L_cell, m.mu_on, m.rho, m.RA_RU, m.base_expl_ratio, ...
        m.base_delay, m.base_p90, m.base_coll*100, ...
        delay_mark, m.improve_delay, m.improve_p90, m.improve_coll, m.improve_expl);
end

fprintf('\n');

%% 4. Sweet Spot 찾기

fprintf('========================================\n');
fprintf('  Sweet Spot 찾기\n');
fprintf('========================================\n\n');

% Criteria:
% 1. Explicit BSR ratio > 15%
% 2. Mean Delay improvement > 2%

sweet_spots = [];
for s = 1:num_scenarios
    m = metrics(s);
    if m.base_expl_ratio > 15 && m.improve_delay > 2
        sweet_spots = [sweet_spots; s];
    end
end

if isempty(sweet_spots)
    fprintf('❌ Sweet spot 없음 (ExplR>15%% && DelayImprove>2%%)\n\n');
    
    fprintf('완화된 기준으로 재검색:\n');
    fprintf('  Criteria 1: ExplR > 10%% && DelayImprove > 1%%\n\n');
    
    for s = 1:num_scenarios
        m = metrics(s);
        if m.base_expl_ratio > 10 && m.improve_delay > 1
            sweet_spots = [sweet_spots; s];
        end
    end
end

if isempty(sweet_spots)
    fprintf('❌ 완화된 기준에서도 sweet spot 없음\n');
    fprintf('👉 v3가 현재 파라미터로는 효과 없음!\n\n');
    
    fprintf('가장 좋은 시나리오들:\n');
    [~, sorted_idx] = sort([metrics.improve_delay], 'descend');
    for i = 1:min(5, num_scenarios)
        s = sorted_idx(i);
        m = metrics(s);
        fprintf('  #%d: L=%.1f, mu=%.2f, rho=%.1f, RA=%d → Delay improve %.2f%%, ExplR %.1f%%\n', ...
            s, m.L_cell, m.mu_on, m.rho, m.RA_RU, m.improve_delay, m.base_expl_ratio);
    end
    fprintf('\n');
else
    fprintf('✅ Sweet spots 발견: %d개\n\n', length(sweet_spots));
    
    for i = 1:length(sweet_spots)
        s = sweet_spots(i);
        m = metrics(s);
        fprintf('  #%d: L=%.1f, mu=%.2f, rho=%.1f, RA=%d\n', s, m.L_cell, m.mu_on, m.rho, m.RA_RU);
        fprintf('       ExplR: %.1f%%, Delay improve: %.2f%%, Coll improve: %.2f%%\n', ...
            m.base_expl_ratio, m.improve_delay, m.improve_coll);
    end
    fprintf('\n');
end

%% 5. 시각화

fprintf('========================================\n');
fprintf('  시각화 생성 중...\n');
fprintf('========================================\n\n');

L_values = unique([metrics.L_cell]);
mu_values = unique([metrics.mu_on]);
rho_values = unique([metrics.rho]);
RA_values = unique([metrics.RA_RU]);

num_L = length(L_values);
num_mu = length(mu_values);
num_rho = length(rho_values);
num_RA = length(RA_values);

% Color scheme - 동적으로 할당
if num_rho == 2
    colors = [0, 0.4470, 0.7410;      % Blue - rho=0.3
              0.8500, 0.3250, 0.0980]; % Orange - rho=0.7
elseif num_rho == 3
    colors = [0, 0.4470, 0.7410;      % Blue
              0.8500, 0.3250, 0.0980;  % Orange
              0.4660, 0.6740, 0.1880]; % Green
else
    % 더 많은 rho 값이 있으면 자동 생성
    colors = lines(num_rho);
end

%% 5-1. Mean Delay vs mu_on (Baseline vs v3)

figure('Position', [100, 100, 1400, 900]);

for L_idx = 1:num_L
    L = L_values(L_idx);
    
    for ra_idx = 1:num_RA
        RA = RA_values(ra_idx);
        
        subplot(num_L, num_RA, (L_idx-1)*num_RA + ra_idx);
        hold on;
        
        for rho_idx = 1:num_rho
            rho = rho_values(rho_idx);
            
            % 데이터 배열 초기화 (NaN으로)
            base_data = nan(1, num_mu);
            v3_data = nan(1, num_mu);
            
            for mu_idx = 1:num_mu
                mu = mu_values(mu_idx);
                
                for s = 1:num_scenarios
                    if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                       metrics(s).rho == rho && metrics(s).RA_RU == RA
                        base_data(mu_idx) = metrics(s).base_delay;
                        v3_data(mu_idx) = metrics(s).v3_delay;
                        break;
                    end
                end
            end
            
            % Baseline: 점선
            plot(1:num_mu, base_data, '--o', 'Color', colors(rho_idx,:), ...
                'LineWidth', 1.5, 'MarkerSize', 6, ...
                'DisplayName', sprintf('Baseline \\rho=%.1f', rho));
            
            % v3: 실선
            plot(1:num_mu, v3_data, '-o', 'Color', colors(rho_idx,:), ...
                'LineWidth', 2, 'MarkerSize', 8, ...
                'DisplayName', sprintf('v3 \\rho=%.1f', rho));
        end
        
        hold off;
        set(gca, 'XTick', 1:num_mu, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_values, 'UniformOutput', false));
        xlabel('\mu_{on} [s]');
        ylabel('Mean Delay [ms]');
        title(sprintf('L_{cell}=%.1f, RA-RU=%d', L, RA));
        legend('Location', 'best', 'FontSize', 8);
        grid on;
    end
end

sgtitle(sprintf('Mean Delay vs Burst Duration (Baseline vs v3, alpha=%.2f, max\\_red=%.2f)', ...
    results.v3_alpha, results.v3_max_red), 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'v3_mean_delay_comparison.png');
fprintf('저장: v3_mean_delay_comparison.png\n');

%% 5-2. Collision Rate & P90 Delay (2×2)

for L_idx = 1:num_L
    L = L_values(L_idx);
    
    figure('Position', [100, 100, 1400, 900]);
    
    % Collision Rate - RA=1
    subplot(2, 2, 1);
    hold on;
    for rho_idx = 1:num_rho
        rho = rho_values(rho_idx);
        
        base_data = nan(1, num_mu);
        v3_data = nan(1, num_mu);
        for mu_idx = 1:num_mu
            mu = mu_values(mu_idx);
            for s = 1:num_scenarios
                if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                   metrics(s).rho == rho && metrics(s).RA_RU == 1
                    base_data(mu_idx) = metrics(s).base_coll * 100;
                    v3_data(mu_idx) = metrics(s).v3_coll * 100;
                    break;
                end
            end
        end
        
        plot(1:num_mu, base_data, '--o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 1.5, 'MarkerSize', 6);
        plot(1:num_mu, v3_data, '-o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    set(gca, 'XTick', 1:num_mu, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_values, 'UniformOutput', false));
    xlabel('\mu_{on} [s]');
    ylabel('Collision Rate [%]');
    title('RA-RU = 1');
    legend('Location', 'best');
    grid on;
    
    % Collision Rate - RA=2
    subplot(2, 2, 2);
    hold on;
    for rho_idx = 1:num_rho
        rho = rho_values(rho_idx);
        
        base_data = nan(1, num_mu);
        v3_data = nan(1, num_mu);
        for mu_idx = 1:num_mu
            mu = mu_values(mu_idx);
            for s = 1:num_scenarios
                if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                   metrics(s).rho == rho && metrics(s).RA_RU == 2
                    base_data(mu_idx) = metrics(s).base_coll * 100;
                    v3_data(mu_idx) = metrics(s).v3_coll * 100;
                    break;
                end
            end
        end
        
        plot(1:num_mu, base_data, '--o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 1.5, 'MarkerSize', 6);
        plot(1:num_mu, v3_data, '-o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    set(gca, 'XTick', 1:num_mu, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_values, 'UniformOutput', false));
    xlabel('\mu_{on} [s]');
    ylabel('Collision Rate [%]');
    title('RA-RU = 2');
    legend('Location', 'best');
    grid on;
    
    % P90 Delay - RA=1
    subplot(2, 2, 3);
    hold on;
    for rho_idx = 1:num_rho
        rho = rho_values(rho_idx);
        
        base_data = nan(1, num_mu);
        v3_data = nan(1, num_mu);
        for mu_idx = 1:num_mu
            mu = mu_values(mu_idx);
            for s = 1:num_scenarios
                if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                   metrics(s).rho == rho && metrics(s).RA_RU == 1
                    base_data(mu_idx) = metrics(s).base_p90;
                    v3_data(mu_idx) = metrics(s).v3_p90;
                    break;
                end
            end
        end
        
        plot(1:num_mu, base_data, '--o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 1.5, 'MarkerSize', 6);
        plot(1:num_mu, v3_data, '-o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    set(gca, 'XTick', 1:num_mu, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_values, 'UniformOutput', false));
    xlabel('\mu_{on} [s]');
    ylabel('P90 Delay [ms]');
    title('RA-RU = 1');
    legend('Location', 'best');
    grid on;
    
    % P90 Delay - RA=2
    subplot(2, 2, 4);
    hold on;
    for rho_idx = 1:num_rho
        rho = rho_values(rho_idx);
        
        base_data = nan(1, num_mu);
        v3_data = nan(1, num_mu);
        for mu_idx = 1:num_mu
            mu = mu_values(mu_idx);
            for s = 1:num_scenarios
                if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                   metrics(s).rho == rho && metrics(s).RA_RU == 2
                    base_data(mu_idx) = metrics(s).base_p90;
                    v3_data(mu_idx) = metrics(s).v3_p90;
                    break;
                end
            end
        end
        
        plot(1:num_mu, base_data, '--o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 1.5, 'MarkerSize', 6);
        plot(1:num_mu, v3_data, '-o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    set(gca, 'XTick', 1:num_mu, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_values, 'UniformOutput', false));
    xlabel('\mu_{on} [s]');
    ylabel('P90 Delay [ms]');
    title('RA-RU = 2');
    legend('Location', 'best');
    grid on;
    
    sgtitle(sprintf('Collision Rate & P90 Delay vs \\mu_{on} (L_{cell}=%.1f)', L), ...
        'FontSize', 14, 'FontWeight', 'bold');
    saveas(gcf, sprintf('v3_collision_p90_L%.1f.png', L));
    fprintf('저장: v3_collision_p90_L%.1f.png\n', L);
end

%% 5-3. BSR Metrics (Explicit BSR Ratio & Buffer Empty Ratio)

for L_idx = 1:num_L
    L = L_values(L_idx);
    
    figure('Position', [100, 100, 1400, 900]);
    
    % Explicit BSR Ratio - RA=1
    subplot(2, 2, 1);
    hold on;
    for rho_idx = 1:num_rho
        rho = rho_values(rho_idx);
        
        base_data = nan(1, num_mu);
        for mu_idx = 1:num_mu
            mu = mu_values(mu_idx);
            for s = 1:num_scenarios
                if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                   metrics(s).rho == rho && metrics(s).RA_RU == 1
                    base_data(mu_idx) = metrics(s).base_expl_ratio;
                    break;
                end
            end
        end
        
        plot(1:num_mu, base_data, '-o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    set(gca, 'XTick', 1:num_mu, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_values, 'UniformOutput', false));
    xlabel('\mu_{on} [s]');
    ylabel('Explicit BSR Ratio [%]');
    title('RA-RU = 1');
    legend('Location', 'best');
    grid on;
    
    % Explicit BSR Ratio - RA=2
    subplot(2, 2, 2);
    hold on;
    for rho_idx = 1:num_rho
        rho = rho_values(rho_idx);
        
        base_data = nan(1, num_mu);
        for mu_idx = 1:num_mu
            mu = mu_values(mu_idx);
            for s = 1:num_scenarios
                if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                   metrics(s).rho == rho && metrics(s).RA_RU == 2
                    base_data(mu_idx) = metrics(s).base_expl_ratio;
                    break;
                end
            end
        end
        
        plot(1:num_mu, base_data, '-o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    set(gca, 'XTick', 1:num_mu, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_values, 'UniformOutput', false));
    xlabel('\mu_{on} [s]');
    ylabel('Explicit BSR Ratio [%]');
    title('RA-RU = 2');
    legend('Location', 'best');
    grid on;
    
    % Buffer Empty Ratio - RA=1
    subplot(2, 2, 3);
    hold on;
    for rho_idx = 1:num_rho
        rho = rho_values(rho_idx);
        
        base_data = nan(1, num_mu);
        v3_data = nan(1, num_mu);
        for mu_idx = 1:num_mu
            mu = mu_values(mu_idx);
            for s = 1:num_scenarios
                if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                   metrics(s).rho == rho && metrics(s).RA_RU == 1
                    base_data(mu_idx) = metrics(s).base_buf_empty * 100;
                    v3_data(mu_idx) = metrics(s).v3_buf_empty * 100;
                    break;
                end
            end
        end
        
        plot(1:num_mu, base_data, '--o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 1.5, 'MarkerSize', 6);
        plot(1:num_mu, v3_data, '-o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    set(gca, 'XTick', 1:num_mu, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_values, 'UniformOutput', false));
    xlabel('\mu_{on} [s]');
    ylabel('Buffer Empty Ratio [%]');
    title('RA-RU = 1');
    legend('Location', 'best');
    grid on;
    
    % Buffer Empty Ratio - RA=2
    subplot(2, 2, 4);
    hold on;
    for rho_idx = 1:num_rho
        rho = rho_values(rho_idx);
        
        base_data = nan(1, num_mu);
        v3_data = nan(1, num_mu);
        for mu_idx = 1:num_mu
            mu = mu_values(mu_idx);
            for s = 1:num_scenarios
                if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                   metrics(s).rho == rho && metrics(s).RA_RU == 2
                    base_data(mu_idx) = metrics(s).base_buf_empty * 100;
                    v3_data(mu_idx) = metrics(s).v3_buf_empty * 100;
                    break;
                end
            end
        end
        
        plot(1:num_mu, base_data, '--o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 1.5, 'MarkerSize', 6);
        plot(1:num_mu, v3_data, '-o', 'Color', colors(rho_idx,:), ...
            'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', sprintf('\\rho=%.1f', rho));
    end
    hold off;
    set(gca, 'XTick', 1:num_mu, 'XTickLabel', arrayfun(@(x) sprintf('%.2f', x), mu_values, 'UniformOutput', false));
    xlabel('\mu_{on} [s]');
    ylabel('Buffer Empty Ratio [%]');
    title('RA-RU = 2');
    legend('Location', 'best');
    grid on;
    
    sgtitle(sprintf('BSR Metrics vs \\mu_{on} (L_{cell}=%.1f)', L), ...
        'FontSize', 14, 'FontWeight', 'bold');
    saveas(gcf, sprintf('v3_bsr_metrics_L%.1f.png', L));
    fprintf('저장: v3_bsr_metrics_L%.1f.png\n', L);
end

%% 5-4. BSR Count Stacked Bar (Baseline vs v3)

for rho_idx = 1:num_rho
    rho = rho_values(rho_idx);
    
    figure('Position', [100, 100, 1800, 600]);
    
    for ra_idx = 1:num_RA
        RA = RA_values(ra_idx);
        
        subplot(1, num_RA, ra_idx);
        
        % 데이터 준비 (L_cell × mu_on 조합)
        x_labels = {};
        base_data = nan(1, num_mu);
        v3_data = nan(1, num_mu);
        
        idx = 0;
        for L_idx = 1:num_L
            L = L_values(L_idx);
            for mu_idx = 1:num_mu
                mu = mu_values(mu_idx);
                
                idx = idx + 1;
                x_labels{idx} = sprintf('L=%.1f\n%.2f', L, mu);
                
                for s = 1:num_scenarios
                    if metrics(s).L_cell == L && metrics(s).mu_on == mu && ...
                       metrics(s).rho == rho && metrics(s).RA_RU == RA
                        base_data(idx, :) = [metrics(s).base_expl, metrics(s).base_impl];
                        v3_data(idx, :) = [metrics(s).v3_expl, metrics(s).v3_impl];
                        break;
                    end
                end
            end
        end
        
        % Grouped stacked bar
        x = 1:idx;
        width = 0.35;
        
        % Baseline stack
        bar(x - width/2, base_data, width, 'stacked');
        hold on;
        
        % v3 stack
        bar(x + width/2, v3_data, width, 'stacked');
        
        hold off;
        
        set(gca, 'XTick', x, 'XTickLabel', x_labels, 'FontSize', 8);
        xlabel('L_{cell}, \mu_{on}');
        ylabel('BSR Count (Stacked)');
        title(sprintf('RA-RU = %d', RA));
        legend('Baseline Explicit', 'Baseline Implicit', 'v3 Explicit', 'v3 Implicit', ...
            'Location', 'best', 'FontSize', 8);
        grid on;
    end
    
    sgtitle(sprintf('BSR Count: Explicit + Implicit Stacked (\\rho=%.1f)', rho), ...
        'FontSize', 14, 'FontWeight', 'bold');
    saveas(gcf, sprintf('v3_bsr_count_rho%.1f.png', rho));
    fprintf('저장: v3_bsr_count_rho%.1f.png\n', rho);
end

%% 5-5. Improvement Summary Bar Chart

figure('Position', [100, 100, 1600, 900]);

% Mean Delay Improvement
subplot(2, 2, 1);
bar([metrics.improve_delay]);
hold on;
yline(0, 'r--', 'LineWidth', 1.5);
xlabel('Scenario Index');
ylabel('Mean Delay Improvement [%]');
title('Mean Delay Improvement by Scenario');
grid on;
ylim([-15 15]);

% P90 Delay Improvement
subplot(2, 2, 2);
bar([metrics.improve_p90]);
hold on;
yline(0, 'r--', 'LineWidth', 1.5);
xlabel('Scenario Index');
ylabel('P90 Delay Improvement [%]');
title('P90 Delay Improvement by Scenario');
grid on;
ylim([-15 15]);

% Collision Improvement
subplot(2, 2, 3);
bar([metrics.improve_coll]);
hold on;
yline(0, 'r--', 'LineWidth', 1.5);
xlabel('Scenario Index');
ylabel('Collision Improvement [%]');
title('Collision Rate Improvement by Scenario');
grid on;
ylim([-15 15]);

% Explicit BSR Reduction
subplot(2, 2, 4);
bar([metrics.improve_expl]);
hold on;
yline(0, 'r--', 'LineWidth', 1.5);
xlabel('Scenario Index');
ylabel('Explicit BSR Reduction [%]');
title('Explicit BSR Reduction by Scenario');
grid on;
ylim([-10 10]);

sgtitle('v3 Performance Improvement Summary', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'v3_improvement_summary.png');
fprintf('저장: v3_improvement_summary.png\n');

fprintf('\n');

%% 6. 결론

fprintf('========================================\n');
fprintf('  종합 결론\n');
fprintf('========================================\n\n');

% 전체 평균 improvement
avg_improve_delay = mean([metrics.improve_delay]);
avg_improve_p90 = mean([metrics.improve_p90]);
avg_improve_coll = mean([metrics.improve_coll]);
avg_improve_expl = mean([metrics.improve_expl]);

fprintf('전체 평균 improvement:\n');
fprintf('  Mean Delay: %.2f%%\n', avg_improve_delay);
fprintf('  P90 Delay: %.2f%%\n', avg_improve_p90);
fprintf('  Collision: %.2f%%\n', avg_improve_coll);
fprintf('  Explicit BSR: %.2f%%\n\n', avg_improve_expl);

% 최고 성능 시나리오
[max_delay_improve, max_delay_idx] = max([metrics.improve_delay]);
m_best = metrics(max_delay_idx);

fprintf('최고 Delay improvement:\n');
fprintf('  Scenario #%d: L=%.1f, mu=%.2f, rho=%.1f, RA=%d\n', ...
    max_delay_idx, m_best.L_cell, m_best.mu_on, m_best.rho, m_best.RA_RU);
fprintf('  Mean Delay: %.2f%% 개선\n', m_best.improve_delay);
fprintf('  P90 Delay: %.2f%% 개선\n', m_best.improve_p90);
fprintf('  Collision: %.2f%% 개선\n', m_best.improve_coll);
fprintf('  Explicit BSR Ratio: %.1f%%\n\n', m_best.base_expl_ratio);

% 권장사항
fprintf('권장사항:\n');
if avg_improve_delay > 2
    fprintf('  ✅ v3가 전반적으로 효과적! (평균 %.1f%% 개선)\n', avg_improve_delay);
    fprintf('  👉 다음: 파라미터 최적화 (alpha, max_red sweep)\n');
elseif avg_improve_delay > 0
    fprintf('  ⚠️  v3 효과 미미 (평균 %.1f%%)\n', avg_improve_delay);
    fprintf('  👉 특정 조건에서만 효과 있음. Sweet spot 중심 파라미터 최적화 추천\n');
else
    fprintf('  ❌ v3 효과 없음 (평균 %.1f%%)\n', avg_improve_delay);
    fprintf('  👉 근본 재설계 필요 or 대체 접근법 탐색\n');
end

fprintf('\n========================================\n\n');