function STAs = UORA(STAs, numRU)
% UORA: OFDMA 백오프 및 RU 접근 경쟁
%
% 입력:
%   STAs  - 단말 구조체 배열
%   numRU - 경쟁할 RU 개수 (보통 SA-RU 개수 = numRU_SA)
%
% 출력:
%   STAs - 업데이트된 단말 구조체 배열
%
% 동작:
%   1. OBO 카운터 초기화 (이전에 전송 시도했으면)
%   2. OBO -= numRU (감소)
%   3. OBO <= 0이면 RU 접근 시도
%
% 참고:
%   IEEE 802.11ax 표준에서 연결된 단말들은 AID=0인 RU들에 대해
%   UORA를 통해 경쟁함. numRU는 보통 SA-RU 개수를 의미.

    for i = 1:length(STAs)

        % UORA 참여 조건 확인: 전송할 데이터가 있고, RA mode
        has_data = ~isempty(STAs(i).Queue);
        is_ra_mode = (STAs(i).mode == 0);
        
        should_participate = has_data && is_ra_mode;
        
        if ~should_participate
            % UORA 참여 안 함
            STAs(i).accessed_RA_RU = 0;
            continue;
        end
        
        % ─────────────────────────────────────────────────────────
        % 여기서부터는 UORA 참여 단말만 처리
        % ─────────────────────────────────────────────────────────
        
        % 1. OBO 카운터 준비
        if STAs(i).did_tx_attempt
            STAs(i).OBO = randi([0, STAs(i).OCW]);
            STAs(i).did_tx_attempt = false;
        end
        
        % 2. OBO 카운터 감소
        STAs(i).OBO = STAs(i).OBO - numRU;
        
        % 3. 전송 여부 결정
        if STAs(i).OBO <= 0
            % RA-RU 접근 시도
            STAs(i).accessed_RA_RU = ACCESSING_RA_RU(numRU);
            STAs(i).did_tx_attempt = true;
        else
            % 접근 안 함
            STAs(i).accessed_RA_RU = 0;
        end
        
    end
end