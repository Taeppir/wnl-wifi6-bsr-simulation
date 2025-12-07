%% exp0_batch_runner.m
% Phase 0 실험을 작은 배치로 나눠서 실행
%
% MATLAB이 자주 종료되는 경우 이 스크립트 사용
% 배치 크기: 6개 설정씩 실행

clear; close all; clc;

if exist('setup_paths.m', 'file')
    setup_paths;
end

fprintf('\n');
fprintf('========================================\n');
fprintf('  Phase 0: 배치 실행 모드\n');
fprintf('========================================\n\n');

%% 설정

% 전체 파라미터와 동일
L_cell_values = [0.1, 0.3, 0.5];
rho_values = [0.3, 0.7];
mu_on_value = 0.05;
num_STAs_values = [10, 20];
numRU_RA_values = [1, 2];

fixed_params = struct();
fixed_params.simulation_time = 10.0;
fixed_params.warmup_time = 0.0;
fixed_params.scheme_id = 0;
fixed_params.collect_bsr_trace = false;

num_runs = 10;
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

% 배치 설정
batch_size = 6;  % 한 번에 6개씩
num_batches = ceil(num_configs / batch_size);

fprintf('총 설정: %d개\n', num_configs);
fprintf('배치 크기: %d개\n', batch_size);
fprintf('총 배치: %d개\n\n', num_batches);

%% 배치 실행

all_results = cell(num_configs, num_runs);
all_configs_used = cell(num_configs, 1);

for batch_idx = 1:num_batches
    fprintf('========================================\n');
    fprintf('  배치 %d/%d\n', batch_idx, num_batches);
    fprintf('========================================\n\n');
    
    % 배치 범위
    start_idx = (batch_idx - 1) * batch_size + 1;
    end_idx = min(batch_idx * batch_size, num_configs);
    
    fprintf('설정 %d ~ %d 실행 중...\n\n', start_idx, end_idx);
    
    for i = start_idx:end_idx
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
            fprintf('\n  ❌ 에러: %s\n', ME.message);
            if ~isempty(ME.stack)
                fprintf('  위치: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
            end
        end
    end
    
    % 배치마다 저장
    batch_file = sprintf('results/phase0/raw/batch_%d.mat', batch_idx);
    batch_results = all_results(start_idx:end_idx, :);
    batch_configs = all_configs_used(start_idx:end_idx);
    save(batch_file, 'batch_results', 'batch_configs', 'start_idx', 'end_idx');
    
    fprintf('\n✓ 배치 %d 완료 및 저장\n', batch_idx);
    fprintf('  파일: %s\n\n', batch_file);
    
    % 배치 사이 잠깐 대기 (메모리 정리)
    if batch_idx < num_batches
        fprintf('5초 대기 중 (메모리 정리)...\n');
        pause(5);
        fprintf('\n');
    end
end

%% 배치 결과 병합

fprintf('========================================\n');
fprintf('  배치 결과 병합\n');
fprintf('========================================\n\n');

% 모든 배치 로드 및 병합
for batch_idx = 1:num_batches
    batch_file = sprintf('results/phase0/raw/batch_%d.mat', batch_idx);
    
    if ~exist(batch_file, 'file')
        fprintf('⚠️  배치 %d 파일 없음: %s\n', batch_idx, batch_file);
        continue;
    end
    
    load(batch_file, 'batch_results', 'batch_configs', 'start_idx', 'end_idx');
    
    for i = start_idx:end_idx
        for run = 1:num_runs
            all_results{i, run} = batch_results{i - start_idx + 1, run};
        end
        all_configs_used{i} = batch_configs{i - start_idx + 1};
    end
    
    fprintf('✓ 배치 %d 로드 완료\n', batch_idx);
end

fprintf('\n');

%% 최종 저장

fprintf('최종 결과 저장 중...\n');

% Cell array를 구조체 배열로 변환
all_results_struct = cell(num_configs, num_runs);
for i = 1:num_configs
    for run = 1:num_runs
        if ~isempty(all_results{i, run})
            all_results_struct{i, run} = all_results{i, run};
        end
    end
end

% 유효한 결과만 필터링
valid_results = [];
valid_configs = [];

for i = 1:num_configs
    has_valid_run = false;
    for run = 1:num_runs
        if ~isempty(all_results_struct{i, run})
            has_valid_run = true;
            break;
        end
    end
    
    if has_valid_run
        valid_results = [valid_results; all_results_struct(i, :)]; %#ok<AGROW>
        valid_configs = [valid_configs; all_configs_used{i}]; %#ok<AGROW>
    end
end

% 저장 함수 호출
if ~isempty(valid_results)
    all_results_array = cell2mat(valid_results);
    save_experiment_results(all_results_array, valid_configs, 'baseline_sweep', 0);
    fprintf('✓ 저장 완료!\n\n');
else
    fprintf('❌ 유효한 결과 없음!\n\n');
end

%% 요약

fprintf('========================================\n');
fprintf('  배치 실행 완료!\n');
fprintf('========================================\n\n');

fprintf('다음 단계:\n');
fprintf('  1. analyze_phase0.m 실행\n');
fprintf('  2. visualize_phase0.m 실행\n\n');