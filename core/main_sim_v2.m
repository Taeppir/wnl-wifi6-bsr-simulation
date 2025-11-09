function [results, metrics] = main_sim_v2(cfg)
% MAIN_SIM_EVENT: IEEE 802.11ax 상향링크 시뮬레이션 (이벤트 기반)
%
% 'main_sim.m'의 이벤트 기반 루프와 'main_sim_v2.m'의
% 최신 함수 및 메트릭 구조를 결합한 버전입니다.
%
% ⚠️ 중요: 이 코드는 'config_default.m'에 다음 파라미터가
%          정의되어 있다고 가정합니다. (이전 main_sim.m 기반)
%
%   cfg.len_TF          % Trigger Frame 전송 시간
%   cfg.len_PHY_headers % PHY 헤더 시간
%   cfg.SIFS            % SIFS 시간
%   cfg.len_MU_BACK     % Multi-User Block ACK 시간

    %% =====================================================================
    %  1. 초기화 (main_sim_v2.m 스타일)
    %  =====================================================================
    
    if cfg.verbose >= 1
        fprintf('\n========================================\n');
        fprintf('  이벤트 기반 시뮬레이션 시작\n');
        fprintf('========================================\n');
        fprintf('  Scheme: %s (ID=%d)\n', get_scheme_name(cfg.scheme_id), cfg.scheme_id);
        fprintf('  STAs: %d, RUs: %d (RA:%d, SA:%d)\n', ...
            cfg.num_STAs, cfg.numRU_total, cfg.numRU_RA, cfg.numRU_SA);
        fprintf('  시뮬레이션 시간: %.1f초 (워밍업: %.1f초)\n', ...
            cfg.simulation_time, cfg.warmup_time);
        tic;
    end
    
    % v2 함수들로 초기화
    AP = DEFINE_AP(cfg.num_STAs);
    STAs = DEFINE_STAs_v2(cfg.num_STAs, cfg.OCW_min, cfg);
    RUs = DEFINE_RUs(cfg.numRU_total, cfg.numRU_RA);
    metrics = init_metrics_struct(cfg); % v2 메트릭
    
    % v2 트래픽 생성
    if cfg.verbose >= 1, fprintf('\n[트래픽 생성]\n'); end
    STAs = gen_onoff_pareto_v2(STAs, cfg);
    if cfg.verbose >= 1, validate_traffic(STAs, cfg); end
    
    %% =====================================================================
    %  2. 메인 시뮬레이션 루프 (이벤트 기반 'while')
    %  =====================================================================
    
    if cfg.verbose >= 1
        fprintf('\n========================================\n');
        fprintf('  메인 루프 시작\n');
        fprintf('========================================\n\n');
    end
    
    current_time = 0.0;
    metrics.cumulative.simulation_start_time = current_time;
    
    while current_time < cfg.simulation_time
        
        is_warmup = (current_time <= cfg.warmup_time);
        
        % -----------------------------------------------------------------
        % Event 1: Trigger Frame (TF) 전송
        % -----------------------------------------------------------------
        
        RUs = INIT_RUs(RUs);
        
        % ⭐ v2의 "스마트 스케줄러" 호출 (cfg.size_MPDU 전달)
        [RUs, AP] = SCHEDULING_RU(RUs, AP, cfg.numRU_SA, cfg.numRU_RA, cfg.size_MPDU);
        
        % ⭐ 시간 증가 1: TF + PHY 헤더
        t_next = current_time + cfg.len_TF + cfg.len_PHY_headers;
        if t_next > cfg.simulation_time, break; end
        current_time = t_next;
        
        % -----------------------------------------------------------------
        % Event 2: TF 수신 및 큐 업데이트
        % -----------------------------------------------------------------
        
        % ⭐ v2 함수 호출 (BSR 지연 측정)
        STAs = RECEIVING_TF(STAs, RUs, AP, cfg, current_time);
        STAs = UPDATE_QUE(STAs, current_time);

        % ⭐ 시간 증가 2: SIFS
        t_next = current_time + cfg.SIFS;
        if t_next > cfg.simulation_time, break; end
        current_time = t_next;
        
        % -----------------------------------------------------------------
        % Event 3: UORA 경쟁 (시간 소모 0으로 가정)
        % -----------------------------------------------------------------
        
        % ⭐ v2 함수 호출
        STAs = UORA(STAs, cfg.numRU_RA);
        
        % -----------------------------------------------------------------
        % Event 4: 상향링크(UL) 전송
        % -----------------------------------------------------------------
        
        % ⭐ 시간 증가 3: 실제 데이터 전송 시간 계산
        % (주의: main_sim.m은 고정된 data_tx_time을 썼지만,
        %  UL_TRANSMITTING_v2는 tx_complete_time을 입력받음)
        %
        % 여기서는 main_sim.m의 접근 방식을 따릅니다.
        % (cfg.size_MPDU / cfg.data_rate_per_RU)가 평균 전송 시간
        
        data_tx_time = (cfg.size_MPDU * 8) / cfg.data_rate_per_RU;
        
        t_next = current_time + data_tx_time + cfg.len_PHY_headers;
        if t_next > cfg.simulation_time, break; end
        tx_complete_time = t_next; % 전송 완료 시각
        
        % ⭐ v2 함수 호출
        [STAs, AP, RUs, tx_log, metrics] = UL_TRANSMITTING_v2(STAs, AP, RUs, tx_complete_time, cfg, metrics);
        
        current_time = tx_complete_time;
        
        % -----------------------------------------------------------------
        % Event 5: ACK/BA 수신
        % -----------------------------------------------------------------
        
        % ⭐ 시간 증가 4: SIFS + MU-BACK + ...
        t_next = current_time + cfg.SIFS + cfg.len_MU_BACK + cfg.len_PHY_headers + cfg.SIFS;
        if t_next > cfg.simulation_time, break; end
        current_time = t_next;
        
        % -----------------------------------------------------------------
        % Event 6: 메트릭 수집 (v2 스타일)
        % -----------------------------------------------------------------
        
        if ~is_warmup
            % --- 6.1: Cumulative 메트릭 누적 ---
            
            % UORA (RA)
            metrics.cumulative.total_uora_attempts = metrics.cumulative.total_uora_attempts + ...
                (tx_log.num_ra_success + tx_log.num_ra_collision);
            metrics.cumulative.total_uora_collisions = metrics.cumulative.total_uora_collisions + tx_log.num_ra_collision;
            metrics.cumulative.total_uora_success = metrics.cumulative.total_uora_success + tx_log.num_ra_success;
            metrics.cumulative.total_uora_idle = metrics.cumulative.total_uora_idle + tx_log.num_ra_idle;
            
            if isfield(tx_log, 'num_ra_idle')
                metrics.cumulative.total_uora_idle = metrics.cumulative.total_uora_idle + tx_log.num_ra_idle;
            end
            
            % BSR
            metrics.cumulative.total_explicit_bsr = metrics.cumulative.total_explicit_bsr + tx_log.num_explicit_bsr;
            metrics.cumulative.total_implicit_bsr = metrics.cumulative.total_implicit_bsr + tx_log.num_implicit_bsr;
            
            % 데이터 전송
            metrics.cumulative.total_tx_bytes = metrics.cumulative.total_tx_bytes + tx_log.total_tx_bytes;
            
            % --- 6.2: Packet-level 메트릭 누적 ---
            
            num_completed = length(tx_log.completed_packets);
            
            if num_completed > 0
                % ⭐ [핵심] 완료 패킷 수 누적
                metrics.cumulative.total_completed_pkts = metrics.cumulative.total_completed_pkts + num_completed;
            
                % 지연 시간 정보 추출
                delays = [tx_log.completed_packets.queuing_delay];
                p_ids = [tx_log.completed_packets.packet_idx];
                s_ids = [tx_log.completed_packets.sta_idx];
                
                % 사전 할당된 배열에 복사
                start_idx = metrics.packet_level.delay_idx + 1;
                end_idx = metrics.packet_level.delay_idx + num_completed;
                
                if end_idx <= cfg.max_delays
                    metrics.packet_level.queuing_delays(start_idx:end_idx) = delays;
                    metrics.packet_level.packet_ids(start_idx:end_idx) = p_ids;
                    metrics.packet_level.sta_ids(start_idx:end_idx) = s_ids;
                    metrics.packet_level.delay_idx = end_idx;
                else
                    % 경고: 사전 할당된 배열 크기 초과
                end
                
                % 분할 전송 지연도 동일하게 처리
                frag_delays = [tx_log.completed_packets.fragmentation_delay];
                f_start_idx = metrics.packet_level.frag_idx + 1;
                f_end_idx = metrics.packet_level.frag_idx + num_completed;
                if f_end_idx <= cfg.max_delays
                     metrics.packet_level.frag_delays(f_start_idx:f_end_idx) = frag_delays;
                     metrics.packet_level.frag_idx = f_end_idx;
                end
            end
            
        end % if ~is_warmup
        
    end % while loop
    
    %% =====================================================================
    %  3. 시뮬레이션 종료 및 분석 (main_sim_v2.m 스타일)
    %  =====================================================================
    
    metrics.cumulative.simulation_end_time = current_time;
    
    if cfg.verbose >= 1
        elapsed_total = toc;
        fprintf('\n========================================\n');
        fprintf('  시뮬레이션 완료\n');
        fprintf('========================================\n');
        fprintf('실제 소요 시간: %.2f 초\n', elapsed_total);
        fprintf('시뮬레이션 시간: %.2f 초\n', current_time);
        fprintf('가속비: %.1fx\n\n', current_time / elapsed_total);
    end
    
    % v2 분석 함수 호출
    results = ANALYZE_RESULTS_v2(STAs, AP, metrics, cfg);
    
    if cfg.verbose >= 1
        results.elapsed_time = elapsed_total;
        print_results_summary(results); % v2의 요약 프린트 함수
    end
