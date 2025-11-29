%% exp2_01_scheme_comparison.m
% Experiment 2-1: 정책 비교 - 부하 수준별 성능
%
% 목적:
%   제안 스킴(v1~v3)이 Baseline 대비 T_uora를 얼마나 감소시키는가?
%   이를 통해 총 큐잉 지연과 분산을 줄일 수 있는가?
%
% 핵심 가설:
%   - 중부하(Mid) 환경에서 개선 효과가 가장 클 것
%   - T_uora 감소 → 평균 지연 감소 + 분산 감소
%
% 시나리오 (Exp 1-00 결과 기반):
%   - Low (L=0.15):  Buffer Empty 38.7%, Unsaturated
%   - Mid (L=0.30):  Buffer Empty 27.2%, 경계 (핵심 타겟)
%   - High (L=0.50): Buffer Empty 23.7%, Saturated
%
% 스킴:
%   - v0: Baseline (R=Q)
%   - v1: Fixed Reduction
%   - v2: Proportional
%   - v3: EMA-based
%
% 고정 파라미터:
%   rho = 0.5, mu_on = 0.05, alpha = 1.5 (Exp 1-00과 동일)

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

exp_config = get_exp2_01_config();

%% =====================================================================
%  2. 실험 실행 (커스텀 러너 사용)
%  =====================================================================

results = run_exp2_01(exp_config);

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
n_scenarios = length(exp_config.scenarios);
n_schemes = length(exp_config.schemes);
n_rows = n_scenarios * n_schemes;

T = table();
scenario_col = cell(n_rows, 1);
scheme_col = cell(n_rows, 1);
L_cell_col = zeros(n_rows, 1);

row_idx = 0;
for s = 1:n_scenarios
    for sc = 1:n_schemes
        row_idx = row_idx + 1;
        scenario_col{row_idx} = exp_config.scenarios(s).name;
        scheme_col{row_idx} = exp_config.scheme_names{sc};
        L_cell_col(row_idx) = exp_config.scenarios(s).L_cell;
    end
end

T.Scenario = scenario_col;
T.L_cell = L_cell_col;
T.Scheme = scheme_col;

% 주요 지표 추가
key_metrics = exp_config.metrics_to_collect;
for i = 1:length(key_metrics)
    metric = key_metrics{i};
    if isfield(results.summary.mean, metric)
        mean_data = results.summary.mean.(metric);
        std_data = results.summary.std.(metric);
        
        T.([metric '_mean']) = mean_data(:);
        T.([metric '_std']) = std_data(:);
    end
end

writetable(T, csv_filename);
fprintf('  ✓ CSV 저장: %s\n\n', csv_filename);

%% =====================================================================
%  4. 핵심 결과 요약 출력
%  =====================================================================

fprintf('========================================\n');
fprintf('  핵심 결과 요약\n');
fprintf('========================================\n\n');

mean_delay = results.summary.mean.mean_delay_ms;
std_delay_metric = results.summary.mean.std_delay_ms;  % 지연의 표준편차
mean_uora = results.summary.mean.mean_uora_delay_ms;
mean_explicit = results.summary.mean.explicit_bsr_count;

% 테이블 헤더
fprintf('%-8s | %-22s | %10s | %10s | %10s | %10s\n', ...
    'Scenario', 'Scheme', 'Delay[ms]', 'Std[ms]', 'T_uora[ms]', 'Exp_BSR');
fprintf('%s\n', repmat('-', 1, 85));

for s = 1:n_scenarios
    for sc = 1:n_schemes
        fprintf('%-8s | %-22s | %10.2f | %10.2f | %10.2f | %10.0f\n', ...
            exp_config.scenarios(s).name, ...
            exp_config.scheme_names{sc}, ...
            mean_delay(s, sc), ...
            std_delay_metric(s, sc), ...
            mean_uora(s, sc), ...
            mean_explicit(s, sc));
    end
    fprintf('%s\n', repmat('-', 1, 85));
end

%% =====================================================================
%  5. 개선률 분석 (Baseline 대비)
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  개선률 (Baseline 대비)\n');
fprintf('========================================\n\n');

baseline_idx = 1;  % v0

