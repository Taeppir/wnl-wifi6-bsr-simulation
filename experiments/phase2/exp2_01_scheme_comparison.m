%% exp2_01_scheme_comparison.m
% Experiment 2-1: 정책 비교 - 부하 수준별 성능
%
% Research Question:
%   제안 스킴(1~3)이 Baseline 대비 얼마나 지연/충돌을 감소시키는가?
%
% 시나리오:
%   A (Low):  L_cell=0.15
%   B (Mid):  L_cell=0.35
%   C (High): L_cell=0.50
%
% 스킴:
%   0: Baseline
%   1: Fixed Reduction
%   2: Proportional
%   3: EMA-based

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

exp_config = get_exp2_01_config();

%% =====================================================================
%  2. 실험 실행 (커스텀 러너 사용)
%  =====================================================================

results = run_exp2_01(exp_config);

%% =====================================================================
%  3. 결과 저장
%  =====================================================================

fprintf('[결과 저장]\n');

% MAT 파일 저장
mat_dir = 'results/mat';
if ~exist(mat_dir, 'dir'), mkdir(mat_dir); end

timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
mat_filename = sprintf('%s/%s_%s.mat', mat_dir, exp_config.name, timestamp_str);

save(mat_filename, 'results', '-v7.3');
fprintf('  ✓ MAT 저장: %s\n', mat_filename);

% CSV 저장 (간단한 버전)
csv_dir = 'results/csv';
if ~exist(csv_dir, 'dir'), mkdir(csv_dir); end

csv_filename = sprintf('%s/%s_summary.csv', csv_dir, exp_config.name);

% 테이블 생성
T = table();
scenario_names = repmat({''}, length(exp_config.scenarios) * length(exp_config.schemes), 1);
scheme_names = repmat({''}, length(exp_config.scenarios) * length(exp_config.schemes), 1);

row_idx = 0;
for s = 1:length(exp_config.scenarios)
    for sc = 1:length(exp_config.schemes)
        row_idx = row_idx + 1;
        scenario_names{row_idx} = exp_config.scenarios(s).name;
        scheme_names{row_idx} = exp_config.scheme_names{sc};
    end
end

T.Scenario = scenario_names;
T.Scheme = scheme_names;

% 주요 지표만 CSV에 저장
key_metrics = {
    'mean_delay_ms'
    'p90_delay_ms'
    'mean_uora_delay_ms'
    'collision_rate'
    'explicit_bsr_count'
    'implicit_bsr_ratio'
    'completion_rate'
};

for i = 1:length(key_metrics)
    metric = key_metrics{i};
    mean_data = results.summary.mean.(metric);
    std_data = results.summary.std.(metric);
    
    T.([metric '_mean']) = mean_data(:);
    T.([metric '_std']) = std_data(:);
end

writetable(T, csv_filename);
fprintf('  ✓ CSV 저장: %s\n\n', csv_filename);

%% =====================================================================
%  4. 간단한 요약 출력
%  =====================================================================

fprintf('========================================\n');
fprintf('  결과 요약\n');
fprintf('========================================\n\n');

mean_delay = results.summary.mean.mean_delay_ms;
mean_collision = results.summary.mean.collision_rate;
mean_explicit = results.summary.mean.explicit_bsr_count;

fprintf('%-12s | %-25s | %10s | %10s | %12s\n', ...
    'Scenario', 'Scheme', 'Delay[ms]', 'Coll[%]', 'Exp_BSR');
fprintf('%s\n', repmat('-', 1, 85));

for s = 1:length(exp_config.scenarios)
    fprintf('\n[%s (L=%.2f)]\n', exp_config.scenarios(s).name, exp_config.scenarios(s).L_cell);
    
    for sc = 1:length(exp_config.schemes)
        fprintf('%-12s | %-25s | %10.2f | %10.1f | %12.0f\n', ...
            '', ...
            exp_config.scheme_names{sc}, ...
            mean_delay(s, sc), ...
            mean_collision(s, sc) * 100, ...
            mean_explicit(s, sc));
    end
end

fprintf('\n========================================\n');
fprintf('  개선률 (Baseline 대비)\n');
fprintf('========================================\n\n');

baseline_idx = 1;  % Scheme 0

for s = 1:length(exp_config.scenarios)
    fprintf('[%s]\n', exp_config.scenarios(s).name);
    
    baseline_delay = mean_delay(s, baseline_idx);
    baseline_coll = mean_collision(s, baseline_idx);
    baseline_exp = mean_explicit(s, baseline_idx);
    
    for sc = 2:length(exp_config.schemes)  % 제안 스킴만
        delay_reduction = (1 - mean_delay(s, sc) / baseline_delay) * 100;
        coll_reduction = (1 - mean_collision(s, sc) / baseline_coll) * 100;
        exp_reduction = (1 - mean_explicit(s, sc) / baseline_exp) * 100;
        
        fprintf('  %s:\n', exp_config.scheme_names{sc});
        fprintf('    Delay 감소: %.1f%%\n', delay_reduction);
        fprintf('    Collision 감소: %.1f%%\n', coll_reduction);
        fprintf('    Explicit BSR 감소: %.1f%%\n', exp_reduction);
    end
    fprintf('\n');
end

fprintf('🎉 Experiment 2-1 완료!\n');
fprintf('   다음 단계: analyze_exp2_01_comparison.m 실행하여 상세 분석\n\n');