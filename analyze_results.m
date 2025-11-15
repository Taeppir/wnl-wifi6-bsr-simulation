%% analyze_policy_comparison.m
% run_policy_comparison.m (run_experiments.m)의 .mat 결과를
% 심층 분석하고 시각화하는 스크립트
%
% 분석 내용:
%   1. Baseline 대비 성능 개선율 (%) 계산
%   2. T_overhead (Gap)를 포함한 지연 분해 검증
%   3. 분석 계획 4.2 (핵심 지표) 테이블 출력
%   4. 분석 계획 4.3 (지연 분해) 테이블 출력
%   5. 핵심 지표 및 지연 분해 그래프 생성

clear; close all; clc;

%% =====================================================================
%  1. 데이터 로드
%  =====================================================================
fprintf('========================================\n');
fprintf('  정책 비교 결과 분석 시작\n');
fprintf('========================================\n\n');

% .mat 파일 자동 탐색
results_dir = 'results/policy_comparison';
mat_files = dir(fullfile(results_dir, 'policy_comp_results_*.mat'));
if isempty(mat_files)
    error('오류: ''%s'' 폴더에서 .mat 파일을 찾을 수 없습니다.\n먼저 run_policy_comparison.m (run_experiments.m)을 실행하세요.', results_dir);
end
% 가장 최신 파일 로드
[~, latest_idx] = max([mat_files.datenum]);
latest_file = fullfile(results_dir, mat_files(latest_idx).name);

fprintf('최신 결과 파일 로드:\n  %s\n\n', latest_file);
load(latest_file);

%% =====================================================================
%  2. 개선율 및 지연 분해 계산
%  =====================================================================

% --- 2.1: Baseline 대비 개선율 계산 ---
improvement_table = mean_table; % 구조 복사
baseline_metrics = mean_table(1, :); % 1번 행(Baseline) 추출

% 지표별로 개선율 계산
for m = 1:width(mean_table)
    metric_name = mean_table.Properties.VariableNames{m};
    
    % (현재값 - 베이스라인) / 베이스라인
    improvement = (mean_table.(metric_name) - baseline_metrics.(metric_name)) ./ baseline_metrics.(metric_name);
    
    % [중요] 지연(Delay)이나 충돌(Collision)은 낮을수록 좋음 (개선 = 음수)
    % 가독성을 위해 개선(감소)된 경우 양수로 표시
    if contains(metric_name, 'delay', 'IgnoreCase', true) || contains(metric_name, 'collision', 'IgnoreCase', true)
        improvement = improvement * -1;
    end
    
    improvement_table.(metric_name) = improvement * 100; % 퍼센트(%)로 변환
end

% --- 2.2: 지연 분해 (T_overhead 계산) ---
T_total = mean_table.mean_delay_ms;
T_uora = mean_table.mean_uora_delay_ms;
T_sched = mean_table.mean_sched_delay_ms;
T_frag = mean_table.mean_frag_delay_ms;

% T_overhead = T_total - (T_uora + T_sched + T_frag)
% (test_delay_decomposition에서 검증된 T_overhead(Gap) 계산)
T_overhead = T_total - (T_uora + T_sched + T_frag);

% 지연 분해 테이블 생성
delay_decomp_table = table(T_uora, T_sched, T_overhead, T_frag, T_total, ...
    'RowNames', scheme_names);

%% =====================================================================
%  3. 콘솔 결과 출력
%  =====================================================================

% --- 4.2 핵심 결과 지표 ---
fprintf('─────────────────────────────────────────────────────────────────────────────────\n');
fprintf('  4.2 핵심 결과 지표 (평균, %d회 실행)\n', num_runs);
fprintf('─────────────────────────────────────────────────────────────────────────────────\n');
core_metrics_vars = {'mean_delay_ms', 'p90_delay_ms', 'collision_rate', 'implicit_bsr_ratio', 'throughput_mbps'};
disp(mean_table(:, core_metrics_vars));

% --- 핵심 지표 개선율 ---
fprintf('\n─────────────────────────────────────────────────────────────────────────────────\n');
fprintf('  [참고] 핵심 지표 개선율 (Baseline 대비, +가 좋음)\n');
fprintf('─────────────────────────────────────────────────────────────────────────────────\n');
disp(improvement_table(:, core_metrics_vars));

