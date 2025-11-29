%% exp1_00_baseline_characterization.m
% Experiment 1-00: Baseline 환경별 성능 분석
%
% 목적:
%   기법 비교 실험(Phase 2) 전, 저부하/중부하/고부하 환경에서
%   Baseline(v0)의 상세 성능을 파악
%
% 시나리오:
%   - Low:  L_cell=0.15 (Unsaturated, Buffer Empty ~50%)
%   - Mid:  L_cell=0.30 (경계, Buffer Empty ~30%)
%   - High: L_cell=0.50 (Saturated)
%
% 고정 파라미터:
%   rho = 0.5, mu_on = 0.05, alpha = 1.5
%   (지난 실험 슬라이드 2와 동일)

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

exp_config = get_exp1_00_config();

%% =====================================================================
%  2. 실험 실행
%  =====================================================================

results = run_exp1_00(exp_config);

%% =====================================================================
%  3. 결과 저장
%  =====================================================================

fprintf('[결과 저장]\n');

% MAT 파일 저장
mat_dir = 'results/mat';
if ~exist(mat_dir, 'dir'), mkdir(mat_dir); end

timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
mat_filename = sprintf('%s/%s_%s.mat', mat_dir, exp_config.name, timestamp_str);

save(mat_filename, 'results', '-v7.3');
fprintf('  ✓ MAT 저장: %s\n', mat_filename);

% CSV 저장
csv_dir = 'results/csv';
if ~exist(csv_dir, 'dir'), mkdir(csv_dir); end

csv_filename = sprintf('%s/%s_summary.csv', csv_dir, exp_config.name);

% 테이블 생성
T = table();
T.Scenario = {exp_config.scenarios.name}';
T.L_cell = [exp_config.scenarios.L_cell]';

% 각 메트릭 추가
metric_names = exp_config.metrics_to_collect;
for i = 1:length(metric_names)
    metric = metric_names{i};
    T.([metric '_mean']) = results.summary.mean.(metric);
    T.([metric '_std']) = results.summary.std.(metric);
end

writetable(T, csv_filename);
fprintf('  ✓ CSV 저장: %s\n\n', csv_filename);

%% =====================================================================
%  4. 상세 결과 출력
%  =====================================================================

fprintf('========================================\n');
fprintf('  Baseline 환경별 성능 요약\n');
fprintf('========================================\n\n');

% 시나리오별 핵심 지표
scenarios = exp_config.scenarios;
mean_data = results.summary.mean;
std_data = results.summary.std;

fprintf('%-10s | %10s | %10s | %10s | %12s | %12s | %10s\n', ...
    'Scenario', 'L_cell', 'Delay[ms]', 'Coll[%]', 'Exp_BSR', 'Buf_Empty[%]', 'Compl[%]');
fprintf('%s\n', repmat('-', 1, 90));

for s = 1:length(scenarios)
    fprintf('%-10s | %10.2f | %7.2f±%.1f | %7.1f±%.1f | %9.0f±%.0f | %9.1f±%.1f | %7.1f±%.1f\n', ...
        scenarios(s).name, ...
        scenarios(s).L_cell, ...
        mean_data.mean_delay_ms(s), std_data.mean_delay_ms(s), ...
        mean_data.collision_rate(s) * 100, std_data.collision_rate(s) * 100, ...
        mean_data.explicit_bsr_count(s), std_data.explicit_bsr_count(s), ...
        mean_data.buffer_empty_ratio(s) * 100, std_data.buffer_empty_ratio(s) * 100, ...
        mean_data.completion_rate(s) * 100, std_data.completion_rate(s) * 100);
end

%% =====================================================================
%  5. 지연 분해 분석
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  지연 분해 (Delay Decomposition)\n');
fprintf('========================================\n\n');

fprintf('%-10s | %12s | %12s | %12s | %12s | %12s\n', ...
    'Scenario', 'Total[ms]', 'T_uora[ms]', 'T_sched[ms]', 'T_overhead[ms]', 'T_frag[ms]');
fprintf('%s\n', repmat('-', 1, 80));

