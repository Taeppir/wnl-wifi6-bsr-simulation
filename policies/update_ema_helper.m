function ema_new = update_ema_helper(value, ema_old, alpha)
% UPDATE_EMA_HELPER: EMA(Exponential Moving Average) 업데이트
%
% 입력:
%   value   - 새로운 관측값
%   ema_old - 이전 EMA 값
%   alpha   - 평활 계수 (0 < alpha <= 1)
%
% 출력:
%   ema_new - 업데이트된 EMA 값
%
% 공식:
%   EMA(t) = α·X(t) + (1-α)·EMA(t-1)
%
% 특성:
%   - α가 클수록: 최근 값에 민감 (빠른 반응)
%   - α가 작을수록: 과거 값 유지 (느린 반응, 장기 추세)

    ema_new = alpha * value + (1 - alpha) * ema_old;
end