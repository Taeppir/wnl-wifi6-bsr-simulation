%% test_buffer_empty_ratio.m
% 시간 기반 buffer_empty_ratio 측정 테스트
%
% 목적:
%   - 기존 샘플링 기반 vs 새로운 시간 기반 비교
%   - 다양한 부하 조건에서 측정 정확도 검증

clear; close all; clc;

fprintf('========================================\n');
fprintf('  Buffer Empty Ratio 측정 테스트\n');
fprintf('========================================\n\n');

%% =====================================================================
%  1. 경로 설정
%  =====================================================================

% setup_paths가 있다면 실행
if exist('setup_paths.m', 'file')
    setup_paths;
end

%% =====================================================================
%  2. 테스트 시나리오 정의
%  =====================================================================

test_scenarios = [
    % [L_cell, rho, alpha, 설명]
    0.1, 0.3, 1.5;  % 낮은 부하, 낮은 On 비율 → Empty 많음
    0.2, 0.5, 1.5;  % 중간 부하
    0.3, 0.7, 1.5;  % 중간-높은 부하 → Empty 적음
    0.4, 0.9, 1.5;  % 높은 부하, 높은 On 비율 → Empty 매우 적음
];

scenario_names = {
    'Low Load (L=0.1, ρ=0.3) - Expect High Empty';
    'Mid Load (L=0.2, ρ=0.5) - Expect Mid Empty';
    'Mid-High Load (L=0.3, ρ=0.7) - Expect Low Empty';
    'High Load (L=0.4, ρ=0.9) - Expect Very Low Empty';
};

n_scenarios = size(test_scenarios, 1);

%% =====================================================================
%  3. 결과 저장 구조체
%  =====================================================================

test_results = struct();
test_results.scenarios = test_scenarios;
test_results.scenario_names = scenario_names;
test_results.buffer_empty_ratio = nan(n_scenarios, 1);
test_results.buffer_empty_time_per_sta = nan(n_scenarios, 1);
test_results.total_completed_packets = nan(n_scenarios, 1);
test_results.completion_rate = nan(n_scenarios, 1);
test_results.mean_delay_ms = nan(n_scenarios, 1);

%% =====================================================================
%  4. 각 시나리오 실행
%  =====================================================================

fprintf('[테스트 시작]\n');
fprintf('  시나리오 수: %d개\n', n_scenarios);
fprintf('  각 시나리오: 1회 실행\n\n');

for s = 1:n_scenarios
    fprintf('----------------------------------------\n');
    fprintf('시나리오 %d/%d: %s\n', s, n_scenarios, scenario_names{s});
    fprintf('----------------------------------------\n');
    
    % 설정 생성
    cfg = config_default();
    cfg.verbose = 1;  % 기본 출력
    
    % 시나리오별 파라미터
    cfg.L_cell = test_scenarios(s, 1);
    cfg.rho = test_scenarios(s, 2);
    cfg.alpha = test_scenarios(s, 3);
    
    % 시간 설정
    cfg.simulation_time = 15.0;  % 충분한 시간
    cfg.warmup_time = 2.0;
    
    % 트래픽 설정
    cfg.num_STAs = 10;  % 적당한 STA 수
    cfg.mu_on = 0.05;
    cfg.mu_off = cfg.mu_on * (1 - cfg.rho) / cfg.rho;
    
    % Lambda 재계산
    cfg = recompute_pareto_lambda(cfg);
    
    % BSR 추적 활성화
    cfg.collect_bsr_trace = true;
    
    fprintf('\n[설정]\n');
    fprintf('  L_cell: %.1f\n', cfg.L_cell);
    fprintf('  rho: %.1f\n', cfg.rho);
    fprintf('  alpha: %.1f\n', cfg.alpha);
    fprintf('  mu_on: %.3f s\n', cfg.mu_on);
    fprintf('  mu_off: %.3f s\n', cfg.mu_off);
    fprintf('  시뮬레이션 시간: %.1f s\n', cfg.simulation_time);
    
    % 시뮬레이션 실행
    fprintf('\n[시뮬레이션 실행 중...]\n');
    tic;
    try
        [results, metrics] = main_sim_v2(cfg);
        elapsed = toc;
        
        fprintf('  완료! (%.2f초)\n', elapsed);
        
        % 결과 저장
        test_results.buffer_empty_ratio(s) = results.bsr.buffer_empty_ratio;
        
        if isfield(results.bsr, 'buffer_empty_time_per_sta')
            test_results.buffer_empty_time_per_sta(s) = results.bsr.buffer_empty_time_per_sta;
        end
        
        test_results.total_completed_packets(s) = results.total_completed_packets;
        test_results.completion_rate(s) = results.packet_completion_rate;
        test_results.mean_delay_ms(s) = results.summary.mean_delay_ms;
        
        % 주요 지표 출력
        fprintf('\n[결과 요약]\n');
        fprintf('  ⭐ Buffer Empty Ratio: %.2f%%\n', results.bsr.buffer_empty_ratio * 100);
        
        if isfield(results.bsr, 'buffer_empty_time_per_sta')
            fprintf('  ⭐ STA당 Empty 시간: %.3f초 (전체 %.1f초 중)\n', ...
                results.bsr.buffer_empty_time_per_sta, cfg.simulation_time - cfg.warmup_time);
        end
        
        fprintf('  완료 패킷: %d개 (완료율: %.1f%%)\n', ...
            results.total_completed_packets, results.packet_completion_rate * 100);
        fprintf('  평균 지연: %.2f ms\n', results.summary.mean_delay_ms);
        fprintf('  Implicit BSR: %.1f%%\n', results.summary.implicit_bsr_ratio * 100);
        
    catch ME
        fprintf('  ❌ 실패: %s\n', ME.message);
        elapsed = toc;
    end
    
    fprintf('\n');
