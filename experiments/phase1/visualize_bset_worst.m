%% visualize_best_worst.m
% 랩미팅용 Best/Worst 시나리오 시각화
%
% Best 3, Worst 3 시나리오 선택
% 8가지 지표 비교: Delay(3), Collision, Buffer Empty, BSR(2), Throughput

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  Best/Worst 시나리오 시각화\n');
fprintf('========================================\n\n');

%% Helper function: bar에 값 표시
function add_bar_values(b, fmt)
    if nargin < 2
        fmt = '%.1f';
    end
    for i = 1:length(b)
        x = b(i).XEndPoints;
        y = b(i).YEndPoints;
        labels = arrayfun(@(v) sprintf(fmt, v), y, 'UniformOutput', false);
        text(x, y, labels, 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', 'FontSize', 8, 'FontWeight', 'bold');
    end
end

%% 1. 결과 로드

load_file = 'v3_sweep_results.mat';
if ~exist(load_file, 'file')
    error('결과 파일 없음: %s', load_file);
end

load(load_file);

num_scenarios = length(results.scenarios);
num_runs = results.num_runs;

%% 2. Metric 추출 (summary_for_meeting.m과 동일)

fprintf('Metric 추출 중...\n');

metrics = struct();

for s = 1:num_scenarios
    
    metrics(s).scenario_idx = s;
    metrics(s).L_cell = results.scenarios(s).L_cell;
    metrics(s).mu_on = results.scenarios(s).mu_on;
    metrics(s).rho = results.scenarios(s).rho;
    metrics(s).RA_RU = results.scenarios(s).RA_RU;
    
    % Baseline
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.baseline(s, :)));
    base_p10 = mean(cellfun(@(x) x.summary.p10_delay_ms, results.baseline(s, :)));
    base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.baseline(s, :)));
    base_coll = mean(cellfun(@(x) x.uora.collision_rate, results.baseline(s, :)));
    base_buffer_empty = mean(cellfun(@(x) x.bsr.buffer_empty_ratio, results.baseline(s, :)));
    base_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.baseline(s, :)));
    base_impl = mean(cellfun(@(x) x.bsr.total_implicit, results.baseline(s, :)));
    base_throughput = mean(cellfun(@(x) x.throughput.throughput_mbps, results.baseline(s, :)));
    
    metrics(s).base_delay = base_delay;
    metrics(s).base_p10 = base_p10;
    metrics(s).base_p90 = base_p90;
    metrics(s).base_coll = base_coll;
    metrics(s).base_buffer_empty = base_buffer_empty;
    metrics(s).base_expl = base_expl;
    metrics(s).base_impl = base_impl;
    metrics(s).base_throughput = base_throughput;
    
    % v3
    v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.v3(s, :)));
    v3_p10 = mean(cellfun(@(x) x.summary.p10_delay_ms, results.v3(s, :)));
    v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.v3(s, :)));
    v3_coll = mean(cellfun(@(x) x.uora.collision_rate, results.v3(s, :)));
    v3_buffer_empty = mean(cellfun(@(x) x.bsr.buffer_empty_ratio, results.v3(s, :)));
    v3_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.v3(s, :)));
    v3_impl = mean(cellfun(@(x) x.bsr.total_implicit, results.v3(s, :)));
    v3_throughput = mean(cellfun(@(x) x.throughput.throughput_mbps, results.v3(s, :)));
    
    metrics(s).v3_delay = v3_delay;
    metrics(s).v3_p10 = v3_p10;
    metrics(s).v3_p90 = v3_p90;
    metrics(s).v3_coll = v3_coll;
    metrics(s).v3_buffer_empty = v3_buffer_empty;
    metrics(s).v3_expl = v3_expl;
    metrics(s).v3_impl = v3_impl;
    metrics(s).v3_throughput = v3_throughput;
    
    % Improvement
    metrics(s).improve_delay = (base_delay - v3_delay) / base_delay * 100;
end

fprintf('Metric 추출 완료!\n\n');

%% 3. Best/Worst 선택

[~, sorted_idx] = sort([metrics.improve_delay], 'descend');

best_3 = sorted_idx(1:3);
worst_3 = sorted_idx(end-2:end);

fprintf('Best 3 시나리오:\n');
for i = 1:3
    idx = best_3(i);
    m = metrics(idx);
    fprintf('  #%d: L=%.1f, mu=%.2f, rho=%.1f, RA=%d (%.2f%% improvement)\n', ...
        idx, m.L_cell, m.mu_on, m.rho, m.RA_RU, m.improve_delay);
end

fprintf('\nWorst 3 시나리오:\n');
for i = 1:3
    idx = worst_3(i);
    m = metrics(idx);
    fprintf('  #%d: L=%.1f, mu=%.2f, rho=%.1f, RA=%d (%.2f%% improvement)\n', ...
        idx, m.L_cell, m.mu_on, m.rho, m.RA_RU, m.improve_delay);
