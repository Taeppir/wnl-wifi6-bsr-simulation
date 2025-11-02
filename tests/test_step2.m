%% test_step2.m
% Step 2: 초기화 함수 테스트

clear; close all; clc;

fprintf('========================================\n');
fprintf('Step 2: 초기화 함수 테스트\n');
fprintf('========================================\n\n');

%% 설정 로드
cfg = config_default();
cfg.verbose = 0;

%% Test 2-1: DEFINE_AP
fprintf('Test 2-1: DEFINE_AP\n');

AP = DEFINE_AP(cfg.num_STAs);

% 필수 필드 확인
assert(isfield(AP, 'BSR'), 'AP must have BSR field');
assert(isfield(AP, 'total_rx_data'), 'AP must have total_rx_data');
assert(isfield(AP, 'num_connected_STAs'), 'AP must have num_connected_STAs');

% 초기값 확인
assert(isempty(AP.BSR), 'Initial BSR table must be empty');
assert(AP.total_rx_data == 0, 'Initial rx_data must be 0');
assert(AP.num_connected_STAs == cfg.num_STAs, 'num_connected_STAs mismatch');

fprintf('  AP 초기화 성공\n');
fprintf('    - BSR 테이블: 비어있음\n');
fprintf('    - 연결 단말: %d개\n', AP.num_connected_STAs);

%% Test 2-2: DEFINE_STAs_v2
fprintf('\nTest 2-2: DEFINE_STAs_v2\n');

STAs = DEFINE_STAs_v2(cfg.num_STAs, cfg.OCW_min, cfg);

% 배열 크기 확인
assert(length(STAs) == cfg.num_STAs, 'STAs array size mismatch');

% 첫 번째 단말 확인
sta1 = STAs(1);

required_fields = {
    'ID', 'mode', 'OCW', 'OBO', 'did_tx_attempt', 'accessed_RA_RU', ...
    'Queue', 'packet_list', 'Q_prev', 'reported_bsr', ...
    'Q_ema', 'ema_initialized', ...
    'is_waiting_for_first_SA', 'wait_start_time', ...
    'assigned_SA_RU', ...
    'num_of_packets', 'num_of_transmitted', 'transmitted_data', ...
    'packet_queuing_delays', 'delay_idx'
};

missing = {};
for i = 1:length(required_fields)
    if ~isfield(sta1, required_fields{i})
        missing{end+1} = required_fields{i}; %#ok<AGROW>
    end
end

assert(isempty(missing), 'Missing fields: %s', strjoin(missing, ', '));

% 초기값 확인
assert(sta1.ID == 1, 'ID mismatch');
assert(sta1.mode == 0, 'Initial mode must be 0 (RA)');
assert(sta1.OCW == cfg.OCW_min, 'Initial OCW mismatch');
assert(sta1.OBO >= 0 && sta1.OBO <= cfg.OCW_min, 'OBO out of range');
assert(isempty(sta1.Queue), 'Initial Queue must be empty');
assert(isempty(sta1.packet_list), 'Initial packet_list must be empty');

fprintf('  STAs 초기화 성공\n');
fprintf('    - 단말 수: %d\n', length(STAs));
fprintf('    - 초기 mode: 0 (RA)\n');
fprintf('    - 초기 OCW: %d\n', cfg.OCW_min);

% 모든 단말 ID 고유성 확인
all_ids = [STAs.ID];
assert(length(unique(all_ids)) == cfg.num_STAs, 'STA IDs are not unique');
fprintf('    - ID 고유성: ✓\n');

%% Test 2-3: DEFINE_RUs
fprintf('\nTest 2-3: DEFINE_RUs\n');

RUs = DEFINE_RUs(cfg.numRU_total, cfg.numRU_RA);

% 배열 크기 확인
assert(length(RUs) == cfg.numRU_total, 'RUs array size mismatch');

% RA-RU 확인
for i = 1:cfg.numRU_RA
    assert(RUs(i).mode == 0, 'RU %d must be RA-RU (mode=0)', i);
end

% SA-RU 확인
for i = (cfg.numRU_RA + 1):cfg.numRU_total
    assert(RUs(i).mode == 1, 'RU %d must be SA-RU (mode=1)', i);
end

% 필수 필드 확인
ru1 = RUs(1);
assert(isfield(ru1, 'ID'), 'RU must have ID');
assert(isfield(ru1, 'mode'), 'RU must have mode');
assert(isfield(ru1, 'accessedSTAs'), 'RU must have accessedSTAs');
assert(isfield(ru1, 'collision'), 'RU must have collision');
assert(isfield(ru1, 'assignedSTA'), 'RU must have assignedSTA');

% 초기값 확인
assert(isempty(ru1.accessedSTAs), 'Initial accessedSTAs must be empty');
assert(ru1.collision == false, 'Initial collision must be false');
assert(ru1.assignedSTA == 0, 'Initial assignedSTA must be 0');

