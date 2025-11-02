function [R, STAs] = compute_bsr_v1(STAs, sta_idx, Q_current, cfg)
% COMPUTE_BSR_V1: 고정 적응형 감소 정책
%
% 입력:
%   STAs      - 단말 구조체 배열
%   sta_idx   - 현재 단말 인덱스
%   Q_current - 현재 큐 크기 [bytes]
%   cfg       - 설정 구조체
%
% 출력:
%   R    - 보고할 BSR 값 [bytes]
%   STAs - 업데이트된 단말 구조체
%
% 로직:
%   1. 버스트 감지: ΔQ = Q - Q_prev > threshold
%   2. 버스트 아니면: R = max(0, Q - fixed_reduction)
%   3. 버스트면: R = Q (정직하게 보고)

    Q_prev = STAs(sta_idx).Q_prev;
    
    % 파라미터
    fixed_reduction = cfg.v1_fixed_reduction_bytes;
    burst_threshold = cfg.burst_threshold;
    reduction_threshold = cfg.reduction_threshold;
    
    % 버스트 감지
    delta_Q = Q_current - Q_prev;
    is_burst = (delta_Q > burst_threshold);
    
    % 큐가 너무 작으면 감소 안 함
    is_small_queue = (Q_current < reduction_threshold);
    
    % 감소 적용 여부 결정
    if is_burst || is_small_queue
        % 버스트 또는 작은 큐 → 감소 안 함
        R = Q_current;
    else
        % 고정량 감소
        R = max(0, Q_current - fixed_reduction);
    end
    
    % 상태 업데이트
    STAs(sta_idx).Q_prev = Q_current;
    
end