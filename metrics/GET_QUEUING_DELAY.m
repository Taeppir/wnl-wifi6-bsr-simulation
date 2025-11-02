function STAs = GET_QUEUING_DELAY(STAs, tx_complete_time, tx_log)
% GET_QUEUING_DELAY: 큐잉 지연 측정 및 기록
%
% 입력:
%   STAs             - 단말 구조체 배열
%   tx_complete_time - 전송 완료 시각
%   tx_log           - UL_TRANSMITTING_v2의 전송 로그
%
% 출력:
%   STAs - 지연 정보가 업데이트된 단말 구조체
%
% 참고: main_sim_v2에서 이미 처리하므로 선택적

    if isempty(tx_log.completed_packets)
        return;
    end
    
    for i = 1:length(tx_log.completed_packets)
        pkt_info = tx_log.completed_packets(i);
        sta_idx = pkt_info.sta_idx;
        
        % 큐잉 지연 기록
        idx = STAs(sta_idx).delay_idx + 1;
        STAs(sta_idx).packet_queuing_delays(idx) = pkt_info.queuing_delay;
        STAs(sta_idx).delay_idx = idx;
        
        % 분할 지연 기록
        if pkt_info.fragmentation_delay > 0
            idx_frag = STAs(sta_idx).frag_idx + 1;
            STAs(sta_idx).fragmentation_delays(idx_frag) = pkt_info.fragmentation_delay;
            STAs(sta_idx).frag_idx = idx_frag;
        end
    end
end