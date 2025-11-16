%% analyze_exp1_02_burst_sweep.m
% Experiment 1-2 분석: 버스트 강도(rho, alpha) 스윕
%
% [수정]
%   - 'analyze_exp1_01_unsaturated.m'와 동일한 분석 지표를 플로팅
%   - (T_uora / T_total) 지연 비율 계산 로직 추가
%   - min() 함수 'omitnan' 문법 오류 수정

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 1-2: 버스트 강도 스윕 분석\n');
fprintf('========================================\n\n');

exp = load_experiment('exp1_2_burst_sweep');

% 축 정보
rho_range = exp.config.sweep_range;      % rho (On-state Ratio, X축)
alpha_range = exp.config.sweep_range2;   % alpha (Pareto Shape, 라인)

n_rho = length(rho_range);
n_alpha = length(alpha_range);

% --- [수정] Raw Data 로드 (UORA 비율 계산용) ---
raw_total_delay = exp.raw_data.mean_delay_ms;
raw_uora_delay = exp.raw_data.mean_uora_delay_ms;

% --- Summary Mean 데이터 추출 ---
mean_delay = exp.summary.mean.mean_delay_ms;
std_delay = exp.summary.mean.std_delay_ms;
mean_uora_delay = exp.summary.mean.mean_uora_delay_ms;
collision_rate = exp.summary.mean.collision_rate * 100; % Percent
completion_rate = exp.summary.mean.completion_rate * 100; % Percent
implicit_bsr = exp.summary.mean.implicit_bsr_ratio * 100; % Percent

% Buffer Empty (있으면 사용)
if isfield(exp.summary.mean, 'buffer_empty_ratio')
    buffer_empty = exp.summary.mean.buffer_empty_ratio * 100; % Percent
    has_buffer_empty = true;
else
    buffer_empty = nan(size(mean_delay));
    has_buffer_empty = false;
    warning('buffer_empty_ratio가 결과에 없습니다.');
end

%% =====================================================================
%  2. [신규] UORA 지연 비율 계산 (Exp 1-1 방식)
%  =====================================================================

% (T_uora / T_total) 비율을 Run별로 계산
% (0/0 방지: T_total이 0일 경우 NaN이 되도록)
raw_total_delay_safe = raw_total_delay;
raw_total_delay_safe(raw_total_delay == 0) = NaN;

% raw_uora_ratios_pct의 크기: [n_rho, n_alpha, num_runs]
raw_uora_ratios_pct = (raw_uora_delay ./ raw_total_delay_safe) * 100; 

% 3번째 차원(num_runs)을 기준으로 평균 및 표준편차 계산
% mean_uora_ratio의 크기: [n_rho, n_alpha]
mean_uora_ratio = mean(raw_uora_ratios_pct, 3, 'omitnan');
std_uora_ratio = std(raw_uora_ratios_pct, 0, 3, 'omitnan');


%% =====================================================================
%  3. 시각화 (6-Panel Line Graph)
%  =====================================================================
fprintf('[Line Graph 생성 중...]\n');

fig_lines = figure('Position', [100, 100, 1000, 1200]);

% 범례(Legend) 생성을 위한 문자열
legend_labels = cell(n_alpha, 1);
for i_a = 1:n_alpha
    legend_labels{i_a} = sprintf('alpha = %.2f', alpha_range(i_a));
end

% 색상
colors = lines(n_alpha);

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: 평균 큐잉 지연 (ms)
% (analyze_exp1_01_unsaturated.m의 Subplot 1과 동일)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 1);
hold on;
for i_a = 1:n_alpha
    % mean_delay는 [n_rho, n_alpha] 크기
    plot(rho_range, mean_delay(:, i_a), 'o-', ...
        'LineWidth', 1.5, 'Color', colors(i_a,:));
end
hold off;
grid on;
title('평균 큐잉 지연 (ms)');
xlabel('\rho (On-state Ratio)');
ylabel('Delay (ms)');
legend(legend_labels, 'Location', 'best');
set(gca, 'XTick', rho_range);

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: 평균 UORA 지연 (ms)
% (analyze_exp1_01_unsaturated.m의 Subplot 2와 동일)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 2);
hold on;
for i_a = 1:n_alpha
    plot(rho_range, mean_uora_delay(:, i_a), 'o-', ...
        'LineWidth', 1.5, 'Color', colors(i_a,:));
