%% exp0_baseline_sweep.m
% Phase 0: Baseline 환경 탐색
%
% 목표:
%   Baseline (scheme_id=0)만으로 다양한 네트워크 환경을 테스트하고,
%   어떤 지표가 어떤 조건에서 나쁜지 파악
%
% 실험 범위:
%   L_cell:   [0.1, 0.3, 0.5, 0.7]       (4개)
%   rho:      [0.3, 0.7]                 (2개)
%   mu_on:    [0.05]                     (1개, 고정)
%   num_STAs: [10, 20]                   (2개)
%   numRU_RA: [1, 2]                     (2개)
%   → 총 32개 조합, 각 10 runs = 320 simulations
%
% 산출물:
%   - results/phase0/raw/baseline_sweep_YYYYMMDD_HHMMSS.mat
%   - results/phase0/csv/baseline_sweep_summary.csv

clear; close all; clc;

%% =====================================================================
%  0. 경로 설정
%  =====================================================================

if exist('setup_paths.m', 'file')
    setup_paths;
end

fprintf('\n');
fprintf('========================================\n');
fprintf('  Phase 0: Baseline 환경 탐색\n');
fprintf('========================================\n\n');

%% =====================================================================
%  1. 실험 파라미터 정의
%  =====================================================================

fprintf('[1/4] 실험 파라미터 정의\n');
fprintf('----------------------------------------\n');

% 파라미터 범위
L_cell_values = [0.3];
rho_values = [0.3, 0.5, 0.7];
mu_on_values = [0.01, 0.05, 0.1, 0.5];
num_STAs_values = [20];
numRU_RA_values = [1, 2];

% 고정 파라미터
fixed_params = struct();
fixed_params.simulation_time = 10.0;  % 충분한 시간
fixed_params.warmup_time = 0.0;
fixed_params.scheme_id = 0;  % Baseline
fixed_params.collect_bsr_trace = false;  % 성능 향상 (Phase 0에서는 불필요)
% numRU_SA는 제거 - run_single_config에서 자동 계산 (numRU_SA = 9 - numRU_RA)

% 실행 설정
num_runs = 10;
rng_seed_base = 1000;

% 조합 생성
configs = [];
config_id = 0;

for L_cell = L_cell_values
    for rho = rho_values
        for mu_on = mu_on_values  % ⭐ mu_on sweep 추가
            for num_STAs = num_STAs_values
                for numRU_RA = numRU_RA_values
                    config_id = config_id + 1;
                    
                    cfg_params = fixed_params;
                    cfg_params.L_cell = L_cell;
                    cfg_params.rho = rho;
                    cfg_params.mu_on = mu_on;  % ⭐ 스칼라 값 할당
                    cfg_params.num_STAs = num_STAs;
                    cfg_params.numRU_RA = numRU_RA;
                    
                    configs = [configs; cfg_params]; %#ok<AGROW>
                end
            end
        end
    end
end

num_configs = length(configs);

fprintf('  총 설정: %d개\n', num_configs);
fprintf('  Run per config: %d\n', num_runs);
fprintf('  총 시뮬레이션: %d개\n', num_configs * num_runs);
fprintf('  예상 소요 시간: %.1f분 (1 sim = 5초 가정)\n', ...
    num_configs * num_runs * 5 / 60);
fprintf('\n');

%% =====================================================================
%  2. 실험 실행
%  =====================================================================

fprintf('[2/4] 실험 실행\n');
fprintf('----------------------------------------\n');

% 중간 저장 파일 경로
checkpoint_file = 'results/phase0/raw/baseline_sweep_checkpoint.mat';

% 복구 시도
if exist(checkpoint_file, 'file')
    fprintf('⚠️  체크포인트 발견! 이전 실험 복구할까요?\n');
    fprintf('   (y: 복구, n: 새로 시작): ');
    user_input = input('', 's');
    
    if strcmpi(user_input, 'y')
        load(checkpoint_file, 'all_results', 'all_configs_used', 'completed_configs');
        fprintf('✓ 복구 완료: %d/%d 설정 완료됨\n\n', completed_configs, num_configs);
    else
        all_results = cell(num_configs, num_runs);
        all_configs_used = cell(num_configs, 1);
        completed_configs = 0;
    end
else
    all_results = cell(num_configs, num_runs);
    all_configs_used = cell(num_configs, 1);
    completed_configs = 0;
end

tic;

