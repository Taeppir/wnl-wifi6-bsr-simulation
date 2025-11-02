function accessed_RU = ACCESSING_RA_RU(numRUs)
% ACCESSING_RA_RU: 랜덤으로 RU 선택
%
% 입력:
%   numRUs - 선택 가능한 RU 개수
%
% 출력:
%   accessed_RU - 선택된 RU ID (1 ~ numRUs)

    accessed_RU = randi([1, numRUs]);
end