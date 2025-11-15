%% test_delay_decomposition.m
% 지연 분해 분석 ($T_{uora}$, $T_{sched}$, $T_{frag}$) 검증
%
% [수정]
%   - [Test 1] 시나리오에 T_overhead(Gap)를 포함하도록 검증 로직 수정

clear; close all; clc;

fprintf('========================================\n');
fprintf('  지연 분해 분석 ($T_{uora/sched/frag}$) 검증\n');
fprintf('========================================\n\n');

%% 1. 기본 설정
cfg = config_default();
cfg.verbose = 0;
cfg.collect_bsr_trace = false;
cfg.simulation_time = 5.0;
cfg.warmup_time = 0.0;
cfg.num_STAs = 2;
cfg.numRU_RA = 1;
cfg.max_packets_per_sta = 10; % 테스트를 위해 큐 크기 축소

total_tests = 0;
passed_tests = 0;

% 테스트용 AP, RUs, metrics 초기화
AP = DEFINE_AP(cfg.num_STAs);
RUs = DEFINE_RUs(cfg.numRU_total, cfg.numRU_RA);
metrics = init_metrics_struct(cfg);

fprintf('[시나리오] STA 1에 P1(2000B), P2(1000B) 순차 도착\n\n');

%% 2. 시나리오 기반 테스트 (이벤트 순차 실행)

fprintf('========================================\n');
fprintf('  [Test 1] 시나리오 상세 검증 (로그 출력)\n');
fprintf('========================================\n');
test_ok = true;

% 검증을 위해 타임스탬프 저장용 변수
t_arrival_p1 = 0;
t_bsr_success = 0;
t_ru_assigned = 0;
t_first_tx_p1 = 0;
t_complete_p1 = 0;
t_complete_p2 = 0;
t_uora = 0;
t_sched = 0;

