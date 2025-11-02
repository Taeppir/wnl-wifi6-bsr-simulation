function visualize_traffic(STAs, cfg)
% VISUALIZE_TRAFFIC: 생성된 트래픽 시각화
%
% 입력:
%   STAs - 트래픽이 생성된 단말 구조체
%   cfg  - 설정 구조체

    figure('Position', [100, 100, 1200, 800]);
    
    %% Subplot 1: 도착 시간 (첫 5개 STA)
    subplot(2, 2, 1);
    hold on;
    colors = lines(5);
    
    for i = 1:min(5, length(STAs))
        if isempty(STAs(i).packet_list)
            continue;
        end
        arrivals = [STAs(i).packet_list.arrival_time];
        plot(arrivals, i * ones(size(arrivals)), 'o', ...
            'MarkerSize', 3, 'Color', colors(i, :));
    end
    
    xlabel('Time (s)');
    ylabel('STA ID');
    title('Packet Arrival Times (First 5 STAs)');
    ylim([0, 6]);
    grid on;
    
    %% Subplot 2: 패킷 수 분포
    subplot(2, 2, 2);
    packets_per_sta = [STAs.num_of_packets];
    histogram(packets_per_sta, 20);
    xlabel('Number of Packets');
    ylabel('Number of STAs');
    title(sprintf('Packet Distribution (Mean: %.1f)', mean(packets_per_sta)));
    grid on;
    
    %% Subplot 3: 누적 패킷 도착
    subplot(2, 2, 3);
    all_arrivals = [];
    for i = 1:length(STAs)
        if ~isempty(STAs(i).packet_list)
            all_arrivals = [all_arrivals, [STAs(i).packet_list.arrival_time]]; %#ok<AGROW>
        end
    end
    all_arrivals = sort(all_arrivals);
    
    plot(all_arrivals, 1:length(all_arrivals), 'b-', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Cumulative Packets');
    title('Cumulative Packet Arrivals');
    grid on;
    
    % 이론적 기울기 (λ_network)
    hold on;
    t_theory = linspace(0, cfg.simulation_time, 100);
    n_theory = cfg.lambda_network * t_theory;
    plot(t_theory, n_theory, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Theoretical');
    legend('Actual', 'Theoretical');
    
    %% Subplot 4: Inter-arrival time 분포 (첫 STA)
    subplot(2, 2, 4);
    if ~isempty(STAs(1).packet_list)
        arrivals = [STAs(1).packet_list.arrival_time];
        if length(arrivals) > 1
            inter_arrivals = diff(arrivals);
            histogram(inter_arrivals, 50);
            xlabel('Inter-arrival Time (s)');
            ylabel('Count');
            title('Inter-arrival Time Distribution (STA 1)');
            grid on;
        end
    end
    
    sgtitle(sprintf('Traffic Visualization (α=%.1f, ρ=%.2f, L_{cell}=%.2f)', ...
        cfg.alpha, cfg.rho, cfg.L_cell));
end