%% resave_phase0_results.m
% 실험은 완료됐는데 저장만 실패한 경우
% 체크포인트에서 로드해서 저장만 다시 실행

clear; close all; clc;

if exist('setup_paths.m', 'file')
    setup_paths;
end

fprintf('\n');
fprintf('========================================\n');
fprintf('  Phase 0 결과 재저장\n');
fprintf('========================================\n\n');

%% 체크포인트 로드

checkpoint_file = 'results/phase0/raw/baseline_sweep_checkpoint.mat';

if ~exist(checkpoint_file, 'file')
    error('체크포인트 파일이 없습니다: %s', checkpoint_file);
end

fprintf('체크포인트 로드 중...\n');
load(checkpoint_file, 'all_results', 'all_configs_used', 'completed_configs', 'num_configs', 'num_runs');

fprintf('  완료된 설정: %d/%d\n', completed_configs, num_configs);
fprintf('  총 시뮬레이션: %d개\n\n', completed_configs * num_runs);

%% 결과 변환

fprintf('결과 변환 중...\n');

all_results_array = [];
for i = 1:completed_configs
    for run = 1:num_runs
        if ~isempty(all_results{i, run})
            all_results_array = [all_results_array; all_results{i, run}]; %#ok<AGROW>
        end
    end
end

all_configs_array = [all_configs_used{:}];

fprintf('  총 결과: %d개\n', length(all_results_array));
fprintf('  설정: %d개\n\n', length(all_configs_array));

%% 저장

fprintf('결과 저장 중...\n');

try
    save_experiment_results(all_results_array, all_configs_array, 'baseline_sweep', 0);
    fprintf('✓ 저장 완료!\n\n');
    
    % 체크포인트 파일 삭제
    delete(checkpoint_file);
    fprintf('✓ 체크포인트 파일 삭제\n\n');
    
catch ME
    fprintf('❌ 저장 실패: %s\n', ME.message);
    fprintf('   스택:\n');
    for i = 1:min(3, length(ME.stack))
        fprintf('   [%d] %s (line %d)\n', i, ME.stack(i).name, ME.stack(i).line);
    end
end

%% 완료

fprintf('========================================\n');
fprintf('  완료!\n');
fprintf('========================================\n\n');

fprintf('결과 파일:\n');
fprintf('  - MAT: results/phase0/raw/baseline_sweep_*.mat\n');
fprintf('  - CSV: results/phase0/csv/baseline_sweep_summary.csv\n\n');

fprintf('다음 단계:\n');
fprintf('  1. analyze_phase0.m 실행\n');
fprintf('  2. visualize_phase0.m 실행\n\n');