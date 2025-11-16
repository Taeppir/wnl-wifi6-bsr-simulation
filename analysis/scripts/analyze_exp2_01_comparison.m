%% analyze_exp2_01_comparison.m
% Experiment 2-1 분석: 정책 비교
%
% 시각화:
%   - 시나리오별 Grouped Bar Chart
%   - 개선률 표시
%   - 지연 분해 비교

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 2-1: 정책 비교 분석\n');
fprintf('========================================\n\n');

% MAT 파일 로드
mat_files = dir('results/mat/exp2_1_scheme_comparison_*.mat');
if isempty(mat_files)
    error('결과 파일을 찾을 수 없습니다!');
end

% 가장 최신 파일 선택
[~, latest_idx] = max([mat_files.datenum]);
mat_file = fullfile(mat_files(latest_idx).folder, mat_files(latest_idx).name);

fprintf('[로드] %s\n', mat_files(latest_idx).name);
loaded = load(mat_file);
results = loaded.results;

%% =====================================================================
%  2. 데이터 추출
%  =====================================================================

n_scenarios = length(results.config.scenarios);
n_schemes = length(results.config.schemes);

scenario_names = {results.config.scenarios.name};
scheme_names = results.config.scheme_names;

% Summary 데이터 [scenario, scheme]
mean_delay = results.summary.mean.mean_delay_ms;
p90_delay = results.summary.mean.p90_delay_ms;
mean_uora_delay = results.summary.mean.mean_uora_delay_ms;
mean_collision = results.summary.mean.collision_rate;
mean_explicit_bsr = results.summary.mean.explicit_bsr_count;
mean_implicit_ratio = results.summary.mean.implicit_bsr_ratio;
mean_completion = results.summary.mean.completion_rate;

std_delay = results.summary.std.mean_delay_ms;
std_uora_delay = results.summary.std.mean_uora_delay_ms;

fprintf('  데이터 크기: %s\n', mat2str(size(mean_delay)));

%% =====================================================================
%  3. 시각화 (Grouped Bar Charts)
%  =====================================================================

fprintf('\n[시각화 생성 중...]\n');

fig = figure('Position', [100, 100, 1800, 1000]);