fprintf('  RUs 초기화 성공\n');
fprintf('    - 총 RU: %d\n', length(RUs));
fprintf('    - RA-RU: %d (RU 1-%d)\n', cfg.numRU_RA, cfg.numRU_RA);
fprintf('    - SA-RU: %d (RU %d-%d)\n', cfg.numRU_SA, ...
    cfg.numRU_RA+1, cfg.numRU_total);

%% Test 2-4: init_metrics_struct
fprintf('\nTest 2-4: init_metrics_struct\n');

metrics = init_metrics_struct(cfg);

% 상위 레벨 필드 확인
assert(isfield(metrics, 'cumulative'), 'Missing cumulative');
assert(isfield(metrics, 'packet_level'), 'Missing packet_level');
assert(isfield(metrics, 'stage_level'), 'Missing stage_level');
assert(isfield(metrics, 'policy_level'), 'Missing policy_level');

% Cumulative 메트릭
assert(metrics.cumulative.total_uora_attempts == 0, 'Initial uora_attempts != 0');
assert(metrics.cumulative.total_explicit_bsr == 0, 'Initial explicit_bsr != 0');
assert(metrics.cumulative.total_implicit_bsr == 0, 'Initial implicit_bsr != 0');

% Packet-level 메트릭
assert(length(metrics.packet_level.queuing_delays) == cfg.max_delays, ...
    'queuing_delays size mismatch');
assert(metrics.packet_level.delay_idx == 0, 'Initial delay_idx != 0');

% Stage-level 메트릭
if cfg.collect_stage_metrics
    assert(length(metrics.stage_level.ra_collision) == cfg.max_stages, ...
        'ra_collision size mismatch');
    assert(metrics.stage_level.stage_idx == 0, 'Initial stage_idx != 0');
end

fprintf('  Metrics 초기화 성공\n');
fprintf('    - Cumulative: ✓\n');
fprintf('    - Packet-level: ✓\n');
fprintf('    - Stage-level: ✓\n');
fprintf('    - Policy-level: ✓\n');

%% Test 2-5: 메모리 사전 할당 확인
fprintf('\nTest 2-5: 메모리 사전 할당 확인\n');

% STAs
assert(length(STAs(1).packet_queuing_delays) == cfg.max_delays, ...
    'STA delays not pre-allocated');

% Metrics
assert(length(metrics.packet_level.queuing_delays) == cfg.max_delays, ...
    'Metrics delays not pre-allocated');

if cfg.collect_stage_metrics
    assert(length(metrics.stage_level.ra_collision) == cfg.max_stages, ...
        'Stage metrics not pre-allocated');
end

fprintf('  메모리 사전 할당 확인\n');

% 메모리 크기 추정
bytes_per_sta = whos('STAs').bytes / cfg.num_STAs;
bytes_metrics = whos('metrics').bytes;
total_mb = (bytes_per_sta * cfg.num_STAs + bytes_metrics) / 1e6;

fprintf('    - STA당 메모리: %.2f KB\n', bytes_per_sta / 1e3);
fprintf('    - Metrics 메모리: %.2f KB\n', bytes_metrics / 1e3);
fprintf('    - 총 메모리: %.2f MB\n', total_mb);

%% Test 2-6: 통합 테스트
fprintf('\nTest 2-6: 통합 초기화 테스트\n');

% 전체 초기화
cfg_test = config_default();
AP_test = DEFINE_AP(cfg_test.num_STAs);
STAs_test = DEFINE_STAs_v2(cfg_test.num_STAs, cfg_test.OCW_min, cfg_test);
RUs_test = DEFINE_RUs(cfg_test.numRU_total, cfg_test.numRU_RA);
metrics_test = init_metrics_struct(cfg_test);

% 상호 일관성 확인
assert(AP_test.num_connected_STAs == length(STAs_test), ...
    'AP and STAs count mismatch');
assert(length(RUs_test) == cfg_test.numRU_total, 'RUs count mismatch');

fprintf('  통합 초기화 성공\n');
fprintf('    - AP ↔ STAs: 일관성 ✓\n');
fprintf('    - RUs 구성: 일관성 ✓\n');
fprintf('    - Metrics: 준비 완료 ✓\n');

%% 모든 테스트 통과
fprintf('\n========================================\n');
fprintf('  Step 2 완료: 초기화 함수 검증 성공\n');
fprintf('========================================\n\n');

fprintf('초기화 완료:\n');
fprintf('  - AP: %d 단말 지원\n', AP.num_connected_STAs);
fprintf('  - STAs: %d개 (mode=0)\n', length(STAs));
fprintf('  - RUs: %d개 (RA:%d, SA:%d)\n', ...
    length(RUs), cfg.numRU_RA, cfg.numRU_SA);
fprintf('  - Metrics: 수집 준비 완료\n\n');

fprintf('다음 단계:\n');
fprintf('  >> test_step3  %% Step 3: 트래픽 생성 테스트\n\n');