%% test_circular_queue.m
% 원형 큐(Circular Queue) 구현 검증
%
% [수정]
%   - UL_TRANSMITTING_v2 호출 시 (tx_start_time, tx_complete_time)
%     두 개의 시간 인수를 전달하도록 수정

clear; close all; clc;

fprintf('========================================\n');
fprintf('  원형 큐(Circular Queue) 검증\n');
fprintf('========================================\n\n');

%% 기본 설정
cfg = config_default();
cfg.verbose = 0;
cfg.collect_bsr_trace = false;

total_tests = 0;
passed_tests = 0;

%% Test 1: 초기화 검증
fprintf('[Test 1] DEFINE_STAs_v2: 초기화 검증\n');
fprintf('----------------------------------------\n');

STAs = DEFINE_STAs_v2(1, cfg.OCW_min, cfg);
sta1 = STAs(1);

total_tests = total_tests + 1;

if isfield(sta1, 'queue_head') && ...
   isfield(sta1, 'queue_tail') && ...
   isfield(sta1, 'queue_size') && ...
   isfield(sta1, 'queue_total_bytes') && ...
   length(sta1.Queue) == cfg.max_packets_per_sta && ...
   sta1.queue_head == 1 && ...
   sta1.queue_tail == 1 && ...
   sta1.queue_size == 0 && ...
   sta1.queue_total_bytes == 0

    fprintf('  ✅ PASS: 큐 포인터 및 사전 할당된 배열 초기화 완료\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 큐 관련 필드 초기화 오류\n');
end

fprintf('\n');

%% Test 2: Enqueue (패킷 추가) 검증
fprintf('[Test 2] UPDATE_QUE: Enqueue (패킷 추가)\n');
fprintf('----------------------------------------\n');

% 1. STA 초기화
STAs = DEFINE_STAs_v2(1, cfg.OCW_min, cfg);
% 2. 패킷 1개 생성
STAs(1).packet_list = struct(...
    'packet_idx', 1, ...
    'total_size', 2000, ...
    'arrival_time', 0.1, ...
    'remaining_size', 2000, ...
    'first_tx_time', [], ...
    'is_bsr_wait_packet', false);
STAs(1).num_of_packets = 1;
STAs(1).packet_list_next_idx = 1;

% 3. Enqueue 실행
current_time = 0.2;
STAs = UPDATE_QUE(STAs, current_time);
sta1 = STAs(1);

total_tests = total_tests + 1;

if sta1.queue_size == 1 && ...
   sta1.queue_total_bytes == 2000 && ...
   sta1.queue_head == 1 && ... % Head는 그대로
   sta1.queue_tail == 2 && ... % Tail은 1 증가
   sta1.packet_list_next_idx == 2 % 대기 큐 포인터 1 증가

    fprintf('  ✅ PASS: Enqueue 성공 (size=1, tail=2)\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: Enqueue 후 큐 상태 변수 오류\n');
    fprintf('    size: %d (예상 1)\n', sta1.queue_size);
    fprintf('    bytes: %d (예상 2000)\n', sta1.queue_total_bytes);
    fprintf('    tail: %d (예상 2)\n', sta1.queue_tail);
end

fprintf('\n');

%% Test 3: Dequeue (패킷 제거) 검증
fprintf('[Test 3] UL_TRANSMITTING_v2: Dequeue (패킷 제거)\n');
fprintf('----------------------------------------\n');

% 1. Test 2의 STA 상태 사용
AP = DEFINE_AP(cfg.num_STAs);
RUs = DEFINE_RUs(cfg.numRU_total, cfg.numRU_RA);
metrics = init_metrics_struct(cfg);

% 2. SA-RU 할당
RUs(2).assignedSTA = 1; % STA 1에게 SA-RU (ID=2) 할당
cfg.size_MPDU = 2000; % 패킷이 한 번에 전송되도록 설정

