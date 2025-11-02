function [RUs, AP] = SCHEDULING_RU(RUs, AP, numRU_SA, numRU_RA, size_MPDU)
% SCHEDULING_RU: AP가 BSR 기반으로 SA-RU 할당 (우선순위 기반)
%
% 입력:
%   RUs      - RU 구조체 배열
%   AP       - AP 구조체 (BSR 테이블)
%   numRU_SA - SA-RU 개수
%   numRU_RA - RA-RU 개수
%
% 출력:
%   RUs - SA-RU 할당 정보가 업데이트된 RU 구조체
%   AP  - 업데이트된 AP 구조체
% 버그 수정 (2025.11.02):
%   - Round-Robin 조기 종료 문제 해결
%   - 버퍼가 있는 모든 STA에게 공평하게 RU 할당

    %% =====================================================================
    %  1. 초기 조건 검사
    %  =====================================================================
    
    if isempty(AP.BSR)
        return;
    end
    
    % BSR 테이블에서 정보 추출
    STAid_BSR = [AP.BSR.STA_ID];
    BufferStatus_BSR = [AP.BSR.Buffer_Status];
    
    % 할당 가능한 SA-RU 인덱스
    SA_RU_idx = (numRU_RA + 1):(numRU_RA + numRU_SA);
    
    % 버퍼가 0보다 큰 단말만 선택
    valid_mask = BufferStatus_BSR > 0;
    valid_STAid = STAid_BSR(valid_mask);
    valid_buffers = BufferStatus_BSR(valid_mask);
    
    if isempty(valid_STAid) || isempty(SA_RU_idx)
        return;
    end
    
    %% =====================================================================
    %  2. 우선순위 목록 생성 (버퍼 크기 기준 내림차순 정렬)
    %  =====================================================================
    
    [sorted_buffers, sorted_indices] = sort(valid_buffers, 'descend');
    sorted_STAid_list = valid_STAid(sorted_indices);
    
    num_stas_to_schedule = length(sorted_STAid_list);
    num_available_RUs = numRU_SA;
    
    %% =====================================================================
    %  3. Round-Robin 할당 (우선순위 기반)
    %  =====================================================================
    
    % RU당 전송 용량을 정의 (UL_TRANSMITTING_v2와 일치해야 함)
    bytes_per_RU = size_MPDU;

    % 라운드-로빈 포인터: 1 = 우선순위 1번 STA
    rr_idx = 1; 
    
    for i = 1:num_available_RUs
        
        % 모든 STA의 버퍼가 소진되었는지 확인
        if all(sorted_buffers <= 0)
            % 할당할 수 있는 STA가 없으면 종료
            break;
        end

        % 'rr_idx'부터 시작하여 버퍼가 남아있는 다음 STA를 찾습니다.
        
        attempts = 0;
        % 'rr_idx'가 가리키는 STA의 버퍼가 0이면, 
        % 버퍼가 0이 아닌 다음 STA를 찾을 때까지 포인터를 이동
        while sorted_buffers(rr_idx) <= 0 && attempts < num_stas_to_schedule
            rr_idx = mod(rr_idx, num_stas_to_schedule) + 1; % 다음 STA로 이동
            attempts = attempts + 1;
        end

        % (안전장치) 모든 STA를 순회했는데도 버퍼가 있는 STA를 못 찾은 경우
        if attempts >= num_stas_to_schedule
            break; 
        end
        
        % 이제 'rr_idx'는 버퍼가 남아있는 STA를 정확히 가리킴

        % RU 할당
        assigned_sta_id = sorted_STAid_list(rr_idx);
        RUs(SA_RU_idx(i)).assignedSTA = assigned_sta_id;
        
        % 스케줄러가 가상으로 버퍼를 차감
        sorted_buffers(rr_idx) = ...
            max(0, sorted_buffers(rr_idx) - bytes_per_RU);
        
        % ⭐ [핵심] 다음 RU를 할당하기 위해 포인터를 다음 STA로 이동
        rr_idx = mod(rr_idx, num_stas_to_schedule) + 1;
        
    end
    
end