for s = 1:n_scenarios
    fprintf('[%s (L_cell=%.2f)]\n', exp_config.scenarios(s).name, exp_config.scenarios(s).L_cell);
    
    baseline_delay = mean_delay(s, baseline_idx);
    baseline_std = std_delay_metric(s, baseline_idx);
    baseline_uora = mean_uora(s, baseline_idx);
    baseline_exp = mean_explicit(s, baseline_idx);
    
    for sc = 2:n_schemes  % 제안 스킴만
        delay_reduction = (1 - mean_delay(s, sc) / baseline_delay) * 100;
        std_reduction = (1 - std_delay_metric(s, sc) / baseline_std) * 100;
        uora_reduction = (1 - mean_uora(s, sc) / baseline_uora) * 100;
        exp_reduction = (1 - mean_explicit(s, sc) / baseline_exp) * 100;
        
        fprintf('  %s:\n', exp_config.scheme_names{sc});
        fprintf('    평균 지연: %+.1f%% (%s)\n', -delay_reduction, get_indicator(delay_reduction));
        fprintf('    지연 분산: %+.1f%% (%s)\n', -std_reduction, get_indicator(std_reduction));
        fprintf('    T_uora:    %+.1f%% (%s)\n', -uora_reduction, get_indicator(uora_reduction));
        fprintf('    Exp BSR:   %+.1f%% (%s)\n', -exp_reduction, get_indicator(exp_reduction));
        fprintf('\n');
    end
end

%% =====================================================================
%  6. 시나리오별 최고 성능 기법
%  =====================================================================

fprintf('========================================\n');
fprintf('  시나리오별 최고 성능 기법\n');
fprintf('========================================\n\n');

for s = 1:n_scenarios
    [min_delay, best_idx] = min(mean_delay(s, :));
    baseline_delay = mean_delay(s, 1);
    improvement = (1 - min_delay / baseline_delay) * 100;
    
    fprintf('[%s]: %s (지연 %.1f%% 감소)\n', ...
        exp_config.scenarios(s).name, ...
        exp_config.scheme_names{best_idx}, ...
        improvement);
end

%% =====================================================================
%  7. 시각화
%  =====================================================================

fprintf('\n[시각화 생성]\n');

fig = figure('Position', [100, 100, 1600, 1000], 'Visible', 'on');

scenario_names = {exp_config.scenarios.name};
scheme_names_short = {'v0', 'v1', 'v2', 'v3'};
colors = [0.5 0.5 0.5;    % v0: 회색 (Baseline)
          0.9 0.4 0.4;    % v1: 빨강
          0.4 0.7 0.4;    % v2: 초록
          0.4 0.4 0.9];   % v3: 파랑

% Subplot 1: 평균 지연 비교
subplot(2, 3, 1);
bar_data = mean_delay;  % [scenarios × schemes]
b = bar(bar_data);
for i = 1:n_schemes
    if i <= length(b)
        b(i).FaceColor = colors(i, :);
    end
end
set(gca, 'XTickLabel', scenario_names);
ylabel('Mean Delay [ms]');
title('평균 큐잉 지연');
legend(scheme_names_short, 'Location', 'northwest');
grid on;

% Subplot 2: 지연 분산 비교 (⭐ 핵심)
subplot(2, 3, 2);
bar_data = std_delay_metric;  % [scenarios × schemes]
b = bar(bar_data);
for i = 1:n_schemes
    if i <= length(b)
        b(i).FaceColor = colors(i, :);
    end
end
set(gca, 'XTickLabel', scenario_names);
ylabel('Delay Std [ms]');
title('지연 분산 (⭐ 감소 목표)');
legend(scheme_names_short, 'Location', 'northwest');
grid on;

% Subplot 3: T_uora 비교 (⭐ 핵심)
subplot(2, 3, 3);
bar_data = mean_uora;  % [scenarios × schemes]
b = bar(bar_data);
for i = 1:n_schemes
    if i <= length(b)
        b(i).FaceColor = colors(i, :);
    end
end
set(gca, 'XTickLabel', scenario_names);
ylabel('T_{uora} [ms]');
title('UORA 지연 (⭐ 핵심 타겟)');
legend(scheme_names_short, 'Location', 'northwest');
grid on;

% Subplot 4: Explicit BSR 비교
subplot(2, 3, 4);
bar_data = mean_explicit;  % [scenarios × schemes]
b = bar(bar_data);
for i = 1:n_schemes
    if i <= length(b)
        b(i).FaceColor = colors(i, :);
    end
