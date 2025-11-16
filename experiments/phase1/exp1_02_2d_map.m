%% exp1_02_2d_map.m
% Experiment 1-2: (L_cell, ρ) 2D 맵 - 비포화/임계 부하 경계
%
% Research Question: 
%   (L_cell, ρ) 평면에서 completion rate, mean delay, collision rate,
%   buffer empty ratio를 2D 맵으로 표현하여 비포화/임계/초과 부하 영역을
%   명확히 구분할 수 있는가?
%
% 스윕 변수:
%   L_cell: [0.3, 0.4, 0.5, 0.6, 0.7]
%   rho:    [0.3, 0.5, 0.7, 0.9]
%
% 고정 파라미터:
%   scheme_id = 0 (Baseline)
%   num_STAs = 20
%   alpha = 1.5
%   mu_on = 0.05

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

exp_config = get_exp1_02_config();

%% =====================================================================
%  2. 실험 실행
%  =====================================================================

results_grid = run_sweep_experiment(exp_config);

%% =====================================================================
%  3. 결과 저장
%  =====================================================================

save_experiment_results(results_grid, exp_config);

%% =====================================================================
%  4. Quick Plot (2D Heatmap)
%  =====================================================================

quick_plot(results_grid, exp_config);

%% =====================================================================
%  5. 간단한 요약 출력
%  =====================================================================

fprintf('========================================\n');
fprintf('  결과 요약 (2D 맵)\n');
fprintf('========================================\n\n');

% 평균 계산 (마지막 차원 = runs)
mean_delay = mean(results_grid.mean_delay_ms, 3, 'omitnan');
mean_collision = mean(results_grid.collision_rate, 3, 'omitnan');
mean_completion = mean(results_grid.completion_rate, 3, 'omitnan');

fprintf('[Completion Rate 기준 영역 분류]\n');
fprintf('  ≥98%%: 안정 비포화\n');
fprintf('  90~98%%: 임계 부하\n');
fprintf('  <90%%: 초과 부하\n\n');

% 영역별 카운트
safe_count = sum(mean_completion(:) >= 0.98);
critical_count = sum(mean_completion(:) >= 0.90 & mean_completion(:) < 0.98);
overload_count = sum(mean_completion(:) < 0.90);

total_points = numel(mean_completion);

fprintf('[결과]\n');
fprintf('  안정 비포화: %d/%d (%.1f%%)\n', safe_count, total_points, safe_count/total_points*100);
fprintf('  임계 부하: %d/%d (%.1f%%)\n', critical_count, total_points, critical_count/total_points*100);
fprintf('  초과 부하: %d/%d (%.1f%%)\n', overload_count, total_points, overload_count/total_points*100);

fprintf('\n[임계 부하 조건 (90~98%%)]\n');
if critical_count > 0
    for i1 = 1:length(exp_config.sweep_range)
        for i2 = 1:length(exp_config.sweep_range2)
            compl = mean_completion(i1, i2);
            if compl >= 0.90 && compl < 0.98
                fprintf('  L_cell=%.1f, ρ=%.1f → Completion=%.1f%%\n', ...
                    exp_config.sweep_range(i1), exp_config.sweep_range2(i2), compl*100);
            end
        end
    end
else
    fprintf('  없음\n');
end

fprintf('\n[초과 부하 조건 (<90%%)]\n');
if overload_count > 0
    for i1 = 1:length(exp_config.sweep_range)
        for i2 = 1:length(exp_config.sweep_range2)
            compl = mean_completion(i1, i2);
            if compl < 0.90
                fprintf('  L_cell=%.1f, ρ=%.1f → Completion=%.1f%%\n', ...
                    exp_config.sweep_range(i1), exp_config.sweep_range2(i2), compl*100);
            end
        end
    end
else
    fprintf('  없음\n');
end

fprintf('\n🎉 Experiment 1-2 완료!\n');
fprintf('   다음 단계: analyze_exp1_02_2d_map.m 실행하여 상세 분석\n\n');