end
%% =========================================================================
%  Helper Functions
%  =========================================================================

function name = get_scheme_name(scheme_id)
    switch scheme_id
        case 0
            name = 'Baseline (R=Q)';
        case 1
            name = 'v1 (Fixed Reduction)';
        case 2
            name = 'v2 (Proportional Reduction)';
        case 3
            name = 'v3 (EMA-based)';
        otherwise
            name = sprintf('Unknown (%d)', scheme_id);
    end
end

function print_results_summary(results)
    fprintf('========================================\n');
    fprintf('  결과 요약\n');
    fprintf('========================================\n\n');
    
    fprintf('[패킷 통계]\n');
    fprintf('  생성: %d개\n', results.total_generated_packets);
    fprintf('  완료: %d개\n', results.total_completed_packets);
    fprintf('  완료율: %.1f%%\n', results.packet_completion_rate * 100);
    
    fprintf('\n[지연]\n');
    fprintf('  평균: %.4f ms\n', results.summary.mean_delay_ms);
    fprintf('  P90: %.4f ms\n', results.summary.p90_delay_ms);
    fprintf('  P99: %.4f ms\n', results.summary.p99_delay_ms);
    
    fprintf('\n[처리율]\n');
    fprintf('  총 전송: %.2f MB\n', results.throughput.total_tx_mb);
    fprintf('  처리율: %.2f Mb/s\n', results.summary.throughput_mbps);
    fprintf('  채널 이용률: %.1f%%\n', results.summary.channel_utilization * 100);
    
    fprintf('\n[UORA (RA-RU)]\n');
    fprintf('  충돌률: %.2f%%\n', results.summary.collision_rate * 100);
    fprintf('  성공률: %.2f%%\n', results.summary.success_rate * 100);
    
    fprintf('\n[BSR]\n');
    fprintf('  Explicit: %d회\n', results.bsr.total_explicit);
    fprintf('  Implicit: %d회\n', results.bsr.total_implicit);
    fprintf('  Implicit 비율: %.1f%%\n', results.summary.implicit_bsr_ratio * 100);
    
    if isfield(results.bsr, 'mean_error') && ~isnan(results.bsr.mean_error)
        fprintf('  평균 오차: %.1f bytes\n', results.bsr.mean_error);
        fprintf('  감소 적용 빈도: %.1f%%\n', results.bsr.reduction_frequency * 100);
    end
    
    fprintf('\n[공평성]\n');
    fprintf('  Jain Index: %.3f\n', results.summary.jain_index);
    
    fprintf('\n========================================\n\n');
end