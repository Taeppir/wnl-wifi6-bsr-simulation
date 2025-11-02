function STAs = gen_onoff_pareto_v2(STAs, cfg)
% GEN_ONOFF_PARETO_V2: Pareto On-Off 트래픽 생성
%
% 입력:
%   STAs - 단말 구조체 배열
%   cfg  - 설정 구조체
%
% 출력:
%   STAs - 패킷이 생성된 단말 구조체 배열
%
% [수정]
%   - 메모리 최적화: `packet_list(end+1)` 동적 할당을 제거하고,
%     `cfg.max_packets_per_sta`를 기반으로 구조체를 사전 할당하여
%     MATLAB 비정상 종료 (Out-of-Memory) 문제 해결.

    numSTAs = length(STAs);
    
    % 파라미터 추출
    alpha = cfg.alpha;
    lambda = cfg.lambda;
    mu_on = cfg.mu_on;
    mu_off = cfg.mu_off;
    packet_size = cfg.size_MPDU;
    sim_time = cfg.simulation_time;
    
    % ⭐ [수정] 사전 할당을 위한 최대 패킷 수
    max_pkts_per_sta = cfg.max_packets_per_sta;
    
    % Pareto 분포 최소값 계산
    k_on = mu_on * (alpha - 1) / alpha;
    k_off = mu_off * (alpha - 1) / alpha;
    
    if cfg.verbose >= 2
        fprintf('[트래픽 생성]\n');
        fprintf('  모델: Pareto On-Off\n');
        fprintf('  Alpha: %.2f\n', alpha);
        fprintf('  Lambda (단말당): %.2f pkt/s\n', lambda);
        fprintf('  On 평균: %.3f s (k=%.4f)\n', mu_on, k_on);
        fprintf('  Off 평균: %.3f s (k=%.4f)\n', mu_off, k_off);
        fprintf('  사전 할당 크기 (STA당): %d packets\n', max_pkts_per_sta);
    end
    
    %% =====================================================================
    %  각 단말별 트래픽 생성
    %  =====================================================================
    
    for sta_idx = 1:numSTAs
        
        current_time = 0.0;
        packet_idx = 0; % 이제부터 생성된 패킷의 인덱스 카운터로 사용
        
        % ⭐ [수정] 빈 구조체 대신, 최대 크기로 사전 할당
        % (nan/cell을 사용하여 빈 구조체 배열을 효율적으로 생성)
        packet_list = struct(...
            'packet_idx', num2cell(nan(max_pkts_per_sta, 1)), ...
            'total_size', num2cell(nan(max_pkts_per_sta, 1)), ...
            'arrival_time', num2cell(nan(max_pkts_per_sta, 1)) ...
        );
        
        % On/Off 상태 초기화
        is_on_state = false;  % 초기: Off 상태
        
        while current_time < sim_time
            
            if is_on_state
                %% =========================================================
                %  On Period: 패킷 생성
                %  =========================================================
                
                on_duration = sample_pareto(k_on, alpha);
                on_end_time = current_time + on_duration;
                
                while current_time < on_end_time && current_time < sim_time
                    
                    inter_arrival = -log(rand()) / lambda;
                    arrival_time = current_time + inter_arrival;
                    
                    if arrival_time >= sim_time
                        break;
                    end
                    
                    if arrival_time < on_end_time
                        % 패킷 생성
                        packet_idx = packet_idx + 1;
                        
                        % ⭐ [수정] 사전 할당된 크기를 초과하는지 확인
                        if packet_idx > max_pkts_per_sta
                            warning('STA %d: 사전 할당된 최대 패킷 수(%d)를 초과했습니다. 트래픽 생성을 중단합니다.', ...
                                sta_idx, max_pkts_per_sta);
                            break; % On-period의 while 루프 중단
                        end
                        
                        % ⭐ [수정] `end+1` 대신 인덱스로 직접 할당
                        packet_list(packet_idx).packet_idx = packet_idx;
                        packet_list(packet_idx).total_size = packet_size;
                        packet_list(packet_idx).arrival_time = arrival_time;
                        
                        current_time = arrival_time;
                    else
                        break;
                    end
                end
                
                % ⭐ [수정] 사전 할당 크기 초과 시, 메인 while 루프도 중단
                if packet_idx > max_pkts_per_sta
                    break;
                end
                
                current_time = on_end_time;
                is_on_state = false;
                
            else
                %% =========================================================
                %  Off Period: 대기
                %  =========================================================
                
                off_duration = sample_pareto(k_off, alpha);
                current_time = current_time + off_duration;
                is_on_state = true;
            end
        end
        
        %% =================================================================
        %  생성된 패킷을 단말에 할당
        %  =================================================================
        
        % ⭐ [수정] 실제로 채워진 부분만 잘라서 할당 (1 ~ packet_idx)
        if packet_idx > 0
            STAs(sta_idx).packet_list = packet_list(1:packet_idx);
            STAs(sta_idx).num_of_packets = packet_idx;
        else
            % 패킷이 하나도 생성되지 않은 경우, 빈 구조체 할당
            STAs(sta_idx).packet_list = struct('packet_idx', {}, 'total_size', {}, 'arrival_time', {});
            STAs(sta_idx).num_of_packets = 0;
        end
        
        if cfg.verbose >= 3
            fprintf('  STA %2d: %4d 패킷 생성 (최대 %d)\n', sta_idx, packet_idx, max_pkts_per_sta);
        end
    end
    
    %% =====================================================================
    %  전체 통계
    %  =====================================================================
    
    total_packets = sum([STAs.num_of_packets]);
    
    if cfg.verbose >= 2
        fprintf('  총 생성 패킷: %d개\n', total_packets);
        fprintf('  단말당 평균: %.1f개\n', total_packets / numSTAs);
    end
end

%% =========================================================================
%  Helper Function: Pareto 샘플링 (변경 없음)
%  =========================================================================

function x = sample_pareto(k, alpha)
% SAMPLE_PARETO: Pareto 분포 샘플링
    u = rand();
    x = k / (u^(1/alpha));
end