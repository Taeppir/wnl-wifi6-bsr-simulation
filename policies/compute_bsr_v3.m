function [R, STAs] = compute_bsr_v3(STAs, sta_idx, Q_current, cfg)
% COMPUTE_BSR_V3: EMA 추세 기반 적응형 감소 정책 (핵심)
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
% 로직: (2025.11.03 수정)
%   1. EMA 업데이트: Q_ema(t) = α·Q(t) + (1-α)·Q_ema(t-1)
%   2. Deviation 계산: dev = Q(t) - Q_ema(t)
%   3. 공통 안전장치 (버스트/작은 큐) 확인
%   4. [수정] 하락 추세(dev <= 0)일 때만 감산 적용
%   5. [수정] 상승 추세(dev > 0)일 때는 R = Q (감산 없음)

    % 상태 변수 읽기
    Q_prev = STAs(sta_idx).Q_prev;
    Q_ema = STAs(sta_idx).Q_ema;
    ema_initialized = STAs(sta_idx).ema_initialized;
    
    % 파라미터
    alpha = cfg.v3_EMA_alpha;              % 예: 0.2 (작을수록 장기 추세)
    sensitivity = cfg.v3_sensitivity;      % 예: 1.0
    max_reduction = cfg.v3_max_reduction;  % 예: 0.7
    burst_threshold = cfg.burst_threshold;
    reduction_threshold = cfg.reduction_threshold;
    
    %% =====================================================================
    %  Step 1: EMA 초기화 (첫 호출 시)
    %  =====================================================================
    
    if ~ema_initialized
        % 첫 번째 값으로 초기화
        Q_ema = Q_current;
        STAs(sta_idx).ema_initialized = true;
    end
    
    %% =====================================================================
    %  Step 2: EMA 업데이트
    %  =====================================================================
    
    % EMA 공식: Q_ema(t) = α·Q(t) + (1-α)·Q_ema(t-1)
    Q_ema_new = alpha * Q_current + (1 - alpha) * Q_ema;
    
    %% =====================================================================
    %  Step 3: Deviation 계산
    %  =====================================================================
    
    % deviation = 실제 큐 - EMA
    % dev > 0: 큐가 평균보다 높음 (증가 추세 또는 버스트)
    % dev < 0: 큐가 평균보다 낮음 (감소 추세)
    deviation = Q_current - Q_ema_new;
    
    %% =====================================================================
    %  Step 4: 공통 안전장치 (버스트 및 작은 큐 보호)
    %  =====================================================================
    
    % 1. 버스트 감지 (급격한 증가)
    delta_Q = Q_current - Q_prev;
    is_burst = (delta_Q > burst_threshold);
    
    % 2. 큐가 너무 작으면 감소 안 함
    is_small_queue = (Q_current < reduction_threshold);
    
    %% =====================================================================
    %  Step 5: 감소 비율 계산 [핵심 수정]
    %  =====================================================================
    
    if is_burst || is_small_queue
        % [안전장치] 버스트 또는 작은 큐 → 감산 안 함 (R=Q)
        reduction_ratio = 0;
        
    else
        % [수정] 정책 로직: 설계안에 따라 하락 추세일 때만 감산
        
        if deviation <= 0
            % [수정] 큐가 하락 추세 (Q <= Q_ema) → 적극적으로 감소
            % (이전 코드의 'else' 블록 로직)
            
            % |deviation|이 클수록 더 많이 감소
            % (Q_current가 0에 가까울 때 분모가 0이 되는 것을 방지)
            normalized_dev = abs(deviation) / max(Q_current, 1);
            
            reduction_ratio = sensitivity * normalized_dev;
            
            % 상한 적용
            reduction_ratio = min(reduction_ratio, max_reduction);
            
        else
            % [수정] 큐가 상승 추세 (Q > Q_ema) → 감산 안 함 (R=Q)
            % (ON 구간 진입으로 판단)
            reduction_ratio = 0;
        end
    end
    
    %% =====================================================================
    %  Step 6: BSR 계산
    %  =====================================================================
    
    % reduction_ratio가 0이면 R = Q_current
    % reduction_ratio가 0보다 크면 R < Q_current
    R = Q_current * (1 - reduction_ratio);
    
    % 안전성 체크 (compute_bsr_policy.m에서도 수행하지만,
    % 여기서도 한 번 더 보장)
    R = max(0, R);
    R = min(R, Q_current);
    
    %% =====================================================================
    %  Step 7: 상태 업데이트
    %  =====================================================================
    
    STAs(sta_idx).Q_prev = Q_current;
    STAs(sta_idx).Q_ema = Q_ema_new;
    
end