% --- 4.3 지연 분해 분석 ---
fprintf('\n─────────────────────────────────────────────────────────────────────────────────\n');
fprintf('  4.3 지연 분해 분석 (평균, ms)\n');
fprintf('─────────────────────────────────────────────────────────────────────────────────\n');
disp(delay_decomp_table);


%% =====================================================================
%  4. 시각화
%  =====================================================================

fprintf('\n그래프 생성 중...\n');

% --- Figure 1: 4.2 핵심 결과 지표 (대시보드) ---
figure('Name', '4.2 핵심 결과 지표', 'Position', [100, 100, 1000, 800]);

% 1. 평균 큐잉 지연 (T_queuing)
subplot(2, 2, 1);
b1 = bar(mean_table.mean_delay_ms, 'FaceColor', [0.3, 0.6, 0.9]);
hold on;
% 표준편차(std)를 에러바로 추가
errorbar(1:4, mean_table.mean_delay_ms, std_table.mean_delay_ms, ...
    'k.', 'LineWidth', 1.5);
set(gca, 'XTickLabel', scheme_names);
title('평균 큐잉 지연 (ms) [↓ 낮을수록 좋음]');
ylabel('지연 (ms)');
grid on;

% 2. UORA 충돌률
subplot(2, 2, 2);
b2 = bar(mean_table.collision_rate, 'FaceColor', [0.8, 0.2, 0.2]);
hold on;
errorbar(1:4, mean_table.collision_rate, std_table.collision_rate, ...
    'k.', 'LineWidth', 1.5);
set(gca, 'XTickLabel', scheme_names);
title('UORA 충돌률 (%) [↓ 낮을수록 좋음]');
ylabel('충돌률 (%)');
grid on;

% 3. Implicit BSR 비율
subplot(2, 2, 3);
b3 = bar(mean_table.implicit_bsr_ratio, 'FaceColor', [0.2, 0.5, 0.9]);
hold on;
errorbar(1:4, mean_table.implicit_bsr_ratio, std_table.implicit_bsr_ratio, ...
    'k.', 'LineWidth', 1.5);
set(gca, 'XTickLabel', scheme_names);
title('Implicit BSR 비율 (%) [↑ 높을수록 좋음]');
ylabel('비율 (%)');
grid on;

% 4. 처리율 (Throughput)
subplot(2, 2, 4);
b4 = bar(mean_table.throughput_mbps, 'FaceColor', [0.3, 0.8, 0.3]);
hold on;
errorbar(1:4, mean_table.throughput_mbps, std_table.throughput_mbps, ...
    'k.', 'LineWidth', 1.5);
set(gca, 'XTickLabel', scheme_names);
title('처리율 (Mbps) [유지/↑ 높을수록 좋음]');
ylabel('Mbps');
grid on;

sgtitle('4.2 핵심 결과 지표 분석 (평균 ± 표준편차)', 'FontSize', 16, 'FontWeight', 'bold');


% --- Figure 2: 4.3 지연 분해 분석 (Stacked Bar) ---
figure('Name', '4.3 지연 분해 분석', 'Position', [200, 200, 1000, 600]);

% 스택 데이터 준비: [T_uora, T_sched, T_overhead, T_frag]
stack_data = [
    delay_decomp_table.T_uora, ...
    delay_decomp_table.T_sched, ...
    delay_decomp_table.T_overhead, ...
    delay_decomp_table.T_frag
];

% 스택 바 그래프
bar(stack_data, 'stacked');
set(gca, 'XTickLabel', scheme_names);
ylabel('지연 (ms)');
title('4.3 지연 분해 분석 (평균)', 'FontSize', 16, 'FontWeight', 'bold');
legend({'T_uora (경쟁)', 'T_sched (대기)', 'T_overhead (Gap)', 'T_frag (분할)'}, ...
    'Location', 'northeastoutside');
grid on;
hold on;

% [검증] 스택의 총 합(T_uora+...+T_frag)과 실제 T_total을 비교
% T_total을 빨간색 라인으로 표시
plot(1:4, delay_decomp_table.T_total, 'r-o', ...
    'LineWidth', 2.5, 'MarkerFaceColor', 'r', 'DisplayName', 'T_total (실제 큐잉 지연)');

fprintf('\n  [검증] Figure 2에서 스택 그래프의 총 높이와 빨간색 T_total 라인이 일치해야 합니다.\n');
fprintf('🎉 분석 완료!\n\n');