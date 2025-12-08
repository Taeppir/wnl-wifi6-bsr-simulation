function [R, STAs] = compute_bsr_v3_simple(STAs, sta_idx, Q_current, cfg)
% COMPUTE_BSR_V3_SIMPLE: 간소화된 EMA 기반 감소 정책
%
% 안전장치 제거 버전:
%   - burst_threshold 제거
%   - reduction_threshold 제거
%   - deviation 로직만 사용
%
% 파라미터 (3개만):
%   - v3_EMA_alpha
%   - v3_sensitivity
%   - v3_max_reduction

    % 상태 변수
    Q_ema = STAs(sta_idx).Q_ema;
    ema_initialized = STAs(sta_idx).ema_initialized;
    
    % 파라미터
    alpha = cfg.v3_EMA_alpha;
    sensitivity = cfg.v3_sensitivity;
    max_reduction = cfg.v3_max_reduction;
    
    %% EMA 초기화
    if ~ema_initialized
        Q_ema = Q_current;
        STAs(sta_idx).ema_initialized = true;
    end
    
    %% EMA 업데이트
    Q_ema_new = alpha * Q_current + (1 - alpha) * Q_ema;
    
    %% Deviation 계산
    deviation = Q_current - Q_ema_new;
    
    %% 감소 비율 계산 (간소화!)
    if deviation <= 0
        % 하락 추세 → 감소
        normalized_dev = abs(deviation) / max(Q_current, 1);
        reduction_ratio = sensitivity * normalized_dev;
        reduction_ratio = min(reduction_ratio, max_reduction);
    else
        % 상승 추세 → 감소 안 함
        reduction_ratio = 0;
    end
    
    %% BSR 계산
    R = Q_current * (1 - reduction_ratio);
    
    % 안전 체크
    R = max(0, R);
    R = min(R, Q_current);
    
    %% 상태 업데이트
    STAs(sta_idx).Q_prev = Q_current;
    STAs(sta_idx).Q_ema = Q_ema_new;
    
end