function STAs = UPDATE_QUE(STAs, current_time)
% UPDATE_QUE: 대기 큐(packet_list)에서 활성 큐(Queue)로 패킷 이동
%
% 입력:
%   STAs         - 단말 구조체 배열
%   current_time - 현재 시각 [sec]
%
% 출력:
%   STAs - 업데이트된 단말 구조체 배열

    numSTAs = length(STAs);
    
    for i = 1:numSTAs
        
        % 1. 포인터를 사용해 대기 큐가 비었는지 확인
        if STAs(i).packet_list_next_idx > STAs(i).num_of_packets
            continue;
        end
        
        % 2. 현재 시간 기준으로 도착한 패킷들의 인덱스 찾기 (상대 인덱스)
        % 남은 패킷 리스트의 도착 시간만 벡터로 추출
        next_idx = STAs(i).packet_list_next_idx;
        arrival_times_vector = [STAs(i).packet_list(next_idx : end).arrival_time];
        
        arrived_relative_indices = find(arrival_times_vector <= current_time);
        
        % 3. 도착한 패킷이 있을 경우에만 처리
        if ~isempty(arrived_relative_indices)
            
            % [개선] 큐가 비어있었는지 확인 (size 변수 사용)
            is_queue_empty_before_add = (STAs(i).queue_size == 0);
            
            % [개선] 3-1. 도착한 패킷들의 절대 인덱스 계산
            num_arrived = length(arrived_relative_indices);
            arrived_packets_data = STAs(i).packet_list(next_idx : (next_idx + num_arrived - 1));
            
            % [개선] 3-2. 큐 오버플로우 확인
            if STAs(i).queue_size + num_arrived > STAs(i).queue_max_size
                warning('STA %d: 활성 큐(Queue) 오버플로우 발생! %d개 패킷 유실', ...
                    i, num_arrived);
                % 오버플로우가 발생해도 대기 큐 포인터는 이동시켜 해당 패킷은 유실 처리
                STAs(i).packet_list_next_idx = next_idx + num_arrived;
                continue;
            end
            
            % 3-3. 활성 큐(원형 큐)에 추가
            for k = 1:num_arrived
                pkt = arrived_packets_data(k);
                
                % 활성 큐(Queue) 형식으로 변환
                queue_entry = struct(...
                    'packet_idx', pkt.packet_idx, ...
                    'total_size', pkt.total_size, ...
                    'arrival_time', pkt.arrival_time, ...
                    'remaining_size', pkt.total_size, ...
                    'first_tx_time', [], ...
                    'is_bsr_wait_packet', false, ...
                    'tx_chunks', 0);
                
                % [개선] 큐가 비어있었고, 지금 추가되는 첫 패킷(k=1)인가?
                if is_queue_empty_before_add && k == 1
                    queue_entry.is_bsr_wait_packet = true;
                end

                % tail 위치에 패킷 삽입
                tail_idx = STAs(i).queue_tail;
                STAs(i).Queue(tail_idx) = queue_entry;
                
                % tail 포인터 및 상태 변수 업데이트 (wrap-around)
                STAs(i).queue_tail = mod(tail_idx, STAs(i).queue_max_size) + 1;
                STAs(i).queue_size = STAs(i).queue_size + 1;
                STAs(i).queue_total_bytes = STAs(i).queue_total_bytes + queue_entry.remaining_size;
            end
            
            % 3-4. 대기 큐 포인터 이동 (삭제 대신)
            STAs(i).packet_list_next_idx = next_idx + num_arrived;
            
            % 3-5. BSR 대기 시작 (큐가 비어있다가 패킷이 들어온 경우만!)
            if is_queue_empty_before_add
                STAs(i).is_waiting_for_first_SA = true;
                STAs(i).wait_start_time = current_time;
            end
        end
    end
end