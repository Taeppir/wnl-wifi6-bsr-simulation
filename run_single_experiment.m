% RUN_SINGLE_EXPERIMENT: 단일 실험 빠른 실행
%
% 사용법:
%   >> setup_paths          % 최초 1회
%   >> run_single_experiment

clear; close all; clc;

%% 1. 설정
cfg = config_default();

% 필요 시 파라미터 수정
cfg.num_STAs = 20;
cfg.simulation_time = 10.0;  % 짧게 (디버깅용)
cfg.scheme_id = 3;          % v3 테스트
cfg.verbose = 1;            % 상세 출력

%% 2. 시뮬레이션 실행
fprintf('Starting simulation...\n');
tic;
results = main_sim_v2(cfg);
elapsed = toc;

fprintf('Simulation completed in %.2f seconds\n', elapsed);

%% 3. 결과 출력
fprintf('\n========== Results ==========\n');
fprintf('Total packets: %d\n', results.total_completed_packets);
fprintf('Mean delay: %.4f ms\n', results.summary.mean_delay_ms);  % ⭐ 수정
fprintf('P90 delay: %.4f ms\n', results.summary.p90_delay_ms);    % ⭐ 수정
fprintf('Collision rate: %.2f%%\n', results.summary.collision_rate * 100);  % ⭐ 수정
fprintf('Implicit BSR ratio: %.2f%%\n', results.summary.implicit_bsr_ratio * 100);  % ⭐ 수정
fprintf('Throughput: %.2f Mb/s\n', results.summary.throughput_mbps);  % ⭐ 추가
fprintf('Jain Index: %.3f\n', results.summary.jain_index);  % ⭐ 추가
fprintf('==============================\n');

%% 4. 시각화 (선택)
fprintf('\nGenerating plots...\n');
VISUALIZE_RESULTS(results, cfg);

fprintf('\n✅ Experiment completed successfully!\n');