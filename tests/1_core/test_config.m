%% test_config.m
% 설정 파일 검증
%
% 검증 내용:
%   - config_default.m 호출 가능 여부
%   - 필수 필드 존재 확인
%   - 파라미터 값 타당성
%   - 계산된 값 정확성

clear; close all; clc;

fprintf('========================================\n');
fprintf('  설정 파일 검증\n');
fprintf('========================================\n\n');

total_tests = 0;
passed_tests = 0;

%% Test 1: 설정 파일 로드
fprintf('[Test 1] 설정 파일 로드\n');
fprintf('----------------------------------------\n');

try
    cfg = config_default();
    fprintf('  ✅ PASS: config_default() 호출 성공\n');
    total_tests = total_tests + 1;
    passed_tests = passed_tests + 1;
catch ME
    fprintf('  ❌ FAIL: %s\n', ME.message);
    total_tests = total_tests + 1;
    return;
end

fprintf('\n');

%% Test 2: 필수 필드 확인
fprintf('[Test 2] 필수 필드 확인\n');
fprintf('----------------------------------------\n');

required_fields = {
    % 네트워크
    'num_STAs', 'numRU_RA', 'numRU_SA', 'numRU_total', ...
    % 시간
    'simulation_time', 'warmup_time', ...
    % 트래픽
    'lambda', 'alpha', 'rho', 'L_cell', ...
    % UORA
    'OCW_min', 'OCW_max', ...
    % BSR 정책
    'scheme_id', 'v1_fixed_reduction_bytes', 'v1_sensitivity', ...
    'v2_sensitivity', 'v2_max_reduction', ...
    'v3_EMA_alpha', 'v3_sensitivity', 'v3_max_reduction', ...
    % 공통
    'burst_threshold', 'reduction_threshold', ...
    % 기타
    'verbose', 'collect_bsr_trace'
};

missing_fields = cell(0, 1);
for i = 1:length(required_fields)
    if ~isfield(cfg, required_fields{i})
        missing_fields{end+1, 1} = required_fields{i};
    end
end

total_tests = total_tests + 1;

if isempty(missing_fields)
    fprintf('  ✅ PASS: 모든 필수 필드 존재 (%d개)\n', length(required_fields));
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 누락된 필드:\n');
    for i = 1:length(missing_fields)
        fprintf('    - %s\n', missing_fields{i});
    end
end

fprintf('\n');

%% Test 3: 파라미터 값 타당성
fprintf('[Test 3] 파라미터 값 타당성\n');
fprintf('----------------------------------------\n');

validations = {
    'num_STAs > 0', cfg.num_STAs > 0;
    'numRU_RA >= 1', cfg.numRU_RA >= 1;
    'numRU_SA >= 1', cfg.numRU_SA >= 1;
    'sim_time > warmup_time', cfg.simulation_time > cfg.warmup_time;
    'alpha > 1', cfg.alpha > 1;
    '0 < rho < 1', cfg.rho > 0 && cfg.rho < 1;
    '0 < L_cell <= 1', cfg.L_cell > 0 && cfg.L_cell <= 1;
    'OCW_min < OCW_max', cfg.OCW_min < cfg.OCW_max;
    'scheme_id ∈ [0,3]', ismember(cfg.scheme_id, [0,1,2,3]);
    'v1_sensitivity > 0', cfg.v1_sensitivity > 0;
    'v2_sensitivity > 0', cfg.v2_sensitivity > 0;
    'v3_sensitivity > 0', cfg.v3_sensitivity > 0;
    '0 < v3_EMA_alpha <= 1', cfg.v3_EMA_alpha > 0 && cfg.v3_EMA_alpha <= 1;
};

all_valid = true;
for i = 1:size(validations, 1)
    condition = validations{i, 1};
    result = validations{i, 2};
    
    if ~result
        fprintf('  ❌ %s 실패\n', condition);
        all_valid = false;
    end
end

total_tests = total_tests + 1;

if all_valid
    fprintf('  ✅ PASS: 모든 파라미터 타당 (%d개 검증)\n', size(validations, 1));
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 일부 파라미터 타당성 검증 실패\n');
end

fprintf('\n');

%% Test 4: 계산된 값 정확성
fprintf('[Test 4] 계산된 값 정확성\n');
fprintf('----------------------------------------\n');

% RU 개수 일치
assert(cfg.numRU_total == cfg.numRU_RA + cfg.numRU_SA, 'RU 개수 불일치');

% 부하 계산
total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
expected_load = cfg.lambda_network * cfg.size_MPDU * 8 / total_capacity;

total_tests = total_tests + 1;

if abs(expected_load - cfg.L_cell) < 0.01
    fprintf('  ✅ PASS: 부하 계산 정확 (오차 < 1%%)\n');
    fprintf('    목표 부하: %.2f%%\n', cfg.L_cell * 100);
    fprintf('    계산 부하: %.2f%%\n', expected_load * 100);
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 부하 계산 오차 큼\n');
    fprintf('    목표: %.2f%%, 계산: %.2f%%\n', ...
        cfg.L_cell * 100, expected_load * 100);
end

fprintf('\n');

%% 최종 결과
fprintf('========================================\n');
fprintf('  테스트 결과\n');
fprintf('========================================\n');
fprintf('  통과: %d / %d\n', passed_tests, total_tests);
fprintf('  통과율: %.0f%%\n\n', passed_tests / total_tests * 100);

if passed_tests == total_tests
    fprintf('  🎉 설정 파일 검증 완료!\n\n');
else
    fprintf('  ⚠️  일부 테스트 실패\n\n');
end