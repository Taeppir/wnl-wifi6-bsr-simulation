%% exp0_quick_test.m
% Phase 0 실험의 빠른 버전
% 시뮬레이션 시간을 5초로 줄여서 빠르게 테스트
%
% 목적: MATLAB 종료 없이 전체 파라미터 범위 테스트 가능한지 확인

clear; close all; clc;

if exist('setup_paths.m', 'file')
    setup_paths;
end

fprintf('\n');
fprintf('========================================\n');
fprintf('  Phase 0: 빠른 테스트 모드\n');
fprintf('========================================\n\n');

fprintf('⚠️  이것은 빠른 테스트 버전입니다.\n');
fprintf('   시뮬레이션 시간: 5초 (정식: 10초)\n');
fprintf('   Runs: 3 (정식: 10)\n\n');

%% 설정

L_cell_values = [0.1, 0.3, 0.5];
rho_values = [0.3, 0.7];
mu_on_value = 0.05;
num_STAs_values = [10, 20];
numRU_RA_values = [1, 2];

fixed_params = struct();
fixed_params.simulation_time = 5.0;  % ⭐ 짧게!
fixed_params.warmup_time = 0.0;
fixed_params.scheme_id = 0;
fixed_params.collect_bsr_trace = false;

num_runs = 3;  % ⭐ 적게!
rng_seed_base = 1000;

% 조합 생성
configs = [];
for L_cell = L_cell_values
    for rho = rho_values
        for num_STAs = num_STAs_values
            for numRU_RA = numRU_RA_values
                cfg_params = fixed_params;
                cfg_params.L_cell = L_cell;
                cfg_params.rho = rho;
                cfg_params.mu_on = mu_on_value;
                cfg_params.num_STAs = num_STAs;
                cfg_params.numRU_RA = numRU_RA;
                configs = [configs; cfg_params]; %#ok<AGROW>
            end
        end
    end
end

num_configs = length(configs);

fprintf('총 설정: %d개\n', num_configs);
fprintf('Run per config: %d\n', num_runs);
fprintf('총 시뮬레이션: %d개\n', num_configs * num_runs);
fprintf('예상 시간: %.1f분\n\n', num_configs * num_runs * 2.5 / 60);

%% 실행

all_results = cell(num_configs, num_runs);
all_configs_used = cell(num_configs, 1);
failed_configs = [];

tic;

for i = 1:num_configs
    fprintf('[%2d/%2d] L=%.1f, ρ=%.1f, STAs=%d, RA-RU=%d', ...
        i, num_configs, ...
        configs(i).L_cell, configs(i).rho, ...
        configs(i).num_STAs, configs(i).numRU_RA);
    
    try
        [results, cfg_used] = run_single_config(configs(i), num_runs, rng_seed_base);
        
        for run = 1:num_runs
            all_results{i, run} = results(run);
        end
        
        all_configs_used{i} = cfg_used;
        
    catch ME
        fprintf('\n  ❌ 실패: %s\n', ME.message);
        failed_configs = [failed_configs; i]; %#ok<AGROW>
    end
end

elapsed = toc;

fprintf('\n');
fprintf('========================================\n');
fprintf('  테스트 완료!\n');
fprintf('========================================\n\n');

fprintf('소요 시간: %.1f분\n', elapsed / 60);
fprintf('성공: %d/%d\n', num_configs - length(failed_configs), num_configs);

if ~isempty(failed_configs)
    fprintf('\n실패한 설정:\n');
    for i = 1:length(failed_configs)
        idx = failed_configs(i);
        fprintf('  [%d] L=%.1f, ρ=%.1f, STAs=%d, RA-RU=%d\n', ...
            idx, configs(idx).L_cell, configs(idx).rho, ...
            configs(idx).num_STAs, configs(idx).numRU_RA);
    end
end

fprintf('\n');

if length(failed_configs) == 0
    fprintf('✅ 모든 설정 성공! 이제 정식 실험을 실행하세요:\n');
    fprintf('   run(''exp0_baseline_sweep.m'')\n\n');
else
    fprintf('⚠️  일부 설정 실패. 코드를 수정한 후 다시 시도하세요.\n\n');
end