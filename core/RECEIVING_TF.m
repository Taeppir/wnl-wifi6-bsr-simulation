function STAs = RECEIVING_TF(STAs, RUs, AP, cfg, current_time)
% RECEIVING_TF: Trigger Frame 수신 및 SA-RU 할당 확인
%
% 입력:
%   STAs         - 단말 구조체 배열
%   RUs          - RU 구조체 배열
%   AP           - AP 구조체 (BSR 테이블)
%   cfg          - 설정 구조체
%   current_time - 현재 시각 [sec]
%
% 출력:
%   STAs - 업데이트된 단말 구조체
%
% 기능:
%   - SA-RU 할당 확인
%   - BSR 대기 지연 측정
%   - OCW 초기화 (SA 모드 전환 시)

    %% =====================================================================
    %  1. BSR 테이블 확인
    %  =====================================================================
    
    BSR_STAs = [];
    if ~isempty(AP.BSR)
        BSR_STAs = [AP.BSR.STA_ID];
    end
    
    %% =====================================================================
    %  2. 각 단말별 처리
    %  =====================================================================
    
    for i = 1:length(STAs)
        
        % SA-RU 할당 상태 초기화
        STAs(i).assigned_SA_RU = [];
        
        %% =================================================================
        %  Case 1: BSR 테이블에 있는 단말 (SA 모드)
        %  =================================================================
        
        if ismember(STAs(i).ID, BSR_STAs)
            
            % ⭐ Mode는 이미 UPDATE_BSR_AND_MODE에서 설정됨
            % 여기서는 확인만
            % assert(STAs(i).mode == 1, 'STA %d should be in SA mode', i);
            
            % ─────────────────────────────────────────────────────────
            % BSR 대기 지연 측정 (첫 SA-RU 할당 시)
            % ─────────────────────────────────────────────────────────
            
            if STAs(i).is_waiting_for_first_SA
                % 지연 = 현재 시각 - 대기 시작 시각
                delay = current_time - STAs(i).wait_start_time;
                
                % 사전 할당된 배열에 저장
                idx = STAs(i).bsr_idx + 1;
                STAs(i).bsr_delays(idx) = delay;
                STAs(i).bsr_idx = idx;
                
                % 대기 종료
                STAs(i).is_waiting_for_first_SA = false;
            end
            
            % ─────────────────────────────────────────────────────────
            % OCW 초기화 (SA 모드로 전환 시)
            % ─────────────────────────────────────────────────────────
            
            STAs(i).OCW = cfg.OCW_min;
            STAs(i).OBO = randi([0, cfg.OCW_min]);
            STAs(i).accessed_RA_RU = 0;
            STAs(i).did_tx_attempt = false;
            
            % ─────────────────────────────────────────────────────────
            % 할당된 SA-RU 확인
            % ─────────────────────────────────────────────────────────
            
            % 이 단말에게 할당된 SA-RU 찾기
            SA_RU_IDs = find([RUs.assignedSTA] == STAs(i).ID & [RUs.mode] == 1);
            
            if ~isempty(SA_RU_IDs)
                STAs(i).assigned_SA_RU = SA_RU_IDs;
            end
            
        %% =================================================================
        %  Case 2: BSR 테이블에 없는 단말 (RA 모드)
        %  =================================================================
        
        else
            % ⭐ Mode는 이미 DELETE_BSR_AND_MODE에서 설정됨
            % 여기서는 확인만
            % assert(STAs(i).mode == 0, 'STA %d should be in RA mode', i);
            
            % RA 모드 단말은 할당 없음
            STAs(i).assigned_SA_RU = [];
        end
    end
end