% 3. Dequeue 실행
% [수정] tx_start_time과 tx_complete_time 전달
tx_start_time = 0.3;
tx_complete_time = 0.35; % (시간이 걸렸다고 가정)
[STAs, AP, RUs, tx_log, metrics] = UL_TRANSMITTING_v2(STAs, AP, RUs, tx_start_time, tx_complete_time, cfg, metrics);
sta1 = STAs(1);

total_tests = total_tests + 1;

if sta1.queue_size == 0 && ...
   sta1.queue_total_bytes == 0 && ...
   sta1.queue_head == 2 && ... % Head는 1 증가
   sta1.queue_tail == 2 && ... % Tail은 그대로
   length(tx_log.completed_packets) == 1 % 패킷 완료 로그 1개

    fprintf('  ✅ PASS: Dequeue 성공 (size=0, head=2)\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: Dequeue 후 큐 상태 변수 오류\n');
    fprintf('    size: %d (예상 0)\n', sta1.queue_size);
    fprintf('    bytes: %d (예상 0)\n', sta1.queue_total_bytes);
    fprintf('    head: %d (예상 2)\n', sta1.queue_head);
end

fprintf('\n');

%% Test 4: 부분 전송 (queue_total_bytes) 검증
fprintf('[Test 4] UL_TRANSMITTING_v2: 부분 전송 (bytes 변수)\n');
fprintf('----------------------------------------\n');

% 1. STA 초기화 및 Enqueue
STAs = DEFINE_STAs_v2(1, cfg.OCW_min, cfg);
STAs(1).packet_list = struct('packet_idx', 1, 'total_size', 2000, 'arrival_time', 0.1, 'remaining_size', 2000, 'first_tx_time', [], 'is_bsr_wait_packet', false);
STAs(1).num_of_packets = 1;
STAs(1).packet_list_next_idx = 1;
STAs = UPDATE_QUE(STAs, 0.2); % size=1, bytes=2000, head=1, tail=2

% 2. AP/RUs/metrics 초기화
AP = DEFINE_AP(cfg.num_STAs);
RUs = DEFINE_RUs(cfg.numRU_total, cfg.numRU_RA);
metrics = init_metrics_struct(cfg);

% 3. SA-RU 할당 (부분 전송되도록 MPDU 크기 조절)
RUs(2).assignedSTA = 1;
cfg_partial = cfg;
cfg_partial.size_MPDU = 1500; % 2000 중 1500만 전송

% 4. 전송 실행 (Dequeue 일어나면 안 됨)
% [수정] tx_start_time과 tx_complete_time 전달
tx_start_time = 0.3;
tx_complete_time = 0.35;
[STAs, AP, RUs, tx_log, metrics] = UL_TRANSMITTING_v2(STAs, AP, RUs, tx_start_time, tx_complete_time, cfg_partial, metrics);
sta1 = STAs(1);

total_tests = total_tests + 1;

if sta1.queue_size == 1 && ... % 큐 크기 유지
   sta1.queue_total_bytes == 500 && ... % 2000 - 1500 = 500
   sta1.queue_head == 1 && ... % Head 그대로
   sta1.queue_tail == 2 && ... % Tail 그대로
   length(tx_log.completed_packets) == 0 && ... % 완료 안 됨
   sta1.Queue(sta1.queue_head).remaining_size == 500 % 남은 크기

    fprintf('  ✅ PASS: 부분 전송 성공 (size=1, bytes=500)\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 부분 전송 후 queue_total_bytes 오류\n');
    fprintf('    bytes: %d (예상 500)\n', sta1.queue_total_bytes);
    fprintf('    size: %d (예상 1)\n', sta1.queue_size);
    fprintf('    head: %d (예상 1)\n', sta1.queue_head);
end

fprintf('\n');

%% Test 5: UORA 큐 상태 검증
fprintf('[Test 5] UORA: 큐 상태 (queue_size) 검증\n');
fprintf('----------------------------------------\n');

