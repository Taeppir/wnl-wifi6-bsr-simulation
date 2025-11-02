function [R, STAs] = compute_bsr_policy(STAs, sta_idx, Q_current, cfg)
% COMPUTE_BSR_POLICY: BSR 정책 라우터
%
% 입력:
%   STAs      - 단말 구조체 배열
%   sta_idx   - 현재 단말 인덱스
%   Q_current - 현재 큐 크기 [bytes]
%   cfg       - 설정 구조체
%
% 출력:
%   R    - 보고할 BSR 값 [bytes]
%   STAs - 업데이트된 단말 구조체 (상태 변수 갱신)
%
% 정책 선택:
%   cfg.scheme_id에 따라 적절한 정책 함수 호출
%     0: Baseline (R = Q)
%     1: v1 고정 적응형
%     2: v2 비례 적응형
%     3: v3 EMA 추세 기반

    switch cfg.scheme_id
        case 0
            % Baseline: 감소 없음
            [R, STAs] = compute_bsr_baseline(STAs, sta_idx, Q_current, cfg);
            
        case 1
            % v1: 고정량 감소
            [R, STAs] = compute_bsr_v1(STAs, sta_idx, Q_current, cfg);
            
        case 2
            % v2: 비례 감소
            [R, STAs] = compute_bsr_v2(STAs, sta_idx, Q_current, cfg);
            
        case 3
            % v3: EMA 추세 기반 (핵심)
            [R, STAs] = compute_bsr_v3(STAs, sta_idx, Q_current, cfg);
            
        otherwise
            error('Unknown scheme_id: %d (must be 0, 1, 2, or 3)', cfg.scheme_id);
    end
    
    % 안전성 체크: R은 항상 0 이상
    R = max(0, R);
    
    % R은 Q를 초과할 수 없음 (conservative reporting)
    R = min(R, Q_current);
end