function [STAs, AP] = UPDATE_BSR_AND_MODE(STAs, AP, sta_idx, buffer_status)
% UPDATE_BSR_AND_MODE: BSR 업데이트 + mode 자동 동기화
%
% 입력:
%   STAs          - 단말 구조체 배열
%   AP            - AP 구조체
%   sta_idx       - 단말 인덱스
%   buffer_status - 버퍼 상태 [bytes]
%
% 출력:
%   STAs - mode가 업데이트된 단말 구조체
%   AP   - BSR 테이블이 업데이트된 AP 구조체

    %% =====================================================================
    %  1. BSR 테이블 업데이트
    %  =====================================================================
    if sta_idx > 0 && sta_idx <= length(AP.BSR)
        % STA_ID는 이미 1:N으로 채워져 있으므로 Buffer_Status만 갱신
        AP.BSR(sta_idx).Buffer_Status = buffer_status;
    else
        warning('UPDATE_BSR_AND_MODE: 유효하지 않은 sta_idx(%d)입니다.', sta_idx);
    end

    %% =====================================================================
    %  2. Mode 자동 동기화
    %  =====================================================================
    
    if buffer_status > 0
        STAs(sta_idx).mode = 1;  % SA 모드
    else
        STAs(sta_idx).mode = 0;  % RA 모드
    end
end