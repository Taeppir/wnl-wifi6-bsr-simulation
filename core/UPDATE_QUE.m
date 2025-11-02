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
        
        % 1. 대기 큐가 비어있으면 건너뛰기
        if isempty(STAs(i).packet_list)
            continue;
        end
        
        % 2. 현재 시간 기준으로 도착한 패킷들의 인덱스 찾기
        arrival_times_vector = [STAs(i).packet_list.arrival_time];
        arrived_indices = find(arrival_times_vector <= current_time);
        
        % 3. 도착한 패킷이 있을 경우에만 처리
        if ~isempty(arrived_indices)
            
            % 큐가 비어있었는지 확인 (BSR 대기 시작 판단용)
            is_queue_empty_before_add = isempty(STAs(i).Queue);
            
            % 3-1. 도착한 패킷들을 임시 변수에 복사
            arrived_packets = STAs(i).packet_list(arrived_indices);
            
            % 3-2. 활성 큐(Queue) 형식으로 변환
            temp_queue_entries = struct(...
                'packet_idx', {arrived_packets.packet_idx}, ...
                'total_size', {arrived_packets.total_size}, ...
                'arrival_time', {arrived_packets.arrival_time}, ...
                'remaining_size', {arrived_packets.total_size}, ...
                'first_tx_time', []);
            
            % 3-3. 활성 큐에 추가
            STAs(i).Queue = [STAs(i).Queue, temp_queue_entries];
            
            % 3-4. 대기 큐에서 삭제
            STAs(i).packet_list(arrived_indices) = [];
            
            % 3-5. BSR 대기 시작 (큐가 비어있다가 패킷이 들어온 경우만!)
            if is_queue_empty_before_add
                STAs(i).is_waiting_for_first_SA = true;
                STAs(i).wait_start_time = current_time;
            end
        end
    end
end