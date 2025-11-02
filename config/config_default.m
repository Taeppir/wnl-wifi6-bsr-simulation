function cfg = config_default()
% CONFIG_DEFAULT: 시뮬레이션 기본 설정 (이벤트 기반)
%
% 출력:
%   cfg - 설정 구조체
%
% 주요 파라미터:
%   - 네트워크: 단말 수, RU 개수
%   - PHY: 대역폭, 전송률, 패킷 크기
%   - 트래픽: Pareto On-Off 모델
%   - UORA: 백오프 윈도우
%   - BSR 정책: v0~v3

    cfg = struct();
    
    %% =====================================================================
    %  출력 옵션 ⭐ (제일 먼저 정의!)
    %  =====================================================================
    
    cfg.verbose = 1;  % 0=조용, 1=기본, 2=상세, 3=디버그
    
    %% =====================================================================
    %  네트워크 구성
    %  =====================================================================
    
    cfg.num_STAs = 20;              % 단말 수
    cfg.numRU_RA = 1;               % RA-RU 개수 (경쟁 기반)
    cfg.numRU_SA = 8;               % SA-RU 개수 (스케줄링 기반)
    cfg.numRU_total = cfg.numRU_RA + cfg.numRU_SA;
    
    %% =====================================================================
    %  시뮬레이션 시간
    %  =====================================================================
    
    % 총 시뮬레이션 시간 [sec]
    cfg.simulation_time = 10.0;
    
    % ⭐ 워밍업 시간 [sec]
    cfg.warmup_time = 2.0;
    

    
    %% =====================================================================
    %  PHY 파라미터 (⭐이벤트 기반용 시간 추가)
    %  =====================================================================
    
    cfg.bandwidth = 20e6;  % 20 MHz 채널
    
    % ⭐ RU당 전송률 [bps]
    cfg.data_rate_per_RU = 6.67e6;  % 6.67 Mbps per RU
    
    cfg.size_MPDU = 2000;  % MPDU 크기 [bytes]
    
    % ⭐ [추가] 이벤트 기반 시뮬레이션을 위한 PHY 시간 파라미터
    % (main_sim_v2.m의 요구사항)
    cfg.SIFS = 16e-6;              % 16 µs (802.11ax 표준)
    cfg.len_PHY_headers = 40e-6;   % PHY 헤더 시간 (가정치)
    cfg.len_TF = 100e-6;            % Trigger Frame 전송 시간 (가정치)
    cfg.len_MU_BACK = 68e-6;       % Multi-User Block ACK 시간 (가정치)
    
    %% =====================================================================
    %  트래픽 모델 (Pareto On-Off)
    %  =====================================================================
    
    cfg.alpha = 1.5;
    cfg.mu_on = 0.05;
    cfg.mu_off = 0.01;
    cfg.rho = cfg.mu_on / (cfg.mu_on + cfg.mu_off);
    
    total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
    
    cfg.L_cell = 0.6;
    
    cfg.lambda_network = cfg.L_cell * total_capacity / (cfg.size_MPDU * 8);
    
    cfg.lambda = cfg.lambda_network / cfg.num_STAs;
    
    % 디버그 출력
    if cfg.verbose >= 2
        fprintf('\n[트래픽 파라미터 계산]\n');
        fprintf('  네트워크 용량: %.2f Mbps (%d RU × %.2f Mbps)\n', ...
            total_capacity / 1e6, cfg.numRU_SA, cfg.data_rate_per_RU / 1e6);
        fprintf('  목표 부하율: %.0f%%\n', cfg.L_cell * 100);
        fprintf('  네트워크 전체 lambda: %.2f pkt/s\n', cfg.lambda_network);
        fprintf('  단말당 lambda: %.2f pkt/s\n', cfg.lambda);
        fprintf('  예상 생성 패킷: %.0f개 (%.1f초)\n', ...
            cfg.lambda_network * cfg.simulation_time, cfg.simulation_time);
        
        % [수정] Stage당 용량 -> RU당 용량으로 변경
        fprintf('  RU당 전송 용량: %d bytes\n', cfg.size_MPDU);
        fprintf('  RU당 전송 시간: %.2f µs\n', (cfg.size_MPDU * 8) / cfg.data_rate_per_RU * 1e6);
    end
    
    %% =====================================================================
    %  UORA 파라미터
    %  =====================================================================
    
    cfg.OCW_min = 15;
    cfg.OCW_max = 31;
    
    %% =====================================================================
    %  BSR 정책 (제안 기법)
    %  =====================================================================
    
    cfg.scheme_id = 0;
    
    cfg.v1_fixed_reduction_bytes = 500;
    cfg.v2_max_reduction = 0.7;
    cfg.v3_EMA_alpha = 0.2;
    cfg.v3_sensitivity = 1.0;
    cfg.v3_max_reduction = 0.7;
    
    cfg.burst_threshold = 1000;
    cfg.reduction_threshold = 500;
    
    %% =====================================================================
    %  메트릭 수집
    %  =====================================================================
    
    cfg.collect_bsr_trace = true;
    
    %% =====================================================================
    %  사전 할당 크기 ⭐
    %  =====================================================================
    
    cfg.max_packets_per_sta = 10000;
    cfg.max_delays = 20000;
    
    
    if cfg.verbose >= 2
        fprintf('\n[사전 할당 크기]\n');
        fprintf('  단말당 최대 패킷: %d개\n', cfg.max_packets_per_sta);
        fprintf('  최대 지연 샘플: %d개\n', cfg.max_delays);
        fprintf('  예상 메모리: %.2f MB\n', (cfg.max_delays * 8) / 1e6);
    end
end