for s = 1:length(scenarios)
    total = mean_data.mean_delay_ms(s);
    t_uora = mean_data.mean_uora_delay_ms(s);
    t_sched = mean_data.mean_sched_delay_ms(s);
    t_overhead = mean_data.mean_overhead_delay_ms(s);
    t_frag = mean_data.mean_frag_delay_ms(s);
    
    fprintf('%-10s | %12.2f | %9.2f (%4.1f%%) | %9.2f (%4.1f%%) | %9.2f (%4.1f%%) | %9.2f (%4.1f%%)\n', ...
        scenarios(s).name, ...
        total, ...
        t_uora, t_uora/total*100, ...
        t_sched, t_sched/total*100, ...
        t_overhead, t_overhead/total*100, ...
        t_frag, t_frag/total*100);
end

%% =====================================================================
%  6. BSR 분석
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  BSR 분석\n');
fprintf('========================================\n\n');

fprintf('%-10s | %12s | %12s | %12s | %15s\n', ...
    'Scenario', 'Explicit', 'Implicit', 'Total', 'Implicit Ratio');
fprintf('%s\n', repmat('-', 1, 70));

for s = 1:length(scenarios)
    exp_bsr = mean_data.explicit_bsr_count(s);
    imp_bsr = mean_data.implicit_bsr_count(s);
    total_bsr = exp_bsr + imp_bsr;
    imp_ratio = mean_data.implicit_bsr_ratio(s) * 100;
    
    fprintf('%-10s | %12.0f | %12.0f | %12.0f | %14.1f%%\n', ...
        scenarios(s).name, exp_bsr, imp_bsr, total_bsr, imp_ratio);
end

%% =====================================================================
%  7. 핵심 인사이트
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  핵심 인사이트\n');
fprintf('========================================\n\n');

% Buffer Empty 기준 Unsaturated 판정
buf_empty = mean_data.buffer_empty_ratio * 100;
fprintf('[Unsaturated 영역 판정 (Buffer Empty ≥ 30%%)]\n');
for s = 1:length(scenarios)
    if buf_empty(s) >= 30
        fprintf('  ✓ %s (L_cell=%.2f): Buffer Empty=%.1f%% → Unsaturated\n', ...
            scenarios(s).name, scenarios(s).L_cell, buf_empty(s));
    else
        fprintf('  ✗ %s (L_cell=%.2f): Buffer Empty=%.1f%% → Saturated\n', ...
            scenarios(s).name, scenarios(s).L_cell, buf_empty(s));
    end
end

% Explicit BSR 피크
fprintf('\n[Explicit BSR 발생량]\n');
[max_exp, max_idx] = max(mean_data.explicit_bsr_count);
fprintf('  최대: %s (L_cell=%.2f)에서 %.0f회\n', ...
    scenarios(max_idx).name, scenarios(max_idx).L_cell, max_exp);
fprintf('  → 이 영역에서 제안 기법의 효과가 가장 클 것으로 예상\n');

% 지연 분해 인사이트
fprintf('\n[지연 분해 인사이트]\n');
for s = 1:length(scenarios)
    t_uora = mean_data.mean_uora_delay_ms(s);
    total = mean_data.mean_delay_ms(s);
    uora_ratio = t_uora / total * 100;
    
    fprintf('  %s: T_uora가 전체 지연의 %.1f%% 차지\n', ...
        scenarios(s).name, uora_ratio);
end
fprintf('  → UORA 지연이 주요 최적화 타겟임을 확인\n');

%% =====================================================================
%  8. 시각화
%  =====================================================================

fprintf('\n[시각화 생성]\n');

fig = figure('Position', [100, 100, 1400, 900], 'Visible', 'on');

scenario_names = {scenarios.name};
L_cells = [scenarios.L_cell];
colors = lines(3);

% Subplot 1: 평균 지연
subplot(2, 3, 1);
bar_data = mean_data.mean_delay_ms;
bar_err = std_data.mean_delay_ms;
bar(bar_data, 'FaceColor', [0.3, 0.6, 0.9]);
hold on;
errorbar(1:length(scenarios), bar_data, bar_err, 'k.', 'LineWidth', 1.5);
set(gca, 'XTickLabel', scenario_names);
ylabel('Mean Delay [ms]');
title('평균 큐잉 지연');
grid on;

