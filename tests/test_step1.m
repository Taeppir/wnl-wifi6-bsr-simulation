%% test_step1.m
% Step 1: 경로 설정 및 설정 파일 테스트

clear; close all; clc;

fprintf('========================================\n');
fprintf('Step 1: 경로 및 설정 테스트\n');
fprintf('========================================\n\n');

%% Test 1-1: 경로 설정
fprintf('Test 1-1: 경로 설정\n');

% setup_paths 실행 (이미 했다면 스킵 가능)
try
    cfg = config_default();  % 함수 호출 테스트
    fprintf('  ✅ config_default 호출 성공\n');
catch ME
    error('❌ config_default 호출 실패: %s', ME.message);
end

%% Test 1-2: 설정 필드 확인
fprintf('\nTest 1-2: 설정 필드 확인\n');

required_fields = {
    'num_STAs', 'numRU_RA', 'numRU_SA', 'numRU_total', ...
    'simulation_time', 'warmup_time', 'stage_duration', ...
    'lambda', 'alpha', 'rho', 'L_cell', ...
    'OCW_min', 'OCW_max', 'scheme_id', ...
    'verbose', 'collect_stage_metrics'
};

missing_fields = {};
for i = 1:length(required_fields)
    if ~isfield(cfg, required_fields{i})
        missing_fields{end+1} = required_fields{i}; %#ok<AGROW>
    end
end

if isempty(missing_fields)
    fprintf('  ✅ 모든 필수 필드 존재\n');
else
    error('❌ 누락된 필드: %s', strjoin(missing_fields, ', '));
end

%% Test 1-3: 설정 값 타당성 검증
fprintf('\nTest 1-3: 설정 값 타당성 검증\n');

assert(cfg.num_STAs > 0, 'num_STAs must be positive');
assert(cfg.numRU_RA >= 1, 'numRU_RA must be >= 1');
assert(cfg.numRU_SA >= 1, 'numRU_SA must be >= 1');
assert(cfg.simulation_time > cfg.warmup_time, 'sim_time > warmup_time');
assert(cfg.stage_duration > 0, 'stage_duration must be positive');
assert(cfg.alpha > 1, 'alpha must be > 1 for Pareto');
assert(cfg.rho > 0 && cfg.rho < 1, 'rho must be in (0,1)');
assert(cfg.L_cell > 0 && cfg.L_cell <= 1, 'L_cell must be in (0,1]');
assert(cfg.OCW_min < cfg.OCW_max, 'OCW_min < OCW_max');
assert(ismember(cfg.scheme_id, [0,1,2,3]), 'scheme_id must be 0,1,2,3');

fprintf('  ✅ 모든 설정 값 타당\n');

%% Test 1-4: 계산된 값 확인
fprintf('\nTest 1-4: 계산된 값 확인\n');

fprintf('  총 RU: %d (RA:%d, SA:%d)\n', cfg.numRU_total, cfg.numRU_RA, cfg.numRU_SA);
fprintf('  Stage 개수: ~%d\n', ceil(cfg.simulation_time / cfg.stage_duration));
fprintf('  Lambda (네트워크): %.2f pkt/s\n', cfg.lambda_network);
fprintf('  Lambda (단말당): %.2f pkt/s\n', cfg.lambda);

total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
fprintf('  SA-RU 용량: %.2f Mbps\n', total_capacity / 1e6);

expected_load = cfg.lambda_network * cfg.size_MPDU * 8 / total_capacity;
fprintf('  예상 부하: %.2f%%\n', expected_load * 100);

assert(abs(expected_load - cfg.L_cell) < 0.01, 'Load calculation mismatch');

fprintf('  ✅ 계산된 값 정확\n');

%% 모든 테스트 통과
fprintf('\n========================================\n');
fprintf('✅ Step 1 완료: 경로 및 설정 검증 성공\n');
fprintf('========================================\n\n');

fprintf('다음 단계:\n');
fprintf('  >> test_step2  %% Step 2: 초기화 함수 테스트\n\n');