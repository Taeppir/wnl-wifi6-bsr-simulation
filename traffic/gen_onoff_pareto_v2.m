function STAs = gen_onoff_pareto_v2(STAs, cfg)
% GEN_ONOFF_PARETO_V2: Pareto On-Off 트래픽 생성
%
% 입력:
%   STAs - 단말 구조체 배열
%   cfg  - 설정 구조체
%
% 출력:
%   STAs - 패킷이 생성된 단말 구조체 배열

    numSTAs = length(STAs);
    
    % 파라미터 추출
    alpha = cfg.alpha;
    lambda = cfg.lambda;
    mu_on = cfg.mu_on;
    mu_off = cfg.mu_off;
    packet_size = cfg.size_MPDU;
    sim_time = cfg.simulation_time;
    
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
    end
    
    %% =====================================================================
    %  각 단말별 트래픽 생성
    %  =====================================================================
    
    for sta_idx = 1:numSTAs
        
        current_time = 0.0;
        packet_idx = 0;
        
        % 빈 구조체 배열로 초기화
        packet_list = struct('packet_idx', {}, 'total_size', {}, 'arrival_time', {});
        
        % On/Off 상태 초기화
        is_on_state = false;  % 초기: Off 상태
        
        while current_time < sim_time
            
            if is_on_state
                %% =========================================================
                %  On Period: 패킷 생성
                %  =========================================================
                
                % On period 지속 시간 샘플링
                on_duration = sample_pareto(k_on, alpha);
                on_end_time = current_time + on_duration;
                
                % On period 동안 패킷 생성
                while current_time < on_end_time && current_time < sim_time
                    
                    % 다음 패킷 도착 시간 (Poisson process)
                    inter_arrival = -log(rand()) / lambda;
                    arrival_time = current_time + inter_arrival;
                    
                    if arrival_time >= sim_time
                        break;
                    end
                    
                    if arrival_time < on_end_time
                        % 패킷 생성
                        packet_idx = packet_idx + 1;
                        
                        new_packet = struct();
                        new_packet.packet_idx = packet_idx;
                        new_packet.total_size = packet_size;
                        new_packet.arrival_time = arrival_time;
                        
                        % ⭐ 구조체 배열에 추가
                        if isempty(packet_list)
                            packet_list = new_packet;
                        else
                            packet_list(end+1) = new_packet; %#ok<AGROW>
                        end
                        
                        current_time = arrival_time;
                    else
                        break;
                    end
                end
                
                % On period 종료
                current_time = on_end_time;
                is_on_state = false;
                
            else
                %% =========================================================
                %  Off Period: 대기
                %  =========================================================
                
                % Off period 지속 시간 샘플링
                off_duration = sample_pareto(k_off, alpha);
                current_time = current_time + off_duration;
                
                % Off period 종료
                is_on_state = true;
            end
        end
        
        %% =================================================================
        %  생성된 패킷을 단말에 할당
        %  =================================================================
        
        STAs(sta_idx).packet_list = packet_list;
        STAs(sta_idx).num_of_packets = length(packet_list);
        
        if cfg.verbose >= 3
            fprintf('  STA %2d: %4d 패킷 생성\n', sta_idx, length(packet_list));
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
%  Helper Function: Pareto 샘플링
%  =========================================================================

function x = sample_pareto(k, alpha)
% SAMPLE_PARETO: Pareto 분포 샘플링
%
% 입력:
%   k     - 최소값 (scale parameter)
%   alpha - Shape parameter (> 1)
%
% 출력:
%   x - Pareto 분포 샘플

    u = rand();
    x = k / (u^(1/alpha));
end