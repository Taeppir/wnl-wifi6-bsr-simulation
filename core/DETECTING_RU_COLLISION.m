function RUs = DETECTING_RU_COLLISION(RUs, STAs)
% DETECTING_RU_COLLISION: RU 충돌 감지
%
% 입력:
%   RUs  - RU 구조체 배열
%   STAs - 단말 구조체 배열
%
% 출력:
%   RUs - 충돌 정보가 업데이트된 RU 구조체 배열

    for i = 1:length(STAs)
        % 각 STA가 접근한 RU ID
        accessed_RU_ID = STAs(i).accessed_RA_RU;
        
        % RU ID가 유효한 경우에만 처리
        if accessed_RU_ID > 0 && accessed_RU_ID <= length(RUs)
            % RU에 접근한 STA ID 추가 (중복 제거)
            RUs(accessed_RU_ID).accessedSTAs = ...
                unique([RUs(accessed_RU_ID).accessedSTAs, STAs(i).ID]);
            
            % 충돌 정보 업데이트 (2개 이상이면 충돌)
            RUs(accessed_RU_ID).collision = ...
                (length(RUs(accessed_RU_ID).accessedSTAs) > 1);
        end
    end
end