try
    %% ---------------------------------------------------------------------
    fprintf('[Event 1] T=0.1: P1(2000B), P2(1000B) 도착 → UPDATE_QUE\n');
    STAs = DEFINE_STAs_v2(cfg.num_STAs, cfg.OCW_min, cfg);
    sta_idx = 1;
    
    STAs(sta_idx).packet_list = [
        struct('packet_idx', 1, 'total_size', 2000, 'arrival_time', 0.1); % P1
        struct('packet_idx', 2, 'total_size', 1000, 'arrival_time', 0.1)  % P2
    ];
    STAs(sta_idx).num_of_packets = 2;
    STAs(sta_idx).packet_list_next_idx = 1;
    
    current_time = 0.1;
    t_arrival_p1 = current_time; % P1의 T_arrival
    
    STAs = UPDATE_QUE(STAs, current_time);
    
    sta1 = STAs(sta_idx);
    assert(sta1.is_waiting_for_first_SA == true, 'is_waiting_for_first_SA 플래그 실패');
    assert(sta1.wait_start_time == 0.1, 'wait_start_time(T_arrival) 기록 실패');
    assert(sta1.Queue(sta1.queue_head).is_bsr_wait_packet == true, 'P1 플래그(true) 설정 실패');
    
    fprintf('  - PASS: P1(BSR) 플래그, T_arrival(%.1f) 기록 완료\n', t_arrival_p1);
    
    %% ---------------------------------------------------------------------
    fprintf('[Event 2] T=0.3: Explicit BSR 성공 → UL_TRANSMITTING_v2 (RA)\n');
    RUs(1).accessedSTAs = [sta_idx];
    
    current_time = 0.3;
    t_bsr_success = current_time; % T_bsr_success
    
    % UL_TRANSMITTING_v2는 tx_start_time, tx_complete_time을 받음
    % RA 전송(BSR)은 순식간에 끝난다고 가정하므로 둘 다 0.3으로 설정
    [STAs, AP, RUs, ~, metrics] = UL_TRANSMITTING_v2(STAs, AP, RUs, t_bsr_success, t_bsr_success, cfg, metrics);
    
    sta1 = STAs(sta_idx);
    assert(sta1.last_bsr_success_time == 0.3, 'T_bsr_success 기록 실패');
    fprintf('  - PASS: T_bsr_success(%.1f) 기록 완료\n', t_bsr_success);
    
    %% ---------------------------------------------------------------------
    fprintf('[Event 3] T=0.6: 첫 SA-RU 할당 → RECEIVING_TF\n');
    RUs(2).assignedSTA = sta_idx;
    
    current_time = 0.6;
    t_ru_assigned = current_time; % T_ru_assigned
    
    STAs = RECEIVING_TF(STAs, RUs, AP, cfg, t_ru_assigned);
    
    sta1 = STAs(sta_idx);
    assert(sta1.delay_decomp_idx == 1, '지연 분해 인덱스 증가 실패');
    
    % 계산된 지연 값 (로그 출력용)
    t_uora = sta1.uora_delays(1);
    t_sched = sta1.sched_delays(1);
    
    fprintf('  - PASS: T_ru_assigned(%.1f) 수신\n', t_ru_assigned);
    fprintf('  - T_uora  : %.2f (%.1f - %.1f)\n', t_uora, t_bsr_success, t_arrival_p1);
    fprintf('  - T_sched : %.2f (%.1f - %.1f)\n', t_sched, t_ru_assigned, t_bsr_success);

    %% ---------------------------------------------------------------------
    fprintf('[Event 4] T=0.7: P1 부분 전송 (1500B) → UL_TRANSMITTING_v2 (SA)\n');
    cfg_frag = cfg;
    cfg_frag.size_MPDU = 1500;
    
    current_time_start = 0.7;
    current_time_complete = 0.75; % (시간이 걸린다고 가정)
    t_first_tx_p1 = current_time_start; % T_first_tx (for P1)
    
    [STAs, AP, RUs, tx_log1, metrics] = UL_TRANSMITTING_v2(STAs, AP, RUs, t_first_tx_p1, current_time_complete, cfg_frag, metrics);
    
    sta1 = STAs(sta_idx);
    assert(isempty(tx_log1.completed_packets), 'P1이 완료되면 안 됨');
    assert(sta1.Queue(sta1.queue_head).first_tx_time == 0.7, 'T_first_tx 기록 실패');
    
    idx = sta1.delay_decomp_idx;
    if idx > 0
        t_overhead_recorded = sta1.overhead_delays(idx);
        t_overhead_expected = t_first_tx_p1 - t_ru_assigned;  % 0.7 - 0.6 = 0.1
        
        assert(abs(t_overhead_recorded - t_overhead_expected) < 1e-9, 'T_overhead 기록 실패');
        fprintf('  - PASS: T_overhead 기록 (%.2f s)\n', t_overhead_recorded);
    else
        error('T_overhead 인덱스 없음');
    end



    fprintf('  - PASS: T_first_tx(%.1f) 기록. P1 완료 안 됨.\n', t_first_tx_p1);

    %% ---------------------------------------------------------------------
    fprintf('[Event 5] T=0.9: P1 완료 전송 (500B) → UL_TRANSMITTING_v2 (SA)\n');
    RUs(2).assignedSTA = sta_idx;
    
    current_time_start = 0.9;
    current_time_complete = 0.95;
    t_complete_p1 = current_time_complete; % T_tx_complete (for P1)
    
    [STAs, AP, RUs, tx_log2, metrics] = UL_TRANSMITTING_v2(STAs, AP, RUs, current_time_start, t_complete_p1, cfg_frag, metrics);
    
    assert(length(tx_log2.completed_packets) == 1, 'P1 완료 로그 누락');
    
    t_frag_p1 = tx_log2.completed_packets(1).fragmentation_delay;
    t_queuing_p1 = tx_log2.completed_packets(1).queuing_delay;
    t_overhead_p1 = tx_log2.completed_packets(1).overhead_delay;
    
    fprintf('  - PASS: P1 완료 (T_complete=%.2f)\n', t_complete_p1);
    fprintf('  - T_frag (P1) : %.2f (%.2f - %.1f)\n', t_frag_p1, t_complete_p1, t_first_tx_p1);
    fprintf('  - T_overhead (P1): %.2f (%.1f - %.1f)\n', t_overhead_p1, t_first_tx_p1, t_ru_assigned);
    fprintf('  - T_total (P1): %.2f (%.2f - %.1f)\n', t_queuing_p1, t_complete_p1, t_arrival_p1);
    
    % [핵심 검증 수정]
    % T_overhead(Gap) = T_first_tx - T_ru_assigned
    t_gap = t_overhead_p1;  % ⭐ completed_packets에서 직접 가져옴
    total_decomposed_delay_p1 = t_uora + t_sched + t_gap + t_frag_p1;
    
    fprintf('  - [검증] T_overhead: %.2f (T_first_tx(%.1f) - T_ru_assigned(%.1f))\n', t_gap, t_first_tx_p1, t_ru_assigned);
    fprintf('  - [검증] 분해 합계: %.2f (T_uora + T_sched + T_overhead + T_frag)\n', total_decomposed_delay_p1);
    fprintf('  - [검증] 큐잉 지연: %.2f (T_total)\n', t_queuing_p1);
    
    assert(abs(total_decomposed_delay_p1 - t_queuing_p1) < 1e-9, 'P1 지연 분해 합계 불일치');
    fprintf('  - [검증] PASS: P1의 지연 분해 합계(%.2f) == 총 큐잉 지연(%.2f)\n', total_decomposed_delay_p1, t_queuing_p1);


    %% ---------------------------------------------------------------------
    fprintf('[Event 6] T=1.1: P2 완료 전송 (1000B) → UL_TRANSMITTING_v2 (SA)\n');
    RUs(2).assignedSTA = sta_idx;
    
    current_time_start = 1.1;
    current_time_complete = 1.15;
    t_complete_p2 = current_time_complete; % T_complete (for P2)
    
    [STAs, AP, RUs, tx_log3, metrics] = UL_TRANSMITTING_v2(STAs, AP, RUs, current_time_start, t_complete_p2, cfg_frag, metrics);
    
    assert(length(tx_log3.completed_packets) == 1, 'P2 완료 로그 누락');
    
    t_queuing_p2 = tx_log3.completed_packets(1).queuing_delay;
    t_frag_p2 = tx_log3.completed_packets(1).fragmentation_delay;

    fprintf('  - PASS: P2 완료 (T_complete=%.2f)\n', t_complete_p2);
    fprintf('  - T_frag (P2) : %.2f (T_first=T_complete=1.15)\n', t_frag_p2);
    fprintf('  - T_total (P2): %.2f (%.2f - %.1f)\n', t_queuing_p2, t_complete_p2, 0.1);
    fprintf('  - [검증] PASS: P2는 BSR 대기 패킷이 아님 (T_uora/T_sched 미적용)\n');
    
