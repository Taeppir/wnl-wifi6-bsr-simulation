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
    
    idx = find([AP.BSR.STA_ID] == sta_idx, 1);
    
    if isempty(idx)
        % 새로 추가
        new_entry = struct('STA_ID', sta_idx, 'Buffer_Status', buffer_status);
        AP.BSR(end+1) = new_entry;
    else
        % 기존 값 업데이트
        AP.BSR(idx).Buffer_Status = buffer_status;
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