% Subplot 2: 지연 분해 (Stacked)
subplot(2, 3, 2);
delay_components = [
    mean_data.mean_uora_delay_ms, ...
    mean_data.mean_sched_delay_ms, ...
    mean_data.mean_overhead_delay_ms, ...
    mean_data.mean_frag_delay_ms
];
bar_handle = bar(delay_components, 'stacked');
bar_handle(1).FaceColor = [0.9, 0.5, 0.2];  % T_uora
bar_handle(2).FaceColor = [0.2, 0.7, 0.4];  % T_sched
bar_handle(3).FaceColor = [0.5, 0.5, 0.8];  % T_overhead
bar_handle(4).FaceColor = [0.7, 0.7, 0.7];  % T_frag
set(gca, 'XTickLabel', scenario_names);
ylabel('Delay [ms]');
title('지연 분해 (Stacked)');
legend({'T_{uora}', 'T_{sched}', 'T_{overhead}', 'T_{frag}'}, 'Location', 'northwest');
grid on;

% Subplot 3: BSR 구성
subplot(2, 3, 3);
bsr_data = [mean_data.explicit_bsr_count, mean_data.implicit_bsr_count];
bar_handle2 = bar(bsr_data, 'stacked');
bar_handle2(1).FaceColor = [0.9, 0.4, 0.4];  % Explicit
bar_handle2(2).FaceColor = [0.4, 0.6, 0.9];  % Implicit
set(gca, 'XTickLabel', scenario_names);
ylabel('BSR Count');
title('BSR 구성');
legend({'Explicit', 'Implicit'}, 'Location', 'northwest');
grid on;

% Subplot 4: Buffer Empty 비율
subplot(2, 3, 4);
bar(mean_data.buffer_empty_ratio * 100, 'FaceColor', [0.6, 0.8, 0.4]);
hold on;
yline(30, 'r--', '30% 기준', 'LineWidth', 2);
set(gca, 'XTickLabel', scenario_names);
ylabel('Buffer Empty [%]');
title('버퍼 비어있음 비율');
ylim([0, 100]);
grid on;

% Subplot 5: 충돌률
subplot(2, 3, 5);
bar(mean_data.collision_rate * 100, 'FaceColor', [0.9, 0.5, 0.5]);
hold on;
errorbar(1:length(scenarios), mean_data.collision_rate * 100, std_data.collision_rate * 100, 'k.', 'LineWidth', 1.5);
set(gca, 'XTickLabel', scenario_names);
ylabel('Collision Rate [%]');
title('UORA 충돌률');
grid on;

% Subplot 6: 완료율
subplot(2, 3, 6);
bar(mean_data.completion_rate * 100, 'FaceColor', [0.5, 0.7, 0.9]);
hold on;
errorbar(1:length(scenarios), mean_data.completion_rate * 100, std_data.completion_rate * 100, 'k.', 'LineWidth', 1.5);
set(gca, 'XTickLabel', scenario_names);
ylabel('Completion Rate [%]');
title('패킷 완료율');
ylim([80, 105]);
grid on;

sgtitle(sprintf('Exp 1-00: Baseline 환경별 성능 (rho=%.1f, mu_{on}=%.2f)', ...
    exp_config.fixed.rho, exp_config.fixed.mu_on), 'FontSize', 14, 'FontWeight', 'bold');

% 저장
plot_dir = 'results/figures';
if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end

plot_filename = sprintf('%s/%s.png', plot_dir, exp_config.name);
saveas(fig, plot_filename);
fprintf('  ✓ Figure 저장: %s\n', plot_filename);

% PDF로도 저장
pdf_filename = sprintf('%s/%s.pdf', plot_dir, exp_config.name);
saveas(fig, pdf_filename);
fprintf('  ✓ PDF 저장: %s\n', pdf_filename);

%% =====================================================================
%  9. 완료
%  =====================================================================

fprintf('\n🎉 Experiment 1-00 완료!\n');
fprintf('   → Phase 2 기법 비교 실험을 위한 Baseline 기준점 확보\n');
fprintf('   → Low/Mid 환경에서 제안 기법 효과 기대\n\n');