end

fprintf('\n');

%% 4. 시각화 - Best 3

figure('Position', [100, 100, 1600, 900]);
sgtitle('Best 3 Scenarios: Baseline vs v3', 'FontSize', 16, 'FontWeight', 'bold');

% Scenario labels
scenario_labels = cell(3, 1);
for i = 1:3
    m = metrics(best_3(i));
    scenario_labels{i} = sprintf('#%d: L=%.1f,\\mu=%.2f,\\rho=%.1f', ...
        best_3(i), m.L_cell, m.mu_on, m.rho);
end

% 색상
color_base = [0.3, 0.3, 0.8];  % Blue
color_v3 = [0.8, 0.3, 0.3];    % Red

% 1. Mean Delay
subplot(2, 4, 1);
data = [[metrics(best_3).base_delay]', [metrics(best_3).v3_delay]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Mean Delay [ms]');
title('Mean Delay');
legend({'Baseline', 'v3'}, 'Location', 'best');
grid on;
add_bar_values(b, '%.1f');
add_bar_values(b, '%.1f');

% 2. P10 Delay
subplot(2, 4, 2);
data = [[metrics(best_3).base_p10]', [metrics(best_3).v3_p10]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('P10 Delay [ms]');
title('P10 Delay');
grid on;
add_bar_values(b, '%.1f');

% 3. P90 Delay
subplot(2, 4, 3);
data = [[metrics(best_3).base_p90]', [metrics(best_3).v3_p90]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('P90 Delay [ms]');
title('P90 Delay');
grid on;
add_bar_values(b, '%.1f');

% 4. Collision Rate
subplot(2, 4, 4);
data = [[metrics(best_3).base_coll]' * 100, [metrics(best_3).v3_coll]' * 100];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Collision Rate [%]');
title('Collision Rate');
grid on;
add_bar_values(b, '%.1f');

% 5. Buffer Empty Ratio
subplot(2, 4, 5);
data = [[metrics(best_3).base_buffer_empty]' * 100, [metrics(best_3).v3_buffer_empty]' * 100];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Buffer Empty [%]');
title('Buffer Empty Ratio');
grid on;
add_bar_values(b, '%.1f');

% 6. Explicit BSR
subplot(2, 4, 6);
data = [[metrics(best_3).base_expl]', [metrics(best_3).v3_expl]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Explicit BSR Count');
title('Explicit BSR');
grid on;
add_bar_values(b, '%.0f');

% 7. Implicit BSR
subplot(2, 4, 7);
data = [[metrics(best_3).base_impl]', [metrics(best_3).v3_impl]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Implicit BSR Count');
title('Implicit BSR');
grid on;
add_bar_values(b, '%.0f');

% 8. Throughput
subplot(2, 4, 8);
data = [[metrics(best_3).base_throughput]', [metrics(best_3).v3_throughput]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Throughput [Mbps]');
title('Throughput');
grid on;
add_bar_values(b, '%.1f');

% 저장
saveas(gcf, 'best3_comparison.png');
fprintf('저장: best3_comparison.png\n');

%% 5. 시각화 - Worst 3

figure('Position', [100, 100, 1600, 900]);
sgtitle('Worst 3 Scenarios: Baseline vs v3', 'FontSize', 16, 'FontWeight', 'bold');

% Scenario labels
scenario_labels = cell(3, 1);
for i = 1:3
    m = metrics(worst_3(i));
    scenario_labels{i} = sprintf('#%d: L=%.1f,\\mu=%.2f,\\rho=%.1f', ...
        worst_3(i), m.L_cell, m.mu_on, m.rho);
end

% 1. Mean Delay
subplot(2, 4, 1);
data = [[metrics(worst_3).base_delay]', [metrics(worst_3).v3_delay]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Mean Delay [ms]');
title('Mean Delay');
legend({'Baseline', 'v3'}, 'Location', 'best');
grid on;
add_bar_values(b, '%.1f');

% 2. P10 Delay
subplot(2, 4, 2);
data = [[metrics(worst_3).base_p10]', [metrics(worst_3).v3_p10]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('P10 Delay [ms]');
title('P10 Delay');
grid on;
add_bar_values(b, '%.1f');

% 3. P90 Delay
subplot(2, 4, 3);
data = [[metrics(worst_3).base_p90]', [metrics(worst_3).v3_p90]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('P90 Delay [ms]');
title('P90 Delay');
grid on;
add_bar_values(b, '%.1f');

% 4. Collision Rate
subplot(2, 4, 4);
data = [[metrics(worst_3).base_coll]' * 100, [metrics(worst_3).v3_coll]' * 100];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Collision Rate [%]');
title('Collision Rate');
grid on;
add_bar_values(b, '%.1f');

% 5. Buffer Empty Ratio
subplot(2, 4, 5);
data = [[metrics(worst_3).base_buffer_empty]' * 100, [metrics(worst_3).v3_buffer_empty]' * 100];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Buffer Empty [%]');
title('Buffer Empty Ratio');
grid on;
add_bar_values(b, '%.1f');

% 6. Explicit BSR
subplot(2, 4, 6);
data = [[metrics(worst_3).base_expl]', [metrics(worst_3).v3_expl]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Explicit BSR Count');
title('Explicit BSR');
grid on;
add_bar_values(b, '%.0f');

% 7. Implicit BSR
subplot(2, 4, 7);
data = [[metrics(worst_3).base_impl]', [metrics(worst_3).v3_impl]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Implicit BSR Count');
title('Implicit BSR');
grid on;
add_bar_values(b, '%.0f');

% 8. Throughput
subplot(2, 4, 8);
data = [[metrics(worst_3).base_throughput]', [metrics(worst_3).v3_throughput]'];
b = bar(data);
b(1).FaceColor = color_base;
b(2).FaceColor = color_v3;
set(gca, 'XTickLabel', scenario_labels);
ylabel('Throughput [Mbps]');
title('Throughput');
grid on;
add_bar_values(b, '%.1f');

% 저장
saveas(gcf, 'worst3_comparison.png');
fprintf('저장: worst3_comparison.png\n');

%% 6. Improvement Percentage 시각화

figure('Position', [100, 100, 1400, 500]);

% Best 3 Improvement
subplot(1, 2, 1);
scenario_labels = cell(3, 1);
improve_data = zeros(3, 4);  % 4가지 주요 지표
for i = 1:3
    idx = best_3(i);
    m = metrics(idx);
    scenario_labels{i} = sprintf('#%d: L=%.1f,\\mu=%.2f', idx, m.L_cell, m.mu_on);
    
    improve_data(i, 1) = m.improve_delay;
    improve_data(i, 2) = (m.base_p90 - m.v3_p90) / m.base_p90 * 100;
    improve_data(i, 3) = (m.base_coll - m.v3_coll) / m.base_coll * 100;
    improve_data(i, 4) = (m.v3_throughput - m.base_throughput) / m.base_throughput * 100;
end

b = bar(improve_data);
b(1).FaceColor = [0.2, 0.6, 0.8];
b(2).FaceColor = [0.8, 0.4, 0.2];
b(3).FaceColor = [0.4, 0.8, 0.3];
b(4).FaceColor = [0.9, 0.6, 0.2];
set(gca, 'XTickLabel', scenario_labels);
ylabel('Improvement [%]');
title('Best 3: Improvement Percentage');
legend({'Mean Delay', 'P90 Delay', 'Collision', 'Throughput'}, 'Location', 'best');
grid on;
add_bar_values(b, '%.1f');

% Worst 3 Improvement
subplot(1, 2, 2);
scenario_labels = cell(3, 1);
improve_data = zeros(3, 4);
for i = 1:3
    idx = worst_3(i);
    m = metrics(idx);
    scenario_labels{i} = sprintf('#%d: L=%.1f,\\mu=%.2f', idx, m.L_cell, m.mu_on);
    
    improve_data(i, 1) = m.improve_delay;
    improve_data(i, 2) = (m.base_p90 - m.v3_p90) / m.base_p90 * 100;
    improve_data(i, 3) = (m.base_coll - m.v3_coll) / m.base_coll * 100;
    improve_data(i, 4) = (m.v3_throughput - m.base_throughput) / m.base_throughput * 100;
end

b = bar(improve_data);
b(1).FaceColor = [0.2, 0.6, 0.8];
b(2).FaceColor = [0.8, 0.4, 0.2];
b(3).FaceColor = [0.4, 0.8, 0.3];
b(4).FaceColor = [0.9, 0.6, 0.2];
set(gca, 'XTickLabel', scenario_labels);
ylabel('Improvement [%]');
title('Worst 3: Improvement Percentage');
legend({'Mean Delay', 'P90 Delay', 'Collision', 'Throughput'}, 'Location', 'best');
grid on;
add_bar_values(b, '%.1f');

% 저장
saveas(gcf, 'improvement_comparison.png');
fprintf('저장: improvement_comparison.png\n');

fprintf('\n========================================\n');
fprintf('  시각화 완료!\n');
fprintf('========================================\n\n');

fprintf('생성된 파일:\n');
fprintf('  1. best3_comparison.png    - Best 3 scenarios 전체 지표\n');
fprintf('  2. worst3_comparison.png   - Worst 3 scenarios 전체 지표\n');
fprintf('  3. improvement_comparison.png - Improvement 비교\n');
fprintf('\n');