STAs = DEFINE_STAs_v2(2, cfg.OCW_min, cfg);
% STA 1: 큐 비어있음
STAs(1).queue_size = 0;
STAs(1).mode = 0;
STAs(1).OBO = 0;
% STA 2: 큐 있음
STAs(2).queue_size = 1;
STAs(2).mode = 0;
STAs(2).OBO = 0;

STAs = UORA(STAs, 1);

total_tests = total_tests + 1;

if STAs(1).accessed_RA_RU == 0 && STAs(2).accessed_RA_RU > 0
    fprintf('  ✅ PASS: queue_size=0일 때 UORA 미참여, >0일 때 참여\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: UORA가 queue_size를 잘못 읽음\n');
    fprintf('    STA 1 (Empty) 접근: %d (예상 0)\n', STAs(1).accessed_RA_RU);
    fprintf('    STA 2 (Data) 접근: %d (예상 >0)\n', STAs(2).accessed_RA_RU);
end

fprintf('\n');

%% Test 6: BSR 리포팅 (queue_total_bytes) 검증
fprintf('[Test 6] UL_TRANSMITTING_v2: BSR 리포팅 검증\n');
fprintf('----------------------------------------\n');
% 1. 큐에 2개의 패킷 (총 3000 바이트) Enqueue
cfg_bsr = cfg;
cfg_bsr.size_MPDU = 1000;
STAs = DEFINE_STAs_v2(1, cfg_bsr.OCW_min, cfg_bsr);
STAs(1).packet_list = [
    struct('packet_idx', 1, 'total_size', 2000, 'arrival_time', 0.1, 'remaining_size', 2000, 'first_tx_time', [], 'is_bsr_wait_packet', false);
    struct('packet_idx', 2, 'total_size', 1000, 'arrival_time', 0.1, 'remaining_size', 1000, 'first_tx_time', [], 'is_bsr_wait_packet', false)
];
STAs(1).num_of_packets = 2;
STAs(1).packet_list_next_idx = 1;
STAs = UPDATE_QUE(STAs, 0.2); % size=2, bytes=3000, head=1, tail=3
AP = DEFINE_AP(cfg_bsr.num_STAs);
RUs = DEFINE_RUs(cfg_bsr.numRU_total, cfg_bsr.numRU_RA);
metrics = init_metrics_struct(cfg_bsr);
RUs(2).assignedSTA = 1; % SA-RU 할당

% 2. 전송 (1000 바이트 전송) -> Implicit BSR 트리거
%    전송 후 남은 버퍼 = 3000 - 1000 = 2000 바이트
% [수정] tx_start_time과 tx_complete_time 전달
tx_start_time = 0.3;
tx_complete_time = 0.35;
[STAs, AP, RUs, tx_log, metrics] = UL_TRANSMITTING_v2(STAs, AP, RUs, tx_start_time, tx_complete_time, cfg_bsr, metrics);

total_tests = total_tests + 1;
reported_bsr = AP.BSR(1).Buffer_Status;

if reported_bsr == 2000
    fprintf('  ✅ PASS: Implicit BSR이 큐 바이트(2000)를 정확히 보고\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: BSR 리포팅 오류\n');
    fprintf('    보고된 BSR: %d (예상 2000)\n', reported_bsr);
end

fprintf('\n');

%% Test 7: 엣지 케이스 - Wrap-around (순환) 검증
fprintf('[Test 7] 엣지 케이스: Wrap-around (순환)\n');
fprintf('----------------------------------------\n');
% 1. 작은 큐(size=3) 생성
cfg_small = cfg;
cfg_small.max_packets_per_sta = 3;
cfg_small.size_MPDU = 1000;

STAs = DEFINE_STAs_v2(1, cfg_small.OCW_min, cfg_small);
AP = DEFINE_AP(cfg_small.num_STAs);
RUs = DEFINE_RUs(cfg_small.numRU_total, cfg_small.numRU_RA);
metrics = init_metrics_struct(cfg_small);

