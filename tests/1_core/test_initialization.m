%% test_initialization.m
% 초기화 함수 검증
%
% 검증 내용:
%   - DEFINE_AP
%   - DEFINE_STAs_v2
%   - DEFINE_RUs
%   - init_metrics_struct

clear; close all; clc;

fprintf('========================================\n');
fprintf('  초기화 함수 검증\n');
fprintf('========================================\n\n');

cfg = config_default();
cfg.verbose = 0;

total_tests = 0;
passed_tests = 0;

%% Test 1: AP 초기화
fprintf('[Test 1] DEFINE_AP\n');
fprintf('----------------------------------------\n');

AP = DEFINE_AP(cfg.num_STAs);

required_fields = {'BSR', 'total_rx_data', 'num_connected_STAs'};
all_present = all(cellfun(@(f) isfield(AP, f), required_fields));

total_tests = total_tests + 1;

if all_present && isempty(AP.BSR) && AP.total_rx_data == 0
    fprintf('  ✅ PASS: AP 초기화 정상\n');
    fprintf('    연결 단말: %d개\n', AP.num_connected_STAs);
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: AP 초기화 오류\n');
end

fprintf('\n');

%% Test 2: STAs 초기화
fprintf('[Test 2] DEFINE_STAs_v2\n');
fprintf('----------------------------------------\n');

STAs = DEFINE_STAs_v2(cfg.num_STAs, cfg.OCW_min, cfg);

required_sta_fields = {
    'ID', 'mode', 'OCW', 'OBO', 'Queue', 'packet_list', ...
    'Q_prev', 'Q_ema', 'ema_initialized', ...
    'is_waiting_for_first_SA', 'assigned_SA_RU', ...
    'packet_queuing_delays', 'delay_idx'
};

sta1 = STAs(1);
all_present = all(cellfun(@(f) isfield(sta1, f), required_sta_fields));

% ID 고유성
all_ids = [STAs.ID];
ids_unique = length(unique(all_ids)) == cfg.num_STAs;

% 초기값 확인
initial_values_ok = (sta1.mode == 0) && ...
                    (sta1.OCW == cfg.OCW_min) && ...
                    isempty(sta1.Queue) && ...
                    isempty(sta1.packet_list);

total_tests = total_tests + 1;

if all_present && ids_unique && initial_values_ok
    fprintf('  ✅ PASS: STAs 초기화 정상\n');
    fprintf('    단말 수: %d\n', length(STAs));
    fprintf('    초기 mode: 0 (RA)\n');
    fprintf('    초기 OCW: %d\n', cfg.OCW_min);
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: STAs 초기화 오류\n');
end

fprintf('\n');

%% Test 3: RUs 초기화
fprintf('[Test 3] DEFINE_RUs\n');
fprintf('----------------------------------------\n');

RUs = DEFINE_RUs(cfg.numRU_total, cfg.numRU_RA);

% 개수 확인
count_ok = (length(RUs) == cfg.numRU_total);

% RA-RU 모드 확인
ra_modes_ok = all([RUs(1:cfg.numRU_RA).mode] == 0);

% SA-RU 모드 확인
sa_modes_ok = all([RUs((cfg.numRU_RA+1):end).mode] == 1);

% 초기 상태 확인
ru1 = RUs(1);
initial_ok = isempty(ru1.accessedSTAs) && ...
             (ru1.collision == false) && ...
             (ru1.assignedSTA == 0);

total_tests = total_tests + 1;

if count_ok && ra_modes_ok && sa_modes_ok && initial_ok
    fprintf('  ✅ PASS: RUs 초기화 정상\n');
    fprintf('    총 RU: %d (RA:%d, SA:%d)\n', ...
        cfg.numRU_total, cfg.numRU_RA, cfg.numRU_SA);
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: RUs 초기화 오류\n');
end

fprintf('\n');

%% Test 4: Metrics 초기화
fprintf('[Test 4] init_metrics_struct\n');
fprintf('----------------------------------------\n');

metrics = init_metrics_struct(cfg);

has_cumulative = isfield(metrics, 'cumulative');
has_packet_level = isfield(metrics, 'packet_level');
has_policy_level = isfield(metrics, 'policy_level');

% Cumulative 필드 확인
cumul_ok = isfield(metrics.cumulative, 'total_uora_attempts') && ...
           isfield(metrics.cumulative, 'total_explicit_bsr') && ...
           isfield(metrics.cumulative, 'total_uora_idle');

% 사전 할당 확인
preallocated_ok = (length(metrics.packet_level.queuing_delays) == cfg.max_delays);

total_tests = total_tests + 1;

if has_cumulative && has_packet_level && has_policy_level && cumul_ok && preallocated_ok
    fprintf('  ✅ PASS: Metrics 초기화 정상\n');
    fprintf('    사전 할당 크기: %d samples\n', cfg.max_delays);
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: Metrics 초기화 오류\n');
end

fprintf('\n');

%% Test 5: 통합 일관성
fprintf('[Test 5] 초기화 통합 일관성\n');
fprintf('----------------------------------------\n');

consistency_ok = (AP.num_connected_STAs == length(STAs)) && ...
                 (length(RUs) == cfg.numRU_total);

total_tests = total_tests + 1;

if consistency_ok
    fprintf('  ✅ PASS: 초기화 간 일관성 유지\n');
    fprintf('    AP ↔ STAs: %d = %d\n', AP.num_connected_STAs, length(STAs));
    fprintf('    RUs: %d\n', length(RUs));
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 일관성 오류\n');
end

fprintf('\n');

%% 최종 결과
fprintf('========================================\n');
fprintf('  테스트 결과\n');
fprintf('========================================\n');
fprintf('  통과: %d / %d\n', passed_tests, total_tests);
fprintf('  통과율: %.0f%%\n\n', passed_tests / total_tests * 100);

if passed_tests == total_tests
    fprintf('  🎉 초기화 검증 완료!\n\n');
else
    fprintf('  ⚠️  일부 테스트 실패\n\n');
end