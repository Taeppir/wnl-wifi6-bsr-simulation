%% explore_exp2_01.m
% Exp 2-1 빠른 탐색 (Notebook 스타일)

clear; close all; clc;

%% 로드
fprintf('[Exp 2-1 빠른 탐색]\n\n');

mat_files = dir('results/mat/exp2_1_scheme_comparison_*.mat');
if isempty(mat_files)
    error('결과 파일을 찾을 수 없습니다!');
end

[~, latest_idx] = max([mat_files.datenum]);
mat_file = fullfile(mat_files(latest_idx).folder, mat_files(latest_idx).name);

fprintf('로드: %s\n\n', mat_files(latest_idx).name);
exp = load(mat_file);
results = exp.results;

%% 데이터 추출
n_scenarios = length(results.config.scenarios);
n_schemes = length(results.config.schemes);

scenario_names = {results.config.scenarios.name};
scheme_names = results.config.scheme_names;

% Mean 값만 추출
delay = results.summary.mean.mean_delay_ms;
uora_delay = results.summary.mean.mean_uora_delay_ms;
collision = results.summary.mean.collision_rate;
explicit_bsr = results.summary.mean.explicit_bsr_count;
implicit_ratio = results.summary.mean.implicit_bsr_ratio;
completion = results.summary.mean.completion_rate;

%% 빠른 확인
fprintf('========================================\n');
fprintf('  Exp 2-1 빠른 확인\n');
fprintf('========================================\n\n');

for s = 1:n_scenarios
    fprintf('[%s (L=%.2f)]\n', scenario_names{s}, ...
        results.config.scenarios(s).L_cell);
    fprintf('%-30s | %10s | %10s | %10s | %12s\n', ...
        'Scheme', 'Delay', 'UORA', 'Coll.', 'Exp_BSR');
    fprintf('%s\n', repmat('-', 1, 80));
    
    for sc = 1:n_schemes
        fprintf('%-30s | %8.2f | %8.2f | %9.1f%% | %10.0f\n', ...
            scheme_names{sc}, ...
            delay(s, sc), ...
            uora_delay(s, sc), ...
            collision(s, sc) * 100, ...
            explicit_bsr(s, sc));
    end
    
    fprintf('\n');
end

%% 개선률 계산
fprintf('[개선률 요약 (Baseline 대비)]\n\n');

baseline_idx = 1;

for s = 1:n_scenarios
    fprintf('%s:\n', scenario_names{s});
    
    baseline_delay = delay(s, baseline_idx);
    baseline_exp = explicit_bsr(s, baseline_idx);
    
    for sc = 2:n_schemes
        delay_improv = (1 - delay(s, sc) / baseline_delay) * 100;
        exp_improv = (1 - explicit_bsr(s, sc) / baseline_exp) * 100;
        
        fprintf('  %s: Delay %.1f%%, Exp_BSR %.1f%%\n', ...
            scheme_names{sc}(9:end-1), delay_improv, exp_improv);
    end
    
    fprintf('\n');
end

%% 최고 성능 스킴
fprintf('[최고 성능 스킴]\n\n');

for s = 1:n_scenarios
    [min_delay, best_idx] = min(delay(s, 2:end));
    best_idx = best_idx + 1;
    
    improvement = (1 - min_delay / delay(s, baseline_idx)) * 100;
    
    fprintf('%s: %s (%.1f%% 개선)\n', ...
        scenario_names{s}, scheme_names{best_idx}, improvement);
end

fprintf('\n');

%% 간단한 플롯
figure('Position', [100, 100, 1400, 400]);

% Subplot 1: Mean Delay
subplot(1, 3, 1);
bar(delay');
set(gca, 'XTickLabel', scenario_names);
ylabel('Mean Delay [ms]');
title('평균 큐잉 지연');
legend(scheme_names, 'Location', 'northwest');
grid on;

% Subplot 2: UORA Delay
subplot(1, 3, 2);
bar(uora_delay');
set(gca, 'XTickLabel', scenario_names);
ylabel('UORA Delay [ms]');
title('UORA 지연');
legend(scheme_names, 'Location', 'northwest');
grid on;

% Subplot 3: Explicit BSR
subplot(1, 3, 3);
bar(explicit_bsr');
set(gca, 'XTickLabel', scenario_names);
ylabel('Explicit BSR Count');
title('Explicit BSR 발생 횟수');
legend(scheme_names, 'Location', 'northwest');
grid on;

sgtitle('Exp 2-1 빠른 탐색', 'FontSize', 14, 'FontWeight', 'bold');

fprintf('✓ 탐색 완료\n\n');