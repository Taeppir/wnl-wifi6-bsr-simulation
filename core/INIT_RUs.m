function RUs = INIT_RUs(RUs)
% INIT_RUs: RU 초기화 (다음 Stage 준비)
%
% 입력:
%   RUs - RU 구조체 배열
%
% 출력:
%   RUs - 초기화된 RU 구조체 배열

    for i = 1:length(RUs)
        RUs(i).accessedSTAs = [];
        RUs(i).assignedSTA = 0;
        RUs(i).collision = false;
    end
end