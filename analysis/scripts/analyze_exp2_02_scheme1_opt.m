%% analyze_exp2_02_scheme1_opt.m
% Experiment 2-2: Scheme 1 파라미터 최적화 분석
%
% [특징]
%   - 1D 스윕 결과 분석
%   - 선 그래프 중심 (히트맵 없음!)
%   - 주요 지표: 지연, 충돌률, BSR 비율

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 2-2: Scheme 1 최적화 분석\n');
fprintf('========================================\n\n');

% MAT 파일 로드
mat_files = dir('results/mat/exp2_2_scheme1_optimization_*.mat');
if isempty(mat_files)
    error('결과 파일을 찾을 수 없습니다!');
end

[~, latest_idx] = max([mat_files.datenum]);
mat_file = fullfile(mat_files(latest_idx).folder, mat_files(latest_idx).name);

fprintf('[로드] %s\n', mat_files(latest_idx).name);
loaded = load(mat_file);
results = loaded.results;

%% =====================================================================
%  2. 데이터 추출
%  =====================================================================

% 스윕 변수 확인
sweep_var = results.config.sweep_var;
sweep_values = results.config.sweep_range;
n_points = length(sweep_values);

fprintf('  스윕 변수: %s\n', sweep_var);
fprintf('  스윕 범위: %s\n', mat2str(sweep_values));
fprintf('  데이터 포인트: %d\n\n', n_points);

% Summary 데이터 추출
mean_delay = results.summary.mean.mean_delay_ms;
std_delay = results.summary.std.mean_delay_ms;
p90_delay = results.summary.mean.p90_delay_ms;

mean_uora_delay = results.summary.mean.mean_uora_delay_ms;
mean_sched_delay = results.summary.mean.mean_sched_delay_ms;
mean_frag_delay = results.summary.mean.mean_frag_delay_ms;

mean_collision = results.summary.mean.collision_rate;
std_collision = results.summary.std.collision_rate;

mean_explicit_bsr = results.summary.mean.explicit_bsr_count;
mean_implicit_bsr = results.summary.mean.implicit_bsr_count;
mean_implicit_ratio = results.summary.mean.implicit_bsr_ratio;

mean_throughput = results.summary.mean.throughput_mbps;
mean_completion = results.summary.mean.completion_rate;

% ⭐ 디버깅: 데이터 크기 확인
fprintf('\n[디버깅] 데이터 크기 확인:\n');
fprintf('  sweep_values: %s\n', mat2str(size(sweep_values)));
fprintf('  mean_delay: %s\n', mat2str(size(mean_delay)));
fprintf('  p90_delay: %s\n', mat2str(size(p90_delay)));
fprintf('  mean_uora_delay: %s\n', mat2str(size(mean_uora_delay)));
fprintf('  mean_collision: %s\n', mat2str(size(mean_collision)));

% ⭐ 전체 데이터 출력
if size(mean_delay, 2) > 1
    fprintf('\n[전체 데이터 매트릭스]\n');
    fprintf('Mean Delay [3x3]:\n');
    disp(mean_delay);
    fprintf('Collision Rate [3x3]:\n');
    disp(mean_collision);
    fprintf('Implicit BSR Ratio [3x3]:\n');
    disp(mean_implicit_ratio);
end

% ⭐ 수정: 2D 데이터를 1D로 변환
if size(mean_delay, 2) > 1
    fprintf('\n⚠️  경고: 1D 실험인데 데이터가 2D로 저장됨. 첫 번째 열만 사용합니다.\n\n');
    mean_delay = mean_delay(:, 1);
    std_delay = std_delay(:, 1);
    p90_delay = p90_delay(:, 1);
    
    mean_uora_delay = mean_uora_delay(:, 1);
    mean_sched_delay = mean_sched_delay(:, 1);
    mean_frag_delay = mean_frag_delay(:, 1);
    
    mean_collision = mean_collision(:, 1);
    std_collision = std_collision(:, 1);
    
    mean_explicit_bsr = mean_explicit_bsr(:, 1);
    mean_implicit_bsr = mean_implicit_bsr(:, 1);
    mean_implicit_ratio = mean_implicit_ratio(:, 1);
    
    mean_throughput = mean_throughput(:, 1);
    mean_completion = mean_completion(:, 1);
end
fprintf('\n');

%% =====================================================================
%  3. 시각화 설정
%  =====================================================================

