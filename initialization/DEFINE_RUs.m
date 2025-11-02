function RUs = DEFINE_RUs(numRU_total, numRU_RA)
% DEFINE_RUs: RU 구조체 배열 초기화
%
% 입력:
%   numRU_total - 총 RU 개수
%   numRU_RA    - RA-RU 개수
%
% 출력:
%   RUs - RU 구조체 배열
%
% RU 구성:
%   RU 1 ~ numRU_RA        : RA-RU (mode=0)
%   RU (numRU_RA+1) ~ end  : SA-RU (mode=1)

    RUs = struct();
    
    for i = 1:numRU_total
        RUs(i).ID = i;
        
        % RU 모드 결정
        if i <= numRU_RA
            RUs(i).mode = 0;  % RA-RU
        else
            RUs(i).mode = 1;  % SA-RU
        end
        
        % 접근 정보
        RUs(i).accessedSTAs = [];  % 이 RU에 접근한 단말 ID 목록
        RUs(i).collision = false;  % 충돌 여부
        
        % 할당 정보 (SA-RU만 사용)
        RUs(i).assignedSTA = 0;    % 할당된 단말 ID (0=없음)
    end
end