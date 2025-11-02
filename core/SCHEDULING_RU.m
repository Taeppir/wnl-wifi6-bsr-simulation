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
    
    % ⭐ 1. RU당 전송 용량을 정의합니다 (UL_TRANSMITTING_v2와 일치해야 함)
    bytes_per_RU = size_MPDU; %
    
    for i = 1:num_available_RUs
        % Round-robin: 우선순위 목록을 순환하며 할당
        sta_idx_for_this_ru = mod(i - 1, num_stas_to_schedule) + 1;
        
        % 버퍼가 소진되었으면 조기 종료 (또는 다음 STA로)
        if sorted_buffers(sta_idx_for_this_ru) <= 0
            % 만약 1순위 STA의 버퍼가 다 찼으면 다음 STA로 넘어가야 하지만,
            % 지금은 대상이 1명이므로 break와 동일하게 동작합니다.
            % (만약 여러 STA가 있다면, 이 부분을 continue로 바꾸고
            %  모든 STA의 버퍼가 0인지 체크하는 로직이 필요합니다.)
            break; 
        end
        
        % RU 할당
        assigned_sta_id = sorted_STAid_list(sta_idx_for_this_ru);
        RUs(SA_RU_idx(i)).assignedSTA = assigned_sta_id;
        
        % ⭐ 2. 스케줄러가 가상으로 버퍼를 차감합니다 (핵심 수정)
        sorted_buffers(sta_idx_for_this_ru) = ...
            sorted_buffers(sta_idx_for_this_ru) - bytes_per_RU;
        
    end
end