%% exp1_1_load_sweep.m
% Experiment 1-1: 트래픽 부하(L_cell) 스윕
%
% Research Question: 
%   네트워크 부하가 증가하면 UORA 경쟁과 큐잉 지연이 어떻게 변하는가?
%
% 스윕 변수:
%   L_cell: [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
%
% 고정 파라미터:
%   scheme_id = 0 (Baseline)
%   num_STAs = 20
%   alpha = 1.5
%   rho = 0.7
%   mu_on = 0.05

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

exp_config = get_exp1_01_config();

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
fprintf('  결과 요약\n');
fprintf('========================================\n\n');

% 평균 계산
mean_delay = mean(results_grid.mean_delay_ms, 2, 'omitnan');
mean_collision = mean(results_grid.collision_rate, 2, 'omitnan');
mean_completion = mean(results_grid.completion_rate, 2, 'omitnan');

fprintf('%-10s | %12s | %12s | %12s\n', 'L_cell', 'Delay (ms)', 'Coll. (%)', 'Compl. (%)');
fprintf('%s\n', repmat('-', 1, 55));

for i = 1:length(exp_config.sweep_range)
    fprintf('%-10.1f | %12.2f | %12.1f | %12.1f\n', ...
        exp_config.sweep_range(i), ...
        mean_delay(i), ...
        mean_collision(i) * 100, ...
        mean_completion(i) * 100);
end

fprintf('\n');

% 경향 분석
fprintf('[경향 분석]\n');
if mean_delay(end) > mean_delay(1) * 1.5
    fprintf('  ✓ L_cell 증가 → 지연 증가 (%.1fms → %.1fms)\n', mean_delay(1), mean_delay(end));
end
if mean_collision(end) > mean_collision(1) * 1.5
    fprintf('  ✓ L_cell 증가 → 충돌 증가 (%.1f%% → %.1f%%)\n', ...
        mean_collision(1)*100, mean_collision(end)*100);
end
if mean_completion(end) < 0.85
    fprintf('  ⚠️  L_cell=%.1f에서 완료율 낮음 (%.1f%%)\n', ...
        exp_config.sweep_range(end), mean_completion(end)*100);
end

fprintf('\n🎉 Experiment 1-1 완료!\n\n');