% 색상 정의
color_delay = [0.2, 0.4, 0.8];      % 파란색 - 지연
color_uora = [0.8, 0.3, 0.3];       % 빨간색 - UORA
color_collision = [0.9, 0.6, 0.0];  % 주황색 - 충돌
color_bsr = [0.3, 0.7, 0.3];        % 녹색 - BSR

% 마커 스타일
marker_style = 'o-';
marker_size = 8;
line_width = 2;

%% =====================================================================
%  4. Figure 1: 지연 분석 (2x2)
%  =====================================================================

figure('Position', [100, 100, 1400, 1000]);

% 4-1. Mean Delay (with error bars)
subplot(2, 2, 1);
errorbar(sweep_values(:), mean_delay(:), std_delay(:), marker_style, ...
    'Color', color_delay, 'LineWidth', line_width, 'MarkerSize', marker_size);
grid on;
xlabel(sweep_var, 'Interpreter', 'none');
ylabel('Mean Delay (ms)');
title('(a) Mean Delay with Std Dev');
set(gca, 'FontSize', 11);

% 4-2. P90 Delay
subplot(2, 2, 2);
plot(sweep_values(:), p90_delay(:), marker_style, ...
    'Color', color_delay, 'LineWidth', line_width, 'MarkerSize', marker_size);
grid on;
xlabel(sweep_var, 'Interpreter', 'none');
ylabel('P90 Delay (ms)');
title('(b) P90 Delay');
set(gca, 'FontSize', 11);

% 4-3. Delay Decomposition (Stacked Area)
subplot(2, 2, 3);
area_data = [mean_uora_delay(:), mean_sched_delay(:), mean_frag_delay(:)];
h_area = area(sweep_values(:), area_data);
set(h_area(1), 'FaceColor', [0.8, 0.3, 0.3]);  % UORA - 빨강
set(h_area(2), 'FaceColor', [0.3, 0.6, 0.8]);  % Sched - 파랑
set(h_area(3), 'FaceColor', [0.9, 0.7, 0.3]);  % Frag - 노랑
grid on;
xlabel(sweep_var, 'Interpreter', 'none');
ylabel('Delay (ms)');
title('(c) Delay Decomposition (Stacked)');
legend({'T_{UORA}', 'T_{Sched}', 'T_{Frag}'}, 'Location', 'best');
set(gca, 'FontSize', 11);

% 4-4. UORA Delay Ratio
subplot(2, 2, 4);
uora_ratio = mean_uora_delay ./ mean_delay * 100;
plot(sweep_values(:), uora_ratio(:), marker_style, ...
    'Color', color_uora, 'LineWidth', line_width, 'MarkerSize', marker_size);
grid on;
xlabel(sweep_var, 'Interpreter', 'none');
ylabel('UORA Delay Ratio (%)');
title('(d) UORA Delay Contribution');
ylim([0, 100]);
set(gca, 'FontSize', 11);

sgtitle('Delay Analysis', 'FontSize', 14, 'FontWeight', 'bold');

%% =====================================================================
%  5. Figure 2: 성능 지표 (2x2)
%  =====================================================================

figure('Position', [150, 150, 1400, 1000]);

% 5-1. Collision Rate
subplot(2, 2, 1);
errorbar(sweep_values(:), mean_collision(:), std_collision(:), marker_style, ...
    'Color', color_collision, 'LineWidth', line_width, 'MarkerSize', marker_size);
grid on;
xlabel(sweep_var, 'Interpreter', 'none');
ylabel('Collision Rate');
title('(a) Collision Rate');
ylim([0, max(mean_collision(:)) * 1.2]);
set(gca, 'FontSize', 11);

% 5-2. Throughput
subplot(2, 2, 2);
plot(sweep_values(:), mean_throughput(:), marker_style, ...
    'Color', color_delay, 'LineWidth', line_width, 'MarkerSize', marker_size);
grid on;
xlabel(sweep_var, 'Interpreter', 'none');
ylabel('Throughput (Mbps)');
title('(b) System Throughput');
set(gca, 'FontSize', 11);

% 5-3. Completion Rate
subplot(2, 2, 3);
plot(sweep_values(:), mean_completion(:) * 100, marker_style, ...
    'Color', [0.5, 0.3, 0.7], 'LineWidth', line_width, 'MarkerSize', marker_size);
