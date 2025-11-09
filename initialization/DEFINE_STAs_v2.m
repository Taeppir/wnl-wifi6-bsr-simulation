function STAs = DEFINE_STAs_v2(numSTAs, OCWmin, cfg)
% DEFINE_STAs_V2: 단말 구조체 배열 초기화 (mode 포함)
%
% 입력:
%   numSTAs - 단말 수
%   OCWmin  - 초기 경쟁 윈도우
%   cfg     - 설정 구조체
%
% 출력:
%   STAs - 단말 구조체 배열

    STAs = struct();
    
    queue_max_size = cfg.max_packets_per_sta;
    max_delays = cfg.max_delays;

    empty_packet_entry = struct(...
        'packet_idx', NaN, ...
        'total_size', NaN, ...
        'arrival_time', NaN, ...
        'remaining_size', NaN, ...
        'first_tx_time', [], ...
        'is_bsr_wait_packet', false);

    for i = 1:numSTAs
        % 기본 정보
        STAs(i).ID = i;
        STAs(i).mode = 0;  % 0:RA mode, 1:SA mode
        
        % UORA 파라미터
        STAs(i).OCW = OCWmin;
        STAs(i).OBO = randi([0, OCWmin]);
        STAs(i).did_tx_attempt = false;
        STAs(i).accessed_RA_RU = 0;
        
        % 큐 관리 (대기 큐)
        STAs(i).packet_list = [];        % 대기 큐 (도착 대기)
        STAs(i).packet_list_next_idx = 1; % [개선] packet_list에서 다음에 읽을 인덱스

        % [개선] 활성 큐 (원형 큐로 구현)
        STAs(i).Queue = repmat(empty_packet_entry, queue_max_size, 1);
        STAs(i).queue_max_size = queue_max_size; % 큐의 최대 용량
        STAs(i).queue_head = 1;      % 읽을 위치 (첫 번째 패킷)
        STAs(i).queue_tail = 1;      % 쓸 위치 (다음 빈 슬롯)
        STAs(i).queue_size = 0;      % 현재 큐에 있는 패킷 수
        STAs(i).queue_total_bytes = 0; % [개선] 큐에 있는 모든 패킷의 remaining_size 합계
        
        % BSR 관련
        STAs(i).Q_prev = 0;              % 이전 큐 크기
        STAs(i).reported_bsr = 0;        % 마지막 보고한 BSR
        
        % v3 정책용 (EMA)
        STAs(i).Q_ema = 0;
        STAs(i).ema_initialized = false;
        
        % BSR 대기 상태 및 지연 분해
        STAs(i).is_waiting_for_first_SA = false;
        STAs(i).wait_start_time = 0;         % T_arrival
        STAs(i).last_bsr_success_time = 0; % T_bsr_success (중간 저장)
        
        % RU 할당 정보
        STAs(i).assigned_SA_RU = [];
        
        % 통계
        STAs(i).num_of_packets = 0;      % 생성된 패킷 수
        STAs(i).num_of_transmitted = 0;  % 전송 횟수
        STAs(i).transmitted_data = 0;    % 전송된 데이터 [bytes]
        
        % 지연 측정 (사전 할당)
        STAs(i).packet_queuing_delays = nan(max_delays, 1);
        STAs(i).delay_idx = 0;
        
        STAs(i).fragmentation_delays = nan(max_delays, 1);
        STAs(i).frag_idx = 0;

        STAs(i).uora_delays = nan(max_delays, 1);   % T_uora
        STAs(i).sched_delays = nan(max_delays, 1);  % T_sched
        STAs(i).delay_decomp_idx = 0; % T_uora/T_sched 공통 인덱스
        
        % 전송 완료 로그 (선택적)
        STAs(i).tx_completed_packets = struct( ...
            'packet_idx', {}, ...
            'arrival_time', {}, ...
            'tx_completed_time', {});
        STAs(i).tx_log_idx = 0;
    end
end