% 색상 설정 (스킴별)
colors = [
    0.5, 0.5, 0.5;   % Baseline: 회색
    0.0, 0.4, 0.7;   % Scheme 1: 파랑
    0.8, 0.4, 0.0;   % Scheme 2: 주황
    0.0, 0.6, 0.5    % Scheme 3: 청록
];

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: Mean Delay (Grouped Bar + Error Bar)
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 1);
b = bar(mean_delay');
for i = 1:n_schemes
    b(i).FaceColor = colors(i, :);
end
hold on;

% Error bars 추가
x_offset = [-0.3, -0.1, 0.1, 0.3];  % 4개 스킴
for s = 1:n_scenarios
    for sc = 1:n_schemes
        x_pos = s + x_offset(sc);
        errorbar(x_pos, mean_delay(s, sc), std_delay(s, sc), ...
            'k.', 'LineWidth', 1.5, 'CapSize', 8);
    end
end

set(gca, 'XTickLabel', scenario_names);
ylabel('Mean Delay [ms]', 'FontSize', 11);
title('평균 큐잉 지연', 'FontSize', 13, 'FontWeight', 'bold');
legend(scheme_names, 'Location', 'northwest', 'FontSize', 9);
grid on;
hold off;

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: P90 Delay
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 2);
b = bar(p90_delay');
for i = 1:n_schemes
    b(i).FaceColor = colors(i, :);
end

set(gca, 'XTickLabel', scenario_names);
ylabel('P90 Delay [ms]', 'FontSize', 11);
title('P90 큐잉 지연', 'FontSize', 13, 'FontWeight', 'bold');
legend(scheme_names, 'Location', 'northwest', 'FontSize', 9);
grid on;

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: UORA Delay
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 3);
b = bar(mean_uora_delay');
for i = 1:n_schemes
    b(i).FaceColor = colors(i, :);
end

set(gca, 'XTickLabel', scenario_names);
ylabel('UORA Delay [ms]', 'FontSize', 11);
title('평균 UORA 지연', 'FontSize', 13, 'FontWeight', 'bold');
legend(scheme_names, 'Location', 'northwest', 'FontSize', 9);
grid on;

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: Collision Rate
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 4);
b = bar(mean_collision' * 100);
for i = 1:n_schemes
    b(i).FaceColor = colors(i, :);
end

set(gca, 'XTickLabel', scenario_names);
ylabel('Collision Rate [%]', 'FontSize', 11);
title('충돌률', 'FontSize', 13, 'FontWeight', 'bold');
legend(scheme_names, 'Location', 'northwest', 'FontSize', 9);
grid on;

% ─────────────────────────────────────────────────────────────────────
% Subplot 5: Explicit BSR Count
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 5);
b = bar(mean_explicit_bsr');
for i = 1:n_schemes
    b(i).FaceColor = colors(i, :);
end

set(gca, 'XTickLabel', scenario_names);
ylabel('Explicit BSR Count', 'FontSize', 11);
title('Explicit BSR 발생 횟수', 'FontSize', 13, 'FontWeight', 'bold');
legend(scheme_names, 'Location', 'northwest', 'FontSize', 9);
grid on;

% ─────────────────────────────────────────────────────────────────────
% Subplot 6: Delay Reduction (%) - Baseline 대비
% ─────────────────────────────────────────────────────────────────────
subplot(2, 3, 6);

baseline_idx = 1;
delay_reduction = zeros(n_scenarios, n_schemes-1);

for s = 1:n_scenarios
    baseline = mean_delay(s, baseline_idx);
    for sc = 2:n_schemes
        delay_reduction(s, sc-1) = (1 - mean_delay(s, sc) / baseline) * 100;
    end
end

b = bar(delay_reduction');
for i = 1:n_schemes-1
    b(i).FaceColor = colors(i+1, :);
end

set(gca, 'XTickLabel', scenario_names);
ylabel('Delay Reduction [%]', 'FontSize', 11);
title('지연 감소율 (Baseline 대비)', 'FontSize', 13, 'FontWeight', 'bold');
legend(scheme_names(2:end), 'Location', 'northwest', 'FontSize', 9);
grid on;
yline(0, 'k--', 'LineWidth', 1.5);

% ─────────────────────────────────────────────────────────────────────
% 전체 제목
% ─────────────────────────────────────────────────────────────────────
sgtitle('Exp 2-1: Scheme Comparison', 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  4. 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fig_filename = sprintf('%s/exp2_1_comparison.png', fig_dir);
saveas(fig, fig_filename);
fprintf('  ✓ Figure 저장: %s\n', fig_filename);

fig_filename_pdf = sprintf('%s/exp2_1_comparison.pdf', fig_dir);
exportgraphics(fig, fig_filename_pdf, 'ContentType', 'vector');
fprintf('  ✓ PDF 저장: %s\n', fig_filename_pdf);

%% =====================================================================
%  5. 상세 통계 출력
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  상세 통계\n');
fprintf('========================================\n\n');

for s = 1:n_scenarios
    fprintf('[%s (L_cell=%.2f)]\n', scenario_names{s}, ...
        results.config.scenarios(s).L_cell);
    fprintf('%-25s | %10s | %10s | %10s | %12s | %10s\n', ...
        'Scheme', 'Delay[ms]', 'P90[ms]', 'Coll[%]', 'Exp_BSR', 'Compl[%]');
    fprintf('%s\n', repmat('-', 1, 95));
    
    for sc = 1:n_schemes
        fprintf('%-25s | %10.2f | %10.2f | %10.1f | %12.0f | %10.1f\n', ...
            scheme_names{sc}, ...
            mean_delay(s, sc), ...
            p90_delay(s, sc), ...
            mean_collision(s, sc) * 100, ...
            mean_explicit_bsr(s, sc), ...
            mean_completion(s, sc) * 100);
    end
    
    % 개선률 계산
    fprintf('\n[개선률 (Baseline 대비)]\n');
    baseline_delay = mean_delay(s, baseline_idx);
    baseline_coll = mean_collision(s, baseline_idx);
    baseline_exp = mean_explicit_bsr(s, baseline_idx);
    
    for sc = 2:n_schemes
        fprintf('  %s:\n', scheme_names{sc});
        fprintf('    - Delay: %.1f%% 감소\n', ...
            (1 - mean_delay(s, sc) / baseline_delay) * 100);
        fprintf('    - Collision: %.1f%% 감소\n', ...
            (1 - mean_collision(s, sc) / baseline_coll) * 100);
        fprintf('    - Explicit BSR: %.1f%% 감소\n', ...
            (1 - mean_explicit_bsr(s, sc) / baseline_exp) * 100);
    end
    fprintf('\n');
end

fprintf('🎉 분석 완료!\n\n');