grid on;
xlabel(sweep_var, 'Interpreter', 'none');
ylabel('Completion Rate (%)');
title('(c) Completion Rate');
ylim([90, 100]);
set(gca, 'FontSize', 11);

% 5-4. BSR Counts
subplot(2, 2, 4);
yyaxis left
plot(sweep_values(:), mean_explicit_bsr(:), 'o-', ...
    'Color', [0.8, 0.3, 0.3], 'LineWidth', line_width, 'MarkerSize', marker_size);
ylabel('Explicit BSR Count');
set(gca, 'YColor', [0.8, 0.3, 0.3]);

yyaxis right
plot(sweep_values(:), mean_implicit_bsr(:), 's-', ...
    'Color', [0.3, 0.7, 0.3], 'LineWidth', line_width, 'MarkerSize', marker_size);
ylabel('Implicit BSR Count');
set(gca, 'YColor', [0.3, 0.7, 0.3]);

grid on;
xlabel(sweep_var, 'Interpreter', 'none');
title('(d) BSR Counts');
legend({'Explicit', 'Implicit'}, 'Location', 'best');
set(gca, 'FontSize', 11);

sgtitle('Performance Metrics', 'FontSize', 14, 'FontWeight', 'bold');

%% =====================================================================
%  6. Figure 3: BSR 분석 (1x2)
%  =====================================================================

figure('Position', [200, 200, 1400, 500]);

% 6-1. BSR Composition (Stacked Bar)
subplot(1, 2, 1);
bsr_data = [mean_explicit_bsr(:), mean_implicit_bsr(:)];
h_bar = bar(sweep_values(:), bsr_data, 'stacked');
set(h_bar(1), 'FaceColor', [0.8, 0.3, 0.3]);  % Explicit - 빨강
set(h_bar(2), 'FaceColor', [0.3, 0.7, 0.3]);  % Implicit - 녹색
grid on;
xlabel(sweep_var, 'Interpreter', 'none');
ylabel('BSR Count');
title('(a) BSR Composition');
legend({'Explicit', 'Implicit'}, 'Location', 'best');
set(gca, 'FontSize', 11);

% 6-2. Implicit BSR Ratio
subplot(1, 2, 2);
plot(sweep_values(:), mean_implicit_ratio(:) * 100, marker_style, ...
    'Color', color_bsr, 'LineWidth', line_width, 'MarkerSize', marker_size);
grid on;
xlabel(sweep_var, 'Interpreter', 'none');
ylabel('Implicit BSR Ratio (%)');
title('(b) Implicit BSR Ratio');
ylim([0, 100]);
set(gca, 'FontSize', 11);

sgtitle('BSR Analysis', 'FontSize', 14, 'FontWeight', 'bold');

%% =====================================================================
%  7. 수치 요약
%  =====================================================================

fprintf('========================================\n');
fprintf('  수치 요약\n');
fprintf('========================================\n\n');

% 최적값 찾기
[min_delay, min_idx] = min(mean_delay);
[min_collision, min_col_idx] = min(mean_collision);
[max_implicit, max_imp_idx] = max(mean_implicit_ratio);

fprintf('[최소 평균 지연]\n');
fprintf('  %s = %.4f → Mean Delay = %.2f ms\n', ...
    sweep_var, sweep_values(min_idx), min_delay);
fprintf('\n');

fprintf('[최소 충돌률]\n');
fprintf('  %s = %.4f → Collision Rate = %.4f\n', ...
    sweep_var, sweep_values(min_col_idx), min_collision);
fprintf('\n');

fprintf('[최대 Implicit BSR 비율]\n');
fprintf('  %s = %.4f → Implicit Ratio = %.2f%%\n', ...
    sweep_var, sweep_values(max_imp_idx), max_implicit * 100);
fprintf('\n');

% 전체 범위 통계
fprintf('[전체 범위 통계]\n');
fprintf('  Mean Delay: %.2f ~ %.2f ms (range: %.2f ms)\n', ...
    min(mean_delay), max(mean_delay), max(mean_delay) - min(mean_delay));
fprintf('  Collision Rate: %.4f ~ %.4f\n', ...
    min(mean_collision), max(mean_collision));
fprintf('  Implicit BSR: %.1f%% ~ %.1f%%\n', ...
    min(mean_implicit_ratio) * 100, max(mean_implicit_ratio) * 100);
fprintf('\n');

fprintf('분석 완료!\n');