function [STAs, AP] = DELETE_BSR_AND_MODE(STAs, AP, sta_idx)
% DELETE_BSR_AND_MODE: BSR 삭제 + mode 자동 동기화
%
% 입력:
%   STAs    - 단말 구조체 배열
%   AP      - AP 구조체
%   sta_idx - 단말 인덱스
%
% 출력:
%   STAs - mode가 업데이트된 단말 구조체
%   AP   - BSR 테이블에서 해당 단말이 삭제된 AP 구조체

    %% =====================================================================
    %  1. BSR 테이블에서 삭제
    %  =====================================================================
    
    if sta_idx > 0 && sta_idx <= length(AP.BSR)
        AP.BSR(sta_idx).Buffer_Status = NaN;
    else
         warning('DELETE_BSR_AND_MODE: 유효하지 않은 sta_idx(%d)입니다.', sta_idx);
    end
    
    %% =====================================================================
    %  2. Mode 자동 동기화
    %  =====================================================================
    
    STAs(sta_idx).mode = 0;  % RA 모드로 복귀
end