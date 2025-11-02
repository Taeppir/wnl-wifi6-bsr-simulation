function stats = compute_statistics(data)
% COMPUTE_STATISTICS: 데이터 통계 계산
%
% 입력:
%   data - 데이터 벡터
%
% 출력:
%   stats - 통계 구조체

    stats = struct();
    
    % NaN 제거
    data = data(~isnan(data));
    
    if isempty(data)
        stats.mean = NaN;
        stats.median = NaN;
        stats.std = NaN;
        stats.min = NaN;
        stats.max = NaN;
        stats.p50 = NaN;
        stats.p90 = NaN;
        stats.p95 = NaN;
        stats.p99 = NaN;
        stats.count = 0;
        return;
    end
    
    stats.mean = mean(data);
    stats.median = median(data);
    stats.std = std(data);
    stats.min = min(data);
    stats.max = max(data);
    
    stats.p50 = prctile(data, 50);
    stats.p90 = prctile(data, 90);
    stats.p95 = prctile(data, 95);
    stats.p99 = prctile(data, 99);
    
    stats.count = length(data);
end