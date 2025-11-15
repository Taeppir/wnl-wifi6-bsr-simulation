function [STAs, AP, RUs, tx_log, metrics] = UL_TRANSMITTING_v2(STAs, AP, RUs, tx_start_time, tx_complete_time, cfg, metrics)
% UL_TRANSMITTING_V2: 상향링크 전송 (RA-RU + SA-RU 통합)
%
% 입력:
%   STAs             - 단말 구조체 배열
%   AP               - AP 구조체
%   RUs              - RU 구조체 배열
%   tx_complete_time - 전송 완료 시각 [sec]
%   cfg              - 설정 구조체
%
% 출력:
%   STAs   - 업데이트된 단말 구조체
%   AP     - 업데이트된 AP 구조체
%   RUs    - 업데이트된 RU 구조체
%   tx_log - 전송 로그 구조체

    %% =====================================================================
    %  1. 전송 로그 초기화
    %  =====================================================================
    
    tx_log = struct();
    tx_log.total_tx_bytes = 0;
    tx_log.num_explicit_bsr = 0;
    tx_log.num_implicit_bsr = 0;
    tx_log.num_ra_success = 0;
    tx_log.num_ra_collision = 0;
    tx_log.num_ra_idle = 0;
    
    max_completions = cfg.numRU_SA;

    tx_log.completed_packets = struct( ...
        'sta_idx', num2cell(nan(max_completions, 1)), ...
        'packet_idx', num2cell(nan(max_completions, 1)), ...
        'arrival_time', num2cell(nan(max_completions, 1)), ...
        'tx_complete_time', num2cell(nan(max_completions, 1)), ...
        'first_tx_time', num2cell(nan(max_completions, 1)), ...
        'queuing_delay', num2cell(nan(max_completions, 1)), ...
        'fragmentation_delay', num2cell(nan(max_completions, 1)), ...
        'is_bsr_wait_packet', num2cell(false(max_completions, 1)));

    log_idx = 0;
    bytes_per_RU = cfg.size_MPDU;
    
    %% =====================================================================
    %  2. RA-RU 처리 (Explicit BSR) ⭐
    %  =====================================================================
    
    % RA-RU 충돌 감지
    RUs = DETECTING_RU_COLLISION(RUs, STAs);
    
    % RA-RU별 처리 (보통 1개)
    for ru_idx = 1:cfg.numRU_RA
        
        accessed_STAs = RUs(ru_idx).accessedSTAs;
        num_accessed = length(accessed_STAs);
        
        if num_accessed == 0
            % 유휴
            tx_log.num_ra_idle = tx_log.num_ra_idle + 1;
            
        elseif num_accessed == 1
            % 성공: Explicit BSR 전송
            tx_log.num_ra_success = tx_log.num_ra_success + 1;
            
            sta_idx = accessed_STAs(1);
            
            % OCW 초기화
            STAs(sta_idx).OCW = cfg.OCW_min;
            
            % 현재 큐 크기 조회
            Q_current = STAs(sta_idx).queue_total_bytes;
            
            if Q_current > 0
                % BSR 정책 적용
                [R_explicit, STAs, metrics] = compute_bsr_policy(STAs, sta_idx, Q_current, tx_complete_time, cfg, metrics);
                
                % BSR + mode 업데이트
                [STAs, AP] = UPDATE_BSR_AND_MODE(STAs, AP, sta_idx, R_explicit);
                
                tx_log.num_explicit_bsr = tx_log.num_explicit_bsr + 1;

                % 지연 분해를 위해 BSR 성공 시각(T_bsr_success) 기록
                STAs(sta_idx).last_bsr_success_time = tx_complete_time;
            end
            
        else
            % 충돌
            tx_log.num_ra_collision = tx_log.num_ra_collision + 1;
            
            % OCW 증가 (Binary Exponential Backoff)
            for sta_idx = accessed_STAs
                old_ocw = STAs(sta_idx).OCW;
                STAs(sta_idx).OCW = min(2 * (old_ocw + 1) - 1, cfg.OCW_max);
            end
        end
    end
    
    %% =====================================================================
    %  3. SA-RU 처리 (데이터 전송 + Implicit BSR) ⭐
    %  =====================================================================
    
    for ru_idx = (cfg.numRU_RA + 1):cfg.numRU_total
        
        assigned_sta = RUs(ru_idx).assignedSTA;
        
        if assigned_sta == 0
            continue;
        end
        
        sta_idx = assigned_sta;
        
        % 큐가 비어있는지 확인
        if STAs(sta_idx).queue_size == 0
            continue;
        end
        
        head_idx = STAs(sta_idx).queue_head;
        %% =================================================================
        %  Step 3.1: 전송할 데이터 결정
        %  =================================================================
        
        %  Queue(head_idx)에서 패킷 읽기
        pkt_remaining = STAs(sta_idx).Queue(head_idx).remaining_size;
        actual_tx_bytes = min(bytes_per_RU, pkt_remaining);
        
        %% =================================================================
        %  Step 3.2: 패킷 상태 업데이트
        %  =================================================================
        
        % Queue(head_idx)의 remaining_size 업데이트
        new_remaining_size = pkt_remaining - actual_tx_bytes;
        STAs(sta_idx).Queue(head_idx).remaining_size = new_remaining_size;
        
        % queue_total_bytes 업데이트 (sum() 대신)
        STAs(sta_idx).queue_total_bytes = STAs(sta_idx).queue_total_bytes - actual_tx_bytes;
        
        % tx_chunks 카운터 증가
        STAs(sta_idx).Queue(head_idx).tx_chunks = STAs(sta_idx).Queue(head_idx).tx_chunks + 1;

        % 첫 전송 시각 기록
        if isempty(STAs(sta_idx).Queue(head_idx).first_tx_time)
            STAs(sta_idx).Queue(head_idx).first_tx_time = tx_start_time;
        end
        
        % 전송 통계 업데이트
        STAs(sta_idx).num_of_transmitted = STAs(sta_idx).num_of_transmitted + 1;
        STAs(sta_idx).transmitted_data = STAs(sta_idx).transmitted_data + actual_tx_bytes;
        
        tx_log.total_tx_bytes = tx_log.total_tx_bytes + actual_tx_bytes;
        
        %% =================================================================
        %  Step 3.3: 패킷 완료 처리 (Dequeue)
        %  =================================================================
        
        if new_remaining_size <= 0
            % 패킷 전송 완료!

            % 완료된 패킷 정보 읽기 (head_idx 사용)
            pkt = STAs(sta_idx).Queue(head_idx);
            
            completed_pkt_info = struct();
            completed_pkt_info.sta_idx = sta_idx;
            completed_pkt_info.packet_idx = pkt.packet_idx;
            completed_pkt_info.arrival_time = pkt.arrival_time;
            completed_pkt_info.tx_complete_time = tx_complete_time;


            completed_pkt_info.first_tx_time = pkt.first_tx_time;
            completed_pkt_info.queuing_delay = tx_complete_time - pkt.arrival_time;

            if pkt.tx_chunks > 1
                % 2번 이상 전송됨 (단편화 발생)
                completed_pkt_info.fragmentation_delay = tx_complete_time - pkt.first_tx_time;
            else
                % 1번에 전송됨 (단편화 아님)
                completed_pkt_info.fragmentation_delay = 0;
            end
            
            % BSR 대기 패킷 플래그 복사
            completed_pkt_info.is_bsr_wait_packet = pkt.is_bsr_wait_packet;

            % 사전 할당된 로그에 저장
            log_idx = log_idx + 1;
            if log_idx <= max_completions
                tx_log.completed_packets(log_idx) = completed_pkt_info;
            else
                % 이 경고가 발생하면 max_completions 계산 로직 재검토 필요
                warning('UL_TRANSMITTING_v2: completed_packets 사전 할당 크기 초과');
            end
            
            % 큐에서 제거 (head 포인터 이동 및 size 감소) (데이터를 실제로 지우지 않음)
            STAs(sta_idx).queue_head = mod(head_idx, STAs(sta_idx).queue_max_size) + 1;
            STAs(sta_idx).queue_size = STAs(sta_idx).queue_size - 1;
        end
        
        %% =================================================================
        %  Step 3.4: Implicit BSR 전송 ⭐
        %  =================================================================
        
        % 전송 후 남은 버퍼 계산
        remaining_buffer = STAs(sta_idx).queue_total_bytes;
        
        % BSR 정책 적용
        [R_implicit, STAs, metrics] = compute_bsr_policy(STAs, sta_idx, remaining_buffer,tx_complete_time, cfg, metrics);
        
        % BSR + mode 업데이트
        [STAs, AP] = UPDATE_BSR_AND_MODE(STAs, AP, sta_idx, R_implicit);
        
        tx_log.num_implicit_bsr = tx_log.num_implicit_bsr + 1;
        
        %% =================================================================
        %  Step 3.5: 큐가 비었으면 BSR 삭제 + mode 전환
        %  =================================================================
        
        if STAs(sta_idx).queue_size == 0
            [STAs, AP] = DELETE_BSR_AND_MODE(STAs, AP, sta_idx);
        end
        
    end  % End of SA-RU loop
    
    %% =====================================================================
    %  4. AP 수신 데이터 업데이트
    %  =====================================================================
    
    AP.total_rx_data = AP.total_rx_data + tx_log.total_tx_bytes;
    
    %% =====================================================================
    %  5. 완료 패킷 로그 정리
    %  =====================================================================
    
    tx_log.completed_packets = tx_log.completed_packets(1:log_idx);
end