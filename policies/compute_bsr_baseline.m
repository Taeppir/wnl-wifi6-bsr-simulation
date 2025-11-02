function [R, STAs] = compute_bsr_baseline(STAs, sta_idx, Q_current, cfg)
% COMPUTE_BSR_BASELINE: Baseline 정책 (R = Q)
%
% 입력:
%   STAs      - 단말 구조체 배열
%   sta_idx   - 현재 단말 인덱스
%   Q_current - 현재 큐 크기 [bytes]
%   cfg       - 설정 구조체 (미사용)
%
% 출력:
%   R    - 보고할 BSR 값 [bytes]
%   STAs - 단말 구조체 (변경 없음)

    % 정직하게 보고
    R = Q_current;
    
    % 상태 업데이트 (baseline은 상태 없음)
    % 하지만 일관성을 위해 Q_prev는 업데이트
    STAs(sta_idx).Q_prev = Q_current;
end