function metrics = init_metrics_struct(cfg)
% INIT_METRICS_STRUCT: 메트릭 구조체 초기화 (사전 할당)
%
% 입력:
%   cfg - 설정 구조체
%
% 출력:
%   metrics - 메트릭 구조체
%
% 구조:
%   - cumulative: 누적 통계
%   - packet_level: 패킷별 메트릭
%   - policy_level: 정책 분석용 메트릭
%
% (수정: 'stage_level'은 이벤트 기반 모델과 호환되지 않아 제거됨)

    metrics = struct();
    
    %% =====================================================================
    %  1. Cumulative 메트릭 (누적 통계)
    %  =====================================================================
    
    metrics.cumulative = struct();
    
    % 시간
    metrics.cumulative.simulation_start_time = 0;
    metrics.cumulative.simulation_end_time = 0;
    
    % UORA 통계
    metrics.cumulative.total_uora_attempts = 0;
    metrics.cumulative.total_uora_collisions = 0;
    metrics.cumulative.total_uora_success = 0;
    metrics.cumulative.total_uora_idle = 0;
    
    % BSR 통계
    metrics.cumulative.total_explicit_bsr = 0;
    metrics.cumulative.total_implicit_bsr = 0;
    
    % 데이터 전송
    metrics.cumulative.total_tx_bytes = 0;
    metrics.cumulative.total_completed_pkts = 0;
    
    %% =====================================================================
    %  2. Packet-level 메트릭
    %  =====================================================================
    
    metrics.packet_level = struct();
    
    max_delays = cfg.max_delays;
    
    % 큐잉 지연
    metrics.packet_level.queuing_delays = nan(max_delays, 1);
    metrics.packet_level.packet_ids = zeros(max_delays, 1);
    metrics.packet_level.sta_ids = zeros(max_delays, 1);
    metrics.packet_level.delay_idx = 0;
    
    % 분할 전송 지연
    metrics.packet_level.frag_delays = nan(max_delays, 1);
    metrics.packet_level.frag_idx = 0;
    
    %% =====================================================================
    %  3. Stage-level 메트릭 (이벤트 기반 모델에서는 사용 안 함)
    %  =====================================================================
    
    % 'cfg.max_stages'가 config_default.m에서 제거되었으므로
    % 'stage_level' 메트릭 수집 로직 전체를 비활성화합니다.
    % 'main_sim_v2.m'의 루프는 'stage'가 아닌 'event' 기반입니다.
    
    metrics.stage_level = struct();
    metrics.stage_level.stage_idx = 0; % (참조 오류 방지를 위한 빈 구조체)
    
    
    %% =====================================================================
    %  4. Policy-level 메트릭 (BSR 정책 분석)
    %  =====================================================================
    
    if cfg.collect_bsr_trace
        metrics.policy_level = struct();
        
        % max_samples는 max_stages와 무관하므로 그대로 둡니다.
        max_samples = 1000;
        
        % BSR 정확도
        metrics.policy_level.bsr_errors = nan(max_samples, 1);
        metrics.policy_level.reduction_applied = false(max_samples, 1);
        
        % 정책 안정성
        metrics.policy_level.stability_switches = 0;
        
        % 인덱스
        metrics.policy_level.policy_idx = 0;
    else
        metrics.policy_level = struct();
        metrics.policy_level.policy_idx = 0;
    end
end