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
        valid_mask = ~isnan([AP.BSR.Buffer_Status]);
        BSR_STAs = [AP.BSR(valid_mask).STA_ID];
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

            if isempty(STAs(i).assigned_SA_RU) || STAs(i).last_ru_assigned_time == 0
                STAs(i).last_ru_assigned_time = current_time;
            end
            
            % ─────────────────────────────────────────────────────────
            % BSR 대기 지연 측정 (첫 SA-RU 할당 시)
            % ─────────────────────────────────────────────────────────
            
            if STAs(i).is_waiting_for_first_SA
                
                T_arrival = STAs(i).wait_start_time;
                T_bsr_success = STAs(i).last_bsr_success_time;
                T_ru_assigned = current_time; % 현재 시각
                
                % BSR 성공 시각(T_bsr_success)이 기록되었는지 확인
                if T_bsr_success > T_arrival
                    % Case A: Explicit BSR 성공 후 SA-RU 할당
                    T_uora = T_bsr_success - T_arrival;
                    T_sched = T_ru_assigned - T_bsr_success;
                else
                    % Case B: BSR 성공 전에 SA-RU를 받은 경우
                    % (예: Implicit BSR이 더 빨랐거나, T_bsr_success 기록 실패)
                    % 이 경우 T_uora = 0, T_sched = T_ru_assigned - T_arrival
                    T_uora = 0;
                    T_sched = T_ru_assigned - T_arrival;
                end
                
                % 사전 할당된 배열에 저장
                idx = STAs(i).delay_decomp_idx + 1;
                
                if idx <= length(STAs(i).uora_delays)
                    STAs(i).uora_delays(idx) = T_uora;
                    STAs(i).sched_delays(idx) = T_sched;
                    STAs(i).delay_decomp_idx = idx;
                else
                    warning('STA %d: 지연 분해(delay_decomp) 배열 크기 초과', i);
                end
                
                % 대기 종료 및 임시 변수 리셋
                STAs(i).is_waiting_for_first_SA = false;
                STAs(i).last_bsr_success_time = 0; 
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
            STAs(i).last_ru_assigned_time = 0;
        end
    end
end