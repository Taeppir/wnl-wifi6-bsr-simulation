function validate_traffic(STAs, cfg)
% VALIDATE_TRAFFIC: 생성된 트래픽 검증 및 통계 출력
%
% 입력:
%   STAs - 트래픽이 생성된 단말 구조체 배열
%   cfg  - 설정 구조체
%
% 기능:
%   - 패킷 수 통계
%   - 도착 시간 분포 확인
%   - 예상 부하와 비교

    numSTAs = length(STAs);
    
    fprintf('\n========================================\n');
    fprintf('  트래픽 검증\n');
    fprintf('========================================\n');
    
    %% =====================================================================
    %  1. 기본 통계
    %  =====================================================================
    
    % 단말별 패킷 수
    packets_per_sta = [STAs.num_of_packets];
    
    total_packets = sum(packets_per_sta);
    mean_packets = mean(packets_per_sta);
    std_packets = std(packets_per_sta);
    min_packets = min(packets_per_sta);
    max_packets = max(packets_per_sta);
    
    fprintf('\n[패킷 통계]\n');
    fprintf('  총 패킷: %d개\n', total_packets);
    fprintf('  단말당 평균: %.1f ± %.1f개\n', mean_packets, std_packets);
    fprintf('  범위: [%d, %d]\n', min_packets, max_packets);
    
    %% =====================================================================
    %  2. 도착 시간 검증
    %  =====================================================================
    
    fprintf('\n[도착 시간 검증]\n');
    
    all_arrivals = [];
    for i = 1:numSTAs
        if ~isempty(STAs(i).packet_list)
            arrivals = [STAs(i).packet_list.arrival_time];
            all_arrivals = [all_arrivals, arrivals]; %#ok<AGROW>
            
            % 시간 순서 확인
            if ~issorted(arrivals)
                warning('STA %d: 도착 시간이 정렬되지 않음', i);
            end
            
            % 범위 확인
            if any(arrivals < 0) || any(arrivals > cfg.simulation_time)
                warning('STA %d: 도착 시간 범위 벗어남', i);
            end
        end
    end
    
    if ~isempty(all_arrivals)
        fprintf('  첫 패킷: %.4f s\n', min(all_arrivals));
        fprintf('  마지막 패킷: %.4f s\n', max(all_arrivals));
        fprintf('  시간 범위: %.2f s\n', max(all_arrivals) - min(all_arrivals));
    end
    
    %% =====================================================================
    %  3. 부하 검증
    %  =====================================================================
    
    fprintf('\n[부하 검증]\n');
    
    % 실제 생성된 부하
    total_data = total_packets * cfg.size_MPDU * 8;  % bits
    actual_sim_time = cfg.simulation_time - cfg.warmup_time;  % ⭐ 측정 시간만
    generated_load_bps = total_data / cfg.simulation_time;  % ⭐ 전체 시간 기준
    generated_load_mbps = generated_load_bps / 1e6;
    
    % 네트워크 용량 (SA-RU만)
    total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
    capacity_mbps = total_capacity / 1e6;
    
    % 부하율
    load_ratio = generated_load_bps / total_capacity;
    
    fprintf('  생성된 부하: %.2f Mbps\n', generated_load_mbps);
    fprintf('  네트워크 용량: %.2f Mbps\n', capacity_mbps);
    fprintf('  부하율: %.2f%%\n', load_ratio * 100);
    fprintf('  목표 부하율: %.2f%%\n', cfg.L_cell * 100);
    
    % 오차 확인 (허용 범위 완화)
    load_error = abs(load_ratio - cfg.L_cell) / cfg.L_cell;
    
    if load_error < 0.15  % ⭐ 15% 오차 허용
        fprintf('  ✅ 부하 오차: %.1f%% (양호)\n', load_error * 100);
    elseif load_error < 0.30  % ⭐ 30% 오차 허용
        fprintf('  ⚠️  부하 오차: %.1f%% (허용 가능)\n', load_error * 100);
    else
        fprintf('  ❌ 부하 오차: %.1f%% (크게 벗어남)\n', load_error * 100);
        warning('Generated load deviates significantly from target');
    end
    
    % ⭐ Pareto On-Off의 burst 특성 설명
    fprintf('\n  참고: Pareto On-Off는 bursty 트래픽입니다.\n');
    fprintf('       시뮬레이션 시간이 짧으면 부하가 목표와 다를 수 있습니다.\n');
    fprintf('       긴 시뮬레이션(10초+)에서 부하율이 수렴합니다.\n');
    
    %% =====================================================================
    %  5. 경고 및 권장사항
    %  =====================================================================
    
    fprintf('\n[검증 결과]\n');
    
    % 패킷 없는 단말 확인
    empty_stas = sum(packets_per_sta == 0);
    if empty_stas > 0
        fprintf('  ⚠️  패킷 없는 단말: %d개\n', empty_stas);
    end
    
    % 과부하 경고
    if load_ratio > 0.95
        fprintf('  ⚠️  높은 부하율 (%.0f%%) - 시뮬레이션 시간 증가 권장\n', load_ratio * 100);
    end
    
    % 저부하 경고
    if load_ratio < 0.3
        fprintf('  ⚠️  낮은 부하율 (%.0f%%) - lambda 증가 권장\n', load_ratio * 100);
    end
    
    fprintf('========================================\n\n');
end