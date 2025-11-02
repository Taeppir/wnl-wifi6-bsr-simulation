function [R, STAs] = compute_bsr_v2(STAs, sta_idx, Q_current, cfg)
% COMPUTE_BSR_V2: 비례 적응형 감소 정책
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
%   1. 버스트 감지: ΔQ > threshold
%   2. 버스트 아니면: reduction_ratio = min(max_reduction, ΔQ / Q_prev)
%   3. R = Q * (1 - reduction_ratio)

    Q_prev = STAs(sta_idx).Q_prev;
    
    % 파라미터
    max_reduction = cfg.v2_max_reduction;  % 예: 0.7
    burst_threshold = cfg.burst_threshold;
    reduction_threshold = cfg.reduction_threshold;
    
    % 버스트 감지
    delta_Q = Q_current - Q_prev;
    is_burst = (delta_Q > burst_threshold);
    
    % 큐가 너무 작으면 감소 안 함
    is_small_queue = (Q_current < reduction_threshold);
    
    % 이전 큐가 0이면 비율 계산 불가
    if Q_prev < 1
        Q_prev = 1;  % 0으로 나누기 방지
    end
    
    % 감소 적용 여부 결정
    if is_burst || is_small_queue
        % 버스트 또는 작은 큐 → 감소 안 함
        R = Q_current;
    else
        % 비례 감소
        % 큐가 감소 추세면 → 낮게 보고
        % 큐가 증가 추세면 → 높게 보고
        
        if delta_Q <= 0
            % 큐가 감소 중 → "감소 비율" 계산
            % (Q_prev - Q_current) / Q_prev
            reduction_ratio = abs(delta_Q) / Q_prev; 
            reduction_ratio = min(reduction_ratio, max_reduction);
            
            R = Q_current * (1 - reduction_ratio);
        else
            % 큐가 증가 중 → 감산 안 함
            R = Q_current;
        end
    end
    
    % 상태 업데이트
    STAs(sta_idx).Q_prev = Q_current;
    
end