STAs(1).packet_list = [
    struct('packet_idx', 1, 'total_size', 1000, 'arrival_time', 0.1, 'remaining_size', 1000, 'first_tx_time', [], 'is_bsr_wait_packet', false); % P1
    struct('packet_idx', 2, 'total_size', 1000, 'arrival_time', 0.1, 'remaining_size', 1000, 'first_tx_time', [], 'is_bsr_wait_packet', false); % P2
    struct('packet_idx', 3, 'total_size', 1000, 'arrival_time', 0.1, 'remaining_size', 1000, 'first_tx_time', [], 'is_bsr_wait_packet', false); % P3
    struct('packet_idx', 4, 'total_size', 1000, 'arrival_time', 0.3, 'remaining_size', 1000, 'first_tx_time', [], 'is_bsr_wait_packet', false); % P4
    struct('packet_idx', 5, 'total_size', 1000, 'arrival_time', 0.3, 'remaining_size', 1000, 'first_tx_time', [], 'is_bsr_wait_packet', false); % P5
];
STAs(1).num_of_packets = 5;
STAs(1).packet_list_next_idx = 1;

% 2. Enqueue (P1, P2, P3) -> 큐 꽉 참
STAs = UPDATE_QUE(STAs, 0.2);
% 상태: size=3, head=1, tail=1 (3+1 -> 4 -> mod(3,3)+1 = 1)
% 큐: [P1, P2, P3]

% 3. Dequeue (P1, P2) -> 큐에 P3만 남음
RUs(2).assignedSTA = 1; % P1 전송
% [수정] tx_start_time과 tx_complete_time 전달
[STAs, AP, RUs, ~, ~] = UL_TRANSMITTING_v2(STAs, AP, RUs, 0.25, 0.27, cfg_small, metrics);
RUs(2).assignedSTA = 1; % P2 전송
% [수정] tx_start_time과 tx_complete_time 전달
[STAs, AP, RUs, ~, ~] = UL_TRANSMITTING_v2(STAs, AP, RUs, 0.28, 0.30, cfg_small, metrics);
% 상태: size=1, head=3, tail=1
% 큐: [_, _, P3]

% 4. Enqueue (P4, P5) -> Wrap-around 발생
STAs = UPDATE_QUE(STAs, 0.4);
% P4가 tail=1에, P5가 tail=2에 삽입되어야 함
% 상태: size=3, head=3, tail=3 (1+2 -> 3)
% 큐: [P4, P5, P3]

sta1 = STAs(1);
total_tests = total_tests + 1;

if sta1.queue_size == 3 && ...
   sta1.queue_head == 3 && ...
   sta1.queue_tail == 3 && ...
   sta1.queue_total_bytes == 3000 && ...
   sta1.Queue(1).packet_idx == 4 && ... % P4가 (1)에
   sta1.Queue(2).packet_idx == 5 && ... % P5가 (2)에
   sta1.Queue(3).packet_idx == 3      % P3가 (3)에

    fprintf('  ✅ PASS: Wrap-around 성공 (head=3, tail=3, size=3)\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: Wrap-around 큐 상태 변수 오류\n');
    fprintf('    size: %d (예상 3)\n', sta1.queue_size);
    fprintf('    head: %d (예상 3)\n', sta1.queue_head);
    fprintf('    tail: %d (예상 3)\n', sta1.queue_tail);
    fprintf('    Pkt at (1): %d (예상 4)\n', sta1.Queue(1).packet_idx);
    fprintf('    Pkt at (2): %d (예상 5)\n', sta1.Queue(2).packet_idx);
end

fprintf('\n');

%% 최종 결과
fprintf('========================================\n');
fprintf('  테스트 결과\n');
fprintf('========================================\n');
fprintf('  통과: %d / %d\n', passed_tests, total_tests);
fprintf('  통과율: %.0f%%\n\n', passed_tests / total_tests * 100);

if passed_tests == total_tests
    fprintf('  🎉 원형 큐(Circular Queue) 검증 완료!\n\n');
else
    fprintf('  ⚠️  일부 테스트 실패\n\n');
end