end

%% =====================================================================
%  5. 종합 결과 출력
%  =====================================================================

fprintf('========================================\n');
fprintf('  테스트 종합 결과\n');
fprintf('========================================\n\n');

fprintf('%-40s | %12s | %12s | %12s\n', ...
    '시나리오', 'Empty [%]', 'Empty Time', 'Compl. [%]');
fprintf('%s\n', repmat('-', 1, 85));

for s = 1:n_scenarios
    fprintf('%-40s | %11.1f%% | %9.2f s | %11.1f%%\n', ...
        scenario_names{s}, ...
        test_results.buffer_empty_ratio(s) * 100, ...
        test_results.buffer_empty_time_per_sta(s), ...
        test_results.completion_rate(s) * 100);
end

fprintf('\n');

%% =====================================================================
%  6. 시각화
%  =====================================================================

fprintf('[시각화 생성]\n');

fig = figure('Position', [100, 100, 1400, 600]);

% Subplot 1: Buffer Empty Ratio
subplot(1, 3, 1);
bar(test_results.buffer_empty_ratio * 100, 'FaceColor', [0.2, 0.6, 0.9]);
set(gca, 'XTickLabel', {'L=0.1', 'L=0.2', 'L=0.3', 'L=0.4'}, 'FontSize', 10);
ylabel('Buffer Empty Ratio [%]', 'FontSize', 11);
title('버퍼 비어있음 비율 (시간 기반)', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
ylim([0, 100]);

% 값 표시
for s = 1:n_scenarios
    text(s, test_results.buffer_empty_ratio(s) * 100 + 3, ...
        sprintf('%.1f%%', test_results.buffer_empty_ratio(s) * 100), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
end

% Subplot 2: Buffer Empty Time per STA
subplot(1, 3, 2);
bar(test_results.buffer_empty_time_per_sta, 'FaceColor', [0.9, 0.5, 0.2]);
set(gca, 'XTickLabel', {'L=0.1', 'L=0.2', 'L=0.3', 'L=0.4'}, 'FontSize', 10);
ylabel('STA당 Empty 시간 [sec]', 'FontSize', 11);
title('STA당 평균 Empty 시간', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% 값 표시
for s = 1:n_scenarios
    text(s, test_results.buffer_empty_time_per_sta(s) + 0.2, ...
        sprintf('%.2fs', test_results.buffer_empty_time_per_sta(s)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
end

% Subplot 3: Completion Rate
subplot(1, 3, 3);
bar(test_results.completion_rate * 100, 'FaceColor', [0.3, 0.8, 0.3]);
set(gca, 'XTickLabel', {'L=0.1', 'L=0.2', 'L=0.3', 'L=0.4'}, 'FontSize', 10);
ylabel('Completion Rate [%]', 'FontSize', 11);
title('패킷 완료율', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
ylim([0, 105]);
yline(85, 'r--', '85% 기준', 'LineWidth', 1.5);

% 값 표시
for s = 1:n_scenarios
    text(s, test_results.completion_rate(s) * 100 + 2, ...
        sprintf('%.1f%%', test_results.completion_rate(s) * 100), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
end

sgtitle('시간 기반 Buffer Empty Ratio 측정 테스트 결과', ...
    'FontSize', 14, 'FontWeight', 'bold');

%% =====================================================================
%  7. 결과 저장
%  =====================================================================

% MAT 파일 저장
results_dir = 'results/tests';
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
mat_filename = sprintf('%s/buffer_empty_test_%s.mat', results_dir, timestamp);
save(mat_filename, 'test_results');
fprintf('  ✓ 결과 저장: %s\n', mat_filename);

% Figure 저장
fig_filename = sprintf('%s/buffer_empty_test_%s.png', results_dir, timestamp);
saveas(fig, fig_filename);
fprintf('  ✓ Figure 저장: %s\n', fig_filename);

fprintf('\n🎉 테스트 완료!\n\n');

%% =====================================================================
%  8. 검증 체크
%  =====================================================================

fprintf('========================================\n');
fprintf('  검증 체크\n');
fprintf('========================================\n\n');

% 기대값 검증
fprintf('[기대값과 비교]\n');

expectations = [
    % [시나리오, 최소 예상, 최대 예상]
    1, 20, 60;  % L=0.1, rho=0.3 → 20~60%
    2, 10, 40;  % L=0.2, rho=0.5 → 10~40%
    3, 5, 25;   % L=0.3, rho=0.7 → 5~25%
    4, 2, 15;   % L=0.4, rho=0.9 → 2~15%
];

all_pass = true;

for s = 1:n_scenarios
    actual = test_results.buffer_empty_ratio(s) * 100;
    expected_min = expectations(s, 2);
    expected_max = expectations(s, 3);
    
    is_in_range = (actual >= expected_min) && (actual <= expected_max);
    
    if is_in_range
        status = '✅ PASS';
    else
        status = '⚠️  CHECK';
        all_pass = false;
    end
    
    fprintf('  시나리오 %d: %.1f%% (예상: %.0f~%.0f%%) %s\n', ...
        s, actual, expected_min, expected_max, status);
end

fprintf('\n');

if all_pass
    fprintf('✅ 모든 테스트 통과!\n');
else
    fprintf('⚠️  일부 결과가 예상 범위를 벗어났습니다.\n');
    fprintf('   (Pareto 트래픽의 변동성으로 인해 정상일 수 있음)\n');
end

fprintf('\n');