for i = 1:num_configs
    % 이미 완료된 설정은 스킵
    if i <= completed_configs
        fprintf('[%2d/%2d] ⏭️  스킵 (이미 완료)\n', i, num_configs);
        continue;
    end
    
    fprintf('[%2d/%2d] L=%.1f, ρ=%.1f, STAs=%d, RA-RU=%d', ...
        i, num_configs, ...
        configs(i).L_cell, configs(i).rho, ...
        configs(i).num_STAs, configs(i).numRU_RA);
    
    try
        % 단일 설정 실행
        [results, cfg_used] = run_single_config(configs(i), num_runs, rng_seed_base);
        
        % 결과 저장 (cell array에)
        for run = 1:num_runs
            all_results{i, run} = results(run);
        end
        
        all_configs_used{i} = cfg_used;
        
        % ⭐ 중간 저장 (매 설정마다)
        completed_configs = i;
        save(checkpoint_file, 'all_results', 'all_configs_used', 'completed_configs', 'configs', 'num_configs', 'num_runs');
        
    catch ME
        fprintf('\n  ❌ 에러 발생: %s\n', ME.message);
        fprintf('  위치: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        fprintf('  체크포인트 저장 후 종료합니다.\n\n');
        
        % 에러 시에도 저장
        completed_configs = i - 1;
        save(checkpoint_file, 'all_results', 'all_configs_used', 'completed_configs', 'configs', 'num_configs', 'num_runs');
        rethrow(ME);
    end
end

% 체크포인트 파일 삭제 (정상 완료 시)
if exist(checkpoint_file, 'file')
    delete(checkpoint_file);
    fprintf('\n✓ 체크포인트 파일 삭제 (정상 완료)\n');
end

elapsed_time = toc;

fprintf('\n');
fprintf('  ✓ 실험 완료! (%.1f분)\n', elapsed_time / 60);
fprintf('  평균 시뮬레이션 시간: %.2f초\n', elapsed_time / (num_configs * num_runs));
fprintf('\n');

%% =====================================================================
%  3. 결과 저장
%  =====================================================================

fprintf('[3/4] 결과 저장\n');
fprintf('----------------------------------------\n');

% Cell array를 구조체 배열로 변환
% all_results: {num_configs, num_runs} cell array
% → all_results_array: (num_configs * num_runs) x 1 struct array

all_results_array = [];
for i = 1:num_configs
    for run = 1:num_runs
        if ~isempty(all_results{i, run})
            all_results_array = [all_results_array; all_results{i, run}]; %#ok<AGROW>
        end
    end
end

all_configs_array = [all_configs_used{:}];

% 저장 함수 호출
save_experiment_results(all_results_array, all_configs_array, 'baseline_sweep', 0);

fprintf('\n');

%% =====================================================================
%  4. 간단한 통계 요약
%  =====================================================================

fprintf('[4/4] 간단한 통계 요약\n');
fprintf('----------------------------------------\n\n');

% CSV 파일 읽기
summary_table = readtable('results/phase0/csv/baseline_sweep_summary.csv');

fprintf('주요 지표 범위:\n');
fprintf('  Mean Delay    : %.2f ~ %.2f ms\n', ...
    min(summary_table.mean_delay_ms), max(summary_table.mean_delay_ms));
fprintf('  P90 Delay     : %.2f ~ %.2f ms\n', ...
    min(summary_table.p90_delay_ms), max(summary_table.p90_delay_ms));
fprintf('  Collision Rate: %.1f ~ %.1f%%\n', ...
    min(summary_table.collision_rate) * 100, max(summary_table.collision_rate) * 100);
fprintf('  Buffer Empty  : %.1f ~ %.1f%% ⭐\n', ...
    min(summary_table.buffer_empty_ratio) * 100, max(summary_table.buffer_empty_ratio) * 100);
fprintf('  Explicit BSR  : %.1f ~ %.1f%%\n', ...
    min(summary_table.explicit_bsr_ratio) * 100, max(summary_table.explicit_bsr_ratio) * 100);

fprintf('\n');

%% =====================================================================
%  5. 다음 단계 안내
%  =====================================================================

fprintf('========================================\n');
fprintf('  Phase 0 실험 완료!\n');
fprintf('========================================\n\n');

fprintf('다음 단계:\n');
fprintf('  1. analyze_phase0.m 실행 → 문제 시나리오 식별\n');
fprintf('  2. visualize_phase0.m 실행 → CDF, Line plots 생성\n');
fprintf('  3. Phase 1 준비: 문제 원인 심층 분석\n\n');

fprintf('결과 파일:\n');
fprintf('  - MAT: results/phase0/raw/baseline_sweep_*.mat\n');
fprintf('  - CSV: results/phase0/csv/baseline_sweep_summary.csv\n\n');