end
set(gca, 'XTickLabel', scenario_names);
ylabel('Explicit BSR Count');
title('Explicit BSR 발생 횟수');
legend(scheme_names_short, 'Location', 'northwest');
grid on;

% Subplot 5: 개선률 (Baseline 대비 지연 감소)
subplot(2, 3, 5);
improvement_data = zeros(n_scenarios, n_schemes - 1);
for s = 1:n_scenarios
    for sc = 2:n_schemes
        improvement_data(s, sc-1) = (1 - mean_delay(s, sc) / mean_delay(s, 1)) * 100;
    end
end
b = bar(improvement_data);
colors_no_baseline = colors(2:end, :);
for i = 1:(n_schemes-1)
    if i <= length(b)
        b(i).FaceColor = colors_no_baseline(i, :);
    end
end
set(gca, 'XTickLabel', scenario_names);
ylabel('Delay Reduction [%]');
title('지연 개선률 (Baseline 대비)');
legend(scheme_names_short(2:end), 'Location', 'northwest');
grid on;
hold on;
yline(0, 'k--', 'LineWidth', 1);

% Subplot 6: 완료율
subplot(2, 3, 6);
completion_data = results.summary.mean.completion_rate * 100;  % [scenarios × schemes]
b = bar(completion_data);
for i = 1:n_schemes
    if i <= length(b)
        b(i).FaceColor = colors(i, :);
    end
end
set(gca, 'XTickLabel', scenario_names);
ylabel('Completion Rate [%]');
title('패킷 완료율');
legend(scheme_names_short, 'Location', 'southwest');
ylim([90, 102]);
grid on;

sgtitle(sprintf('Exp 2-1: 기법 비교 (rho=%.1f, mu_{on}=%.2f)', ...
    exp_config.scenarios(1).rho, exp_config.scenarios(1).mu_on), ...
    'FontSize', 14, 'FontWeight', 'bold');

% 저장
plot_dir = 'results/figures';
if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end

plot_filename = sprintf('%s/%s.png', plot_dir, exp_config.name);
saveas(fig, plot_filename);
fprintf('  ✓ Figure 저장: %s\n', plot_filename);

pdf_filename = sprintf('%s/%s.pdf', plot_dir, exp_config.name);
saveas(fig, pdf_filename);
fprintf('  ✓ PDF 저장: %s\n', pdf_filename);

%% =====================================================================
%  8. 핵심 인사이트 출력
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  핵심 인사이트\n');
fprintf('========================================\n\n');

% Mid 환경에서 가장 좋은 기법 찾기
mid_idx = 2;  % Mid scenario
[best_delay_mid, best_scheme_mid] = min(mean_delay(mid_idx, :));
improvement_mid = (1 - best_delay_mid / mean_delay(mid_idx, 1)) * 100;

fprintf('[Mid 환경 (핵심 타겟)]\n');
fprintf('  최고 성능 기법: %s\n', exp_config.scheme_names{best_scheme_mid});
fprintf('  지연 개선: %.1f%% (%.2f ms → %.2f ms)\n', ...
    improvement_mid, mean_delay(mid_idx, 1), best_delay_mid);

std_improvement_mid = (1 - std_delay_metric(mid_idx, best_scheme_mid) / std_delay_metric(mid_idx, 1)) * 100;
fprintf('  분산 개선: %.1f%%\n', std_improvement_mid);

uora_improvement_mid = (1 - mean_uora(mid_idx, best_scheme_mid) / mean_uora(mid_idx, 1)) * 100;
fprintf('  T_uora 개선: %.1f%%\n', uora_improvement_mid);

%% =====================================================================
%  9. 완료
%  =====================================================================

fprintf('\n🎉 Experiment 2-1 완료!\n');
fprintf('   → 다음 단계: 가장 유망한 기법의 파라미터 최적화 (Exp 2-2/2-3/2-4)\n\n');

%% =========================================================================
%  Helper Function
%  =========================================================================

function indicator = get_indicator(value)
    if value > 5
        indicator = '✓ 개선';
    elseif value > 0
        indicator = '소폭 개선';
    elseif value > -5
        indicator = '유사';
    else
        indicator = '✗ 악화';
    end
end