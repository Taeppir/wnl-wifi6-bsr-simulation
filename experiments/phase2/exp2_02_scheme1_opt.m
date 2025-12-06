%% exp2_02_scheme1_optimization.m
% Experiment 2-2: Scheme 1 파라미터 최적화
%
% Research Question:
%   Scheme 1의 최적 파라미터 조합은?
%
% 스윕 변수:
%   fixed_reduction_bytes: [100, 300, 500, 700, 1000]
%   sensitivity: [0.5, 0.7, 1.0, 1.3, 1.5]

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

exp_config = get_exp2_02_config();

%% =====================================================================
%  2. 실험 실행
%  =====================================================================

results_grid = run_sweep_experiment(exp_config);

%% =====================================================================
%  3. Baseline 실행 (비교용)
%  =====================================================================

if exp_config.include_baseline
    fprintf('\n[Baseline 실행]\n');
    
    baseline_results = zeros(1, exp_config.num_runs);
    
    for run = 1:exp_config.num_runs
        fprintf('  Run %d/%d... ', run, exp_config.num_runs);
        
        % Baseline 설정
        cfg = config_default();
        fixed_fields = fieldnames(exp_config.fixed);
        for f = 1:length(fixed_fields)
            field_name = fixed_fields{f};
            cfg.(field_name) = exp_config.fixed.(field_name);
        end
        cfg.scheme_id = 0;  % Baseline
        cfg = recompute_pareto_lambda(cfg);
        
        rng(run);
        
        try
            [results, ~] = main_sim_v2(cfg);
            baseline_results(run) = results.summary.mean_delay_ms;
            fprintf('완료\n');
        catch ME
            fprintf('실패\n');
            baseline_results(run) = NaN;
        end
    end
    
    results_grid.baseline_delay = mean(baseline_results, 'omitnan');
    fprintf('  Baseline 평균 지연: %.2f ms\n\n', results_grid.baseline_delay);
end

%% =====================================================================
%  4. 결과 저장
%  =====================================================================

save_experiment_results(results_grid, exp_config);

%% =====================================================================
%  5. Quick Plot
%  =====================================================================

quick_plot(results_grid, exp_config);

%% =====================================================================
%  6. 간단한 요약
%  =====================================================================

fprintf('========================================\n');
fprintf('  최적 파라미터 찾기\n');
fprintf('========================================\n\n');

mean_delay = mean(results_grid.mean_delay_ms, 3, 'omitnan');

[min_delay, min_idx] = min(mean_delay(:));
[min_i, min_j] = ind2sub(size(mean_delay), min_idx);

fprintf('[최적 조합]\n');
fprintf('  fixed_reduction: %d bytes\n', exp_config.sweep_range(min_i));
fprintf('  sensitivity: %.1f\n', exp_config.sweep_range2(min_j));
fprintf('  평균 지연: %.2f ms\n', min_delay);

if exp_config.include_baseline
    improvement = (1 - min_delay / results_grid.baseline_delay) * 100;
    fprintf('  Baseline 대비: %.1f%% 개선\n', improvement);
end

fprintf('\n🎉 Experiment 2-2 완료!\n');
fprintf('   다음 단계: analyze_exp2_02_scheme1_opt.m 실행\n\n');