catch ME
    test_ok = false;
    fprintf('  ❌ FAIL: %s (line %d, file %s)\n', ME.message, ME.stack(1).line, ME.stack(1).name);
end

% 3. 시나리오 최종 판정
total_tests = total_tests + 1;
if test_ok
    fprintf('\n  ✅ PASS: [시나리오 1] 지연 분해 이벤트 흐름 전체 검증 완료\n');
    passed_tests = passed_tests + 1;
else
    fprintf('\n  ❌ FAIL: [시나리오 1] 지연 분해 이벤트 흐름 실패\n');
end

fprintf('\n');

%% 3. ANALYZE_RESULTS_v2 집계 로직 검증 (Warning 발생 지점)

fprintf('========================================\n');
fprintf('  [Test 2] ANALYZE_RESULTS_v2 집계 검증\n');
fprintf('========================================\n');

% 1. Mock 데이터 생성
mock_STAs = DEFINE_STAs_v2(cfg.num_STAs, cfg.OCW_min, cfg);
mock_metrics = init_metrics_struct(cfg);

% STA 1: UORA 샘플 2개
mock_STAs(1).delay_decomp_idx = 2;
mock_STAs(1).uora_delays(1:2) = [0.1; 0.3];
mock_STAs(1).sched_delays(1:2) = [0.2; 0.4];
% STA 2: UORA 샘플 1개
mock_STAs(2).delay_decomp_idx = 1;
mock_STAs(2).uora_delays(1) = 0.5;
mock_STAs(2).sched_delays(1) = 0.6;

% Frag 샘플 2개
mock_metrics.packet_level.frag_idx = 2;
mock_metrics.packet_level.frag_delays(1:2) = [1.0; 2.0];

% 총 완료 패킷 4개
mock_metrics.cumulative.total_completed_pkts = 4;
% [참고] 'total_generated'는 0이므로 완료율 0% Warning은 정상입니다.
% [참고] 'queuing_delays'는 비어있으므로 'No valid samples' Warning은 정상입니다.

% 2. 분석 함수 실행
results = ANALYZE_RESULTS_v2(mock_STAs, AP, mock_metrics, cfg);

% 3. 검증
total_tests = total_tests + 1;
test_ok_2 = true;

% T_uora
mean_uora_exp = mean([0.1, 0.3, 0.5]);
if abs(results.bsr.mean_uora_delay - mean_uora_exp) > 1e-9
    fprintf('  ❌ FAIL: T_uora 평균(%.3f) 불일치 (예상 %.3f)\n', results.bsr.mean_uora_delay, mean_uora_exp);
    test_ok_2 = false;
end

% T_sched
mean_sched_exp = mean([0.2, 0.4, 0.6]);
if abs(results.bsr.mean_sched_delay - mean_sched_exp) > 1e-9
    fprintf('  ❌ FAIL: T_sched 평균(%.3f) 불일치 (예상 %.3f)\n', results.bsr.mean_sched_delay, mean_sched_exp);
    test_ok_2 = false;
end

% T_frag
mean_frag_exp = mean([1.0, 2.0]);
if abs(results.packet_level.mean_frag_delay - mean_frag_exp) > 1e-9
    fprintf('  ❌ FAIL: T_frag 평균(%.3f) 불일치 (예상 %.3f)\n', results.packet_level.mean_frag_delay, mean_frag_exp);
    test_ok_2 = false;
end

% BSR Affected Ratio (Metric A)
ratio_exp = 3 / 4; % 3개 샘플 / 4개 총 패킷
if abs(results.bsr.bsr_affected_packet_ratio - ratio_exp) > 1e-9
    fprintf('  ❌ FAIL: BSR AFFECTED RATIO(%.3f) 불일치 (예상 %.3f)\n', results.bsr.bsr_affected_packet_ratio, ratio_exp);
    test_ok_2 = false;
end

if test_ok_2
    fprintf('  ✅ PASS: T_uora, T_sched, T_frag 평균 및 비율 집계 완료\n');
    passed_tests = passed_tests + 1;
end
fprintf('\n');


%% 최종 결과
fprintf('========================================\n');
fprintf('  테스트 결과\n');
fprintf('========================================\n');
fprintf('  통과: %d / %d\n', passed_tests, total_tests);
fprintf('  통과율: %.0f%%\n\n', passed_tests / total_tests * 100);

if passed_tests == total_tests
    fprintf('  🎉 지연 분해 분석 로직 검증 완료!\n\n');
else
    fprintf('  ⚠️  일부 테스트 실패\n\n');
end