end
hold off;
grid on;
title('UORA 지연 (경쟁 강도, ms)');
xlabel('\rho (On-state Ratio)');
ylabel('UORA Delay (ms)');
legend(legend_labels, 'Location', 'best');
set(gca, 'XTick', rho_range);

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: UORA 충돌률 (%)
% (analyze_exp1_01_unsaturated.m의 Subplot 4(우측)와 동일)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 3);
hold on;
for i_a = 1:n_alpha
    plot(rho_range, collision_rate(:, i_a), 'o-', ...
        'LineWidth', 1.5, 'Color', colors(i_a,:));
end
hold off;
grid on;
title('UORA 충돌률 (%)');
xlabel('\rho (On-state Ratio)');
ylabel('Collision Rate (%)');
legend(legend_labels, 'Location', 'best');
set(gca, 'XTick', rho_range);

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: 버퍼 비어있음 비율 (%)
% (analyze_exp1_01_unsaturated.m의 Subplot 6과 동일)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 4);
hold on;
if has_buffer_empty
    for i_a = 1:n_alpha
        plot(rho_range, buffer_empty(:, i_a), 'o-', ...
            'LineWidth', 1.5, 'Color', colors(i_a,:));
    end
    ylim([0, 100]);
else
    text(0.5, 0.5, 'N/A (buffer_empty_ratio)', ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'r');
end
hold off;
grid on;
title('버퍼 비어있음 비율 (%)');
xlabel('\rho (On-state Ratio)');
ylabel('Buffer Empty (%)');
legend(legend_labels, 'Location', 'best');
set(gca, 'XTick', rho_range);

% ─────────────────────────────────────────────────────────────────────
% Subplot 5: UORA 지연 비율 (T_uora / T_total) (%)
% (analyze_exp1_01_unsaturated.m의 Subplot 5와 동일)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 5);
hold on;
for i_a = 1:n_alpha
    % Bar 대신 Line으로 플롯
    plot(rho_range, mean_uora_ratio(:, i_a), 'o-', ...
         'LineWidth', 1.5, 'Color', colors(i_a,:));
end
hold off;
grid on;
title('UORA 지연 비율 (T_{uora} / T_{total}, Run별 계산)');
xlabel('\rho (On-state Ratio)');
ylabel('Ratio (%)');
legend(legend_labels, 'Location', 'best');
set(gca, 'XTick', rho_range);
ylim([0, 105]);

% ─────────────────────────────────────────────────────────────────────
% Subplot 6: 패킷 완료율 (%)
% (analyze_exp1_01_unsaturated.m의 Subplot 4(좌측)와 동일)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 6);
hold on;
for i_a = 1:n_alpha
    plot(rho_range, completion_rate(:, i_a), 'o-', ...
        'LineWidth', 1.5, 'Color', colors(i_a,:));
end
hold off;
grid on;
title('패킷 완료율 (%)');
xlabel('\rho (On-state Ratio)');
ylabel('Completion Rate (%)');
legend(legend_labels, 'Location', 'best');
set(gca, 'XTick', rho_range);

% [오류 수정] min(A, 'omitnan') -> min(A, [], 'omitnan')
min_scalar = min(completion_rate(:), [], 'omitnan');
min_val = min(min_scalar, 80); % Y축 하한을 80으로 제한
ylim([min_val, 100]);

% ─────────────────────────────────────────────────────────────────────
% 전체 제목
% ─────────────────────────────────────────────────────────────────────
sgtitle(sprintf('Exp 1-2: 버스트 강도(rho, alpha) 분석 (L_{cell}=%.1f)', ...
    exp.config.fixed.L_cell), 'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  4. 저장 (파일 이름 변경)
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fig_filename_png = sprintf('%s/exp1_2_burst_sweep_analysis_lines.png', fig_dir);
fig_filename_pdf = sprintf('%s/exp1_2_burst_sweep_analysis_lines.pdf', fig_dir);

saveas(fig_lines, fig_filename_png);
fprintf('  ✓ Line Graph (PNG) 저장: %s\n', fig_filename_png);

% PDF도 저장 (고품질)
exportgraphics(fig_lines, fig_filename_pdf, 'ContentType', 'vector');
fprintf('  ✓ Line Graph (PDF) 저장: %s\n', fig_filename_pdf);


fprintf('\n🎉 분석 완료!\n\n');