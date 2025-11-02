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
    
    for i = 1:numSTAs
        % 기본 정보
        STAs(i).ID = i;
        STAs(i).mode = 0;  % 0:RA mode, 1:SA mode
        
        % UORA 파라미터
        STAs(i).OCW = OCWmin;
        STAs(i).OBO = randi([0, OCWmin]);
        STAs(i).did_tx_attempt = false;
        STAs(i).accessed_RA_RU = 0;
        
        % 큐 관리
        STAs(i).Queue = [];              % 활성 큐 (전송 대기)
        STAs(i).packet_list = [];        % 대기 큐 (도착 대기)
        
        % BSR 관련
        STAs(i).Q_prev = 0;              % 이전 큐 크기
        STAs(i).reported_bsr = 0;        % 마지막 보고한 BSR
        
        % v3 정책용 (EMA)
        STAs(i).Q_ema = 0;
        STAs(i).ema_initialized = false;
        
        % BSR 대기 상태
        STAs(i).is_waiting_for_first_SA = false;
        STAs(i).wait_start_time = 0;
        
        % RU 할당 정보
        STAs(i).assigned_SA_RU = [];
        
        % 통계
        STAs(i).num_of_packets = 0;      % 생성된 패킷 수
        STAs(i).num_of_transmitted = 0;  % 전송 횟수
        STAs(i).transmitted_data = 0;    % 전송된 데이터 [bytes]
        
        % 지연 측정 (사전 할당)
        max_delays = cfg.max_delays;
        STAs(i).packet_queuing_delays = nan(max_delays, 1);
        STAs(i).delay_idx = 0;
        
        STAs(i).fragmentation_delays = nan(max_delays, 1);
        STAs(i).frag_idx = 0;
        
        STAs(i).bsr_delays = nan(1000, 1);
        STAs(i).bsr_idx = 0;
        
        % 전송 완료 로그 (선택적)
        STAs(i).tx_completed_packets = struct( ...
            'packet_idx', {}, ...
            'arrival_time', {}, ...
            'tx_completed_time', {});
        STAs(i).tx_log_idx = 0;
    end
end