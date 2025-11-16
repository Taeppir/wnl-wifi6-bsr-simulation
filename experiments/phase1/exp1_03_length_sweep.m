%% exp1_03_on_length_sweep.m
% Experiment 1-3: ON-length(μ_on) 스윕 - Burst 길이 영향
%
% Research Question: 
%   Burst 길이(μ_on)가 Explicit BSR 발생 패턴과 지연에 미치는 영향은?
%
% 스윕 변수:
%   μ_on:   [0.01, 0.05, 0.1, 0.3, 0.5] (초)
%   L_cell: [0.35, 0.5]
%
% 고정 파라미터:
%   scheme_id = 0 (Baseline)
%   num_STAs = 20
%   alpha = 1.5
%   rho = 0.7

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

exp_config = get_exp1_03_config();

%% =====================================================================
%  2. 실험 실행
%  =====================================================================

results_grid = run_sweep_experiment(exp_config);

%% =====================================================================
%  3. 결과 저장
%  =====================================================================

save_experiment_results(results_grid, exp_config);

%% =====================================================================
%  4. Quick Plot
%  =====================================================================

quick_plot(results_grid, exp_config);

%% =====================================================================
%  5. 간단한 요약 출력
%  =====================================================================

fprintf('========================================\n');
fprintf('  결과 요약 (ON-length 스윕)\n');
fprintf('========================================\n\n');

% 평균 계산 (마지막 차원 = runs)
mean_delay = mean(results_grid.mean_delay_ms, 3, 'omitnan');
mean_explicit_bsr = mean(results_grid.explicit_bsr_count, 3, 'omitnan');
mean_implicit_ratio = mean(results_grid.implicit_bsr_ratio, 3, 'omitnan');
mean_buffer_empty = mean(results_grid.buffer_empty_ratio, 3, 'omitnan');

n_mu = length(exp_config.sweep_range);
n_L = length(exp_config.sweep_range2);

fprintf('[μ_on에 따른 경향]\n\n');

for j = 1:n_L
    L_val = exp_config.sweep_range2(j);
    fprintf('▶ L_cell = %.2f\n', L_val);
    fprintf('%-10s | %10s | %12s | %12s | %12s\n', ...
        'μ_on[s]', 'Delay[ms]', 'Exp_BSR', 'Impl_Ratio', 'Buf_Empty');
    fprintf('%s\n', repmat('-', 1, 70));
    
    for i = 1:n_mu
        fprintf('%-10.2f | %10.2f | %12.0f | %11.1f%% | %11.1f%%\n', ...
            exp_config.sweep_range(i), ...
            mean_delay(i, j), ...
            mean_explicit_bsr(i, j), ...
            mean_implicit_ratio(i, j) * 100, ...
            mean_buffer_empty(i, j) * 100);
    end
    fprintf('\n');
end

%% =====================================================================
%  6. 경향 분석
%  =====================================================================

fprintf('========================================\n');
fprintf('  경향 분석\n');
fprintf('========================================\n\n');

for j = 1:n_L
    L_val = exp_config.sweep_range2(j);
    fprintf('[L_cell = %.2f]\n', L_val);
    
    % μ_on이 증가할 때 변화
    delay_first = mean_delay(1, j);
    delay_last = mean_delay(end, j);
    delay_change = ((delay_last / delay_first) - 1) * 100;
    
    exp_first = mean_explicit_bsr(1, j);
    exp_last = mean_explicit_bsr(end, j);
    exp_change = ((exp_last / exp_first) - 1) * 100;
    
    fprintf('  μ_on: %.2fs → %.2fs\n', ...
        exp_config.sweep_range(1), exp_config.sweep_range(end));
    fprintf('    - Mean Delay: %.2fms → %.2fms (%.1f%%)\n', ...
        delay_first, delay_last, delay_change);
    fprintf('    - Explicit BSR: %.0f → %.0f (%.1f%%)\n', ...
        exp_first, exp_last, exp_change);
    
    % 버퍼 Empty 패턴
    buf_first = mean_buffer_empty(1, j);
    buf_last = mean_buffer_empty(end, j);
    fprintf('    - Buffer Empty: %.1f%% → %.1f%%\n', ...
        buf_first * 100, buf_last * 100);
    
    fprintf('\n');
end

%% =====================================================================
%  7. 예상 사이클 정보
%  =====================================================================

fprintf('[참고] μ_on별 예상 Burst 사이클 수 (ρ=0.7, 10s 시뮬레이션)\n');
fprintf('%-10s | %15s | %20s\n', 'μ_on[s]', 'Cycle 길이[s]', '예상 사이클 수');
fprintf('%s\n', repmat('-', 1, 50));

for i = 1:n_mu
    mu_on = exp_config.sweep_range(i);
    mu_off = mu_on * (1 - 0.7) / 0.7;  % rho=0.7 기준
    cycle_time = mu_on + mu_off;
    expected_cycles = 10.0 / cycle_time;
    
    fprintf('%-10.2f | %15.3f | %20.1f\n', ...
        mu_on, cycle_time, expected_cycles);
end

fprintf('\n🎉 Experiment 1-3 완료!\n');
fprintf('   다음 단계: analyze_exp1_03_on_length.m 실행하여 상세 분석\n\n');