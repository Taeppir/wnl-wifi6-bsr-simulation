function AP = DEFINE_AP(num_STAs)
% DEFINE_AP: Access Point 구조체 초기화
%
% 입력:
%   num_STAs - 연결된 단말 수
%
% 출력:
%   AP - AP 구조체
%
% 필드:
%   - BSR: BSR 테이블 (구조체 배열)
%       - STA_ID: 단말 ID
%       - Buffer_Status: 버퍼 상태 [bytes]
%   - total_rx_data: 총 수신 데이터 [bytes]
%   - num_connected_STAs: 연결된 단말 수

    AP = struct();
    
    % BSR 테이블 (초기: 비어있음)
    AP.BSR = struct(...
        'STA_ID', num2cell(1:num_STAs)', ...
        'Buffer_Status', num2cell(nan(num_STAs, 1)));
    
    % 통계
    AP.total_rx_data = 0;
    AP.num_connected_STAs = num_STAs;
    
    % 메타데이터
    AP.created_at = datetime('now');
end