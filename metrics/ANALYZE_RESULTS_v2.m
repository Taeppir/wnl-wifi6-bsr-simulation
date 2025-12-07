% function results = ANALYZE_RESULTS_v2(STAs, AP, metrics, cfg)
% % ANALYZE_RESULTS_V2: 시뮬레이션 결과 집계 및 분석
% %
% % 입력:
% %   STAs    - 시뮬레이션 완료 후 단말 구조체 배열
% %   AP      - 시뮬레이션 완료 후 AP 구조체
% %   metrics - 메트릭 구조체 (init_metrics_struct)
% %   cfg     - 설정 구조체
% %
% % 출력:
% %   results - 결과 구조체 (계층적 구성)
% %
% % 결과 구조:
% %   - packet_level: 패킷 지연 통계
% %   - throughput: 처리율 분석
% %   - uora: UORA 효율성
% %   - bsr: BSR 통계 및 정확도
% %   - fairness: 단말별 공평성
% %   - summary: 핵심 메트릭 요약
% %
% % [v2.1] p10_delay_ms, UORA delay 분포 지표 추가

%     if cfg.verbose >= 1
%         fprintf('\n========================================\n');
%         fprintf('  결과 분석 시작\n');
%         fprintf('========================================\n\n');
%     end

%     results = struct();

%     %% =====================================================================
%     %  1. Packet-level 분석 (큐잉 지연)
%     %  =====================================================================

%     if cfg.verbose >= 2
%         fprintf('[1/6] 패킷 지연 분석...\n');
%     end

%     % 유효한 지연 샘플 추출
%     valid_idx = 1:metrics.packet_level.delay_idx;
%     queuing_delays = metrics.packet_level.queuing_delays(valid_idx);
%     queuing_delays = queuing_delays(~isnan(queuing_delays) & queuing_delays >= 0);

%     if ~isempty(queuing_delays)
%         results.packet_level = struct();
%         results.packet_level.mean_delay = mean(queuing_delays);
%         results.packet_level.median_delay = median(queuing_delays);
%         results.packet_level.std_delay = std(queuing_delays);
%         results.packet_level.min_delay = min(queuing_delays);
%         results.packet_level.max_delay = max(queuing_delays);

%         % 백분위수 (p10 추가)
%         results.packet_level.p10_delay = prctile(queuing_delays, 10);
%         results.packet_level.p50_delay = prctile(queuing_delays, 50);
%         results.packet_level.p90_delay = prctile(queuing_delays, 90);
%         results.packet_level.p95_delay = prctile(queuing_delays, 95);
%         results.packet_level.p99_delay = prctile(queuing_delays, 99);

%         % 지연 샘플 저장 (시각화용)
%         results.packet_level.delay_samples = queuing_delays;
%         results.packet_level.num_samples = length(queuing_delays);
%     else
%         % 지연 샘플 없음
%         results.packet_level = struct();
%         results.packet_level.mean_delay = NaN;
%         results.packet_level.median_delay = NaN;
%         results.packet_level.std_delay = NaN;
%         results.packet_level.min_delay = NaN;
%         results.packet_level.max_delay = NaN;
%         results.packet_level.p10_delay = NaN;
%         results.packet_level.p50_delay = NaN;
%         results.packet_level.p90_delay = NaN;
%         results.packet_level.p95_delay = NaN;
%         results.packet_level.p99_delay = NaN;
%         results.packet_level.delay_samples = [];
%         results.packet_level.num_samples = 0;

%         warning('No valid delay samples found');
%     end

%     % [개선] T_frag (단편화 지연) 집계
%     valid_frag_idx = 1:metrics.packet_level.frag_idx;
%     all_frag_delays = metrics.packet_level.frag_delays(valid_frag_idx);
%     all_frag_delays = all_frag_delays(~isnan(all_frag_delays) & all_frag_delays >= 0);

%     if ~isempty(all_frag_delays)
%         results.packet_level.mean_frag_delay = mean(all_frag_delays);
%         results.packet_level.num_fragmented = length(all_frag_delays);
%     else
%         results.packet_level.mean_frag_delay = 0;
%         results.packet_level.num_fragmented = 0;
%     end

%     %% =====================================================================
%     %  2. Throughput 분석
%     %  =====================================================================

%     if cfg.verbose >= 2
%         fprintf('[2/6] 처리율 분석...\n');
%     end

%     results.throughput = struct();

%     % 실제 시뮬레이션 시간 (워밍업 제외)
%     actual_sim_time = metrics.cumulative.simulation_end_time - cfg.warmup_time;

%     if actual_sim_time <= 0
%         actual_sim_time = cfg.simulation_time - cfg.warmup_time;
%     end

%     % 총 전송 데이터
%     results.throughput.total_tx_bytes = metrics.cumulative.total_tx_bytes;
%     results.throughput.total_tx_mb = metrics.cumulative.total_tx_bytes / 1e6;

%     % 평균 처리율 [Mb/s]
%     results.throughput.throughput_mbps = ...
%         (metrics.cumulative.total_tx_bytes * 8) / actual_sim_time / 1e6;

%     % 채널 용량 대비 이용률
%     total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;  % bits/sec
%     results.throughput.channel_utilization = ...
%         (metrics.cumulative.total_tx_bytes * 8) / actual_sim_time / total_capacity;

%     % AP 수신 데이터
%     results.throughput.ap_rx_bytes = AP.total_rx_data;

%     %% =====================================================================
%     %  3. UORA 효율성 분석
%     %  =====================================================================

%     if cfg.verbose >= 2
%         fprintf('[3/6] UORA 효율성 분석...\n');
%     end

%     results.uora = struct();

%     % 누적 통계
%     results.uora.total_attempts = metrics.cumulative.total_uora_attempts;
%     results.uora.total_collisions = metrics.cumulative.total_uora_collisions;
%     results.uora.total_success = metrics.cumulative.total_uora_success;

%     if isfield(metrics.cumulative, 'total_uora_idle')
%          results.uora.total_idle = metrics.cumulative.total_uora_idle;
%     else
%          results.uora.total_idle = 0;
%          warning('ANALYZE_RESULTS_v2: main_sim_v2.m에서 total_uora_idle 누적이 필요합니다.');
%     end

%     total_ru_opportunities = results.uora.total_success + ...
%                              results.uora.total_collisions + ...
%                              results.uora.total_idle;

%     % 비율 계산
%     if total_ru_opportunities > 0
%         results.uora.collision_rate = results.uora.total_collisions / total_ru_opportunities;
%         results.uora.success_rate = results.uora.total_success / total_ru_opportunities;
%         results.uora.idle_rate = results.uora.total_idle / total_ru_opportunities;
%     else
%         results.uora.collision_rate = 0;
%         results.uora.success_rate = 0;
%         results.uora.idle_rate = 0;
%     end


%     %% =====================================================================
%     %  4. BSR 통계 및 정확도 분석
%     %  =====================================================================

%     if cfg.verbose >= 2
%         fprintf('[4/6] BSR 통계 분석...\n');
%     end

%     results.bsr = struct();

%     % 시간 기반 buffer_empty_ratio 계산
%     total_empty_time = 0;
%     for i = 1:length(STAs)
%         % 시뮬레이션 종료 시점에 아직 비어있는 경우 처리
%         if STAs(i).is_buffer_currently_empty && STAs(i).buffer_empty_start_time > 0
%             final_empty_duration = metrics.cumulative.simulation_end_time - STAs(i).buffer_empty_start_time;
%             STAs(i).total_buffer_empty_time = STAs(i).total_buffer_empty_time + final_empty_duration;
%         end

%         total_empty_time = total_empty_time + STAs(i).total_buffer_empty_time;
%     end

%     % 실제 측정 시간 (워밍업 제외)
%     actual_sim_time = metrics.cumulative.simulation_end_time - cfg.warmup_time;
%     total_sim_time = cfg.num_STAs * actual_sim_time;

%     if total_sim_time > 0
%         results.bsr.buffer_empty_ratio = total_empty_time / total_sim_time;
%         results.bsr.buffer_empty_time_per_sta = total_empty_time / cfg.num_STAs;
%     else
%         results.bsr.buffer_empty_ratio = NaN;
%         results.bsr.buffer_empty_time_per_sta = NaN;
%     end

%     % Explicit vs Implicit BSR
%     results.bsr.total_explicit = metrics.cumulative.total_explicit_bsr;
%     results.bsr.total_implicit = metrics.cumulative.total_implicit_bsr;
%     results.bsr.total_bsr = results.bsr.total_explicit + results.bsr.total_implicit;

%     if results.bsr.total_bsr > 0
%         results.bsr.explicit_ratio = results.bsr.total_explicit / results.bsr.total_bsr;
%         results.bsr.implicit_ratio = results.bsr.total_implicit / results.bsr.total_bsr;
%     else
%         results.bsr.explicit_ratio = 0;
%         results.bsr.implicit_ratio = 0;
%     end

%     % 지연 분해 집계 (T_uora, T_sched, T_overhead)
%     total_decomp_samples = sum([STAs.delay_decomp_idx]);
%     all_uora_delays = nan(total_decomp_samples, 1);
%     all_sched_delays = nan(total_decomp_samples, 1);
%     all_overhead_delays = nan(total_decomp_samples, 1);
%     current_idx = 0;

%     for i = 1:length(STAs)
%         num_samples_sta = STAs(i).delay_decomp_idx;
%         if num_samples_sta > 0
%             % 1. 원본 데이터 (NaN 포함)
%             uora_raw = STAs(i).uora_delays(1:num_samples_sta);
%             sched_raw = STAs(i).sched_delays(1:num_samples_sta);
%             overhead_raw = STAs(i).overhead_delays(1:num_samples_sta);

%             % 2. T_uora를 기준으로 공통 마스크 생성
%             valid_mask = ~isnan(uora_raw) & uora_raw >= 0;
%             num_valid = sum(valid_mask);

%             if num_valid > 0
%                 % 3. 공통 마스크를 3개 벡터 모두에 적용
%                 all_uora_delays(current_idx + 1 : current_idx + num_valid) = uora_raw(valid_mask);
%                 all_sched_delays(current_idx + 1 : current_idx + num_valid) = sched_raw(valid_mask);
%                 all_overhead_delays(current_idx + 1 : current_idx + num_valid) = overhead_raw(valid_mask);

%                 current_idx = current_idx + num_valid;
%             end
%         end
%     end
%     all_uora_delays = all_uora_delays(1:current_idx);
%     all_sched_delays = all_sched_delays(1:current_idx);
%     all_overhead_delays = all_overhead_delays(1:current_idx);

%     % T_uora 통계 (분포 지표 포함)
%     if ~isempty(all_uora_delays)
%         results.bsr.mean_uora_delay = mean(all_uora_delays);
%         results.bsr.std_uora_delay = std(all_uora_delays);
%         results.bsr.median_uora_delay = median(all_uora_delays);
%         results.bsr.p10_uora_delay = prctile(all_uora_delays, 10);
%         results.bsr.p90_uora_delay = prctile(all_uora_delays, 90);
%         results.bsr.p99_uora_delay = prctile(all_uora_delays, 99);
%         results.bsr.num_uora_samples = length(all_uora_delays);
%     else
%         results.bsr.mean_uora_delay = NaN;
%         results.bsr.std_uora_delay = NaN;
%         results.bsr.median_uora_delay = NaN;
%         results.bsr.p10_uora_delay = NaN;
%         results.bsr.p90_uora_delay = NaN;
%         results.bsr.p99_uora_delay = NaN;
%         results.bsr.num_uora_samples = 0;
%     end

%     % T_sched 통계
%     if ~isempty(all_sched_delays)
%         results.bsr.mean_sched_delay = mean(all_sched_delays);
%         results.bsr.median_sched_delay = median(all_sched_delays);
%         results.bsr.p90_sched_delay = prctile(all_sched_delays, 90);
%         results.bsr.num_sched_samples = length(all_sched_delays);
%     else
%         results.bsr.mean_sched_delay = NaN;
%         results.bsr.median_sched_delay = NaN;
%         results.bsr.p90_sched_delay = NaN;
%         results.bsr.num_sched_samples = 0;
%     end

%     % T_overhead 통계
%     if ~isempty(all_overhead_delays)
%         results.bsr.mean_overhead_delay = mean(all_overhead_delays);
%         results.bsr.median_overhead_delay = median(all_overhead_delays);
%         results.bsr.p90_overhead_delay = prctile(all_overhead_delays, 90);
%         results.bsr.num_overhead_samples = length(all_overhead_delays);
%     else
%         results.bsr.mean_overhead_delay = NaN;
%         results.bsr.median_overhead_delay = NaN;
%         results.bsr.p90_overhead_delay = NaN;
%         results.bsr.num_overhead_samples = 0;
%     end

%     % BSR 대기 발생 패킷 비율
%     total_completed_pkts = metrics.cumulative.total_completed_pkts;
%     if total_completed_pkts > 0
%         results.bsr.bsr_affected_packet_ratio = results.bsr.num_uora_samples / total_completed_pkts;
%     else
%         results.bsr.bsr_affected_packet_ratio = NaN;
%     end


%     %% =====================================================================
%     %  5. Fairness 분석 (단말별)
%     %  =====================================================================

%     if cfg.verbose >= 2
%         fprintf('[5/6] 공평성 분석...\n');
%     end

%     results.fairness = struct();

%     % 단말별 처리율
%     throughput_per_sta = zeros(cfg.num_STAs, 1);
%     packets_per_sta = zeros(cfg.num_STAs, 1);

%     for i = 1:cfg.num_STAs
%         throughput_per_sta(i) = STAs(i).transmitted_data;

%         % 완료된 패킷 수
%         if isfield(STAs(i), 'tx_log_idx')
%             packets_per_sta(i) = STAs(i).tx_log_idx;
%         end
%     end

%     results.fairness.throughput_per_sta = throughput_per_sta;
%     results.fairness.packets_per_sta = packets_per_sta;

%     % Jain's Fairness Index
%     % J = (Σx_i)^2 / (n * Σx_i^2)
%     if sum(throughput_per_sta) > 0
%         results.fairness.jain_index = ...
%             (sum(throughput_per_sta))^2 / ...
%             (cfg.num_STAs * sum(throughput_per_sta.^2));
%     else
%         results.fairness.jain_index = NaN;
%     end

%     % 단말별 평균 지연
%     mean_delays_per_sta = zeros(cfg.num_STAs, 1);

%     for i = 1:cfg.num_STAs
%         valid_delays = STAs(i).packet_queuing_delays(1:STAs(i).delay_idx);
%         valid_delays = valid_delays(~isnan(valid_delays) & valid_delays >= 0);

%         if ~isempty(valid_delays)
%             mean_delays_per_sta(i) = mean(valid_delays);
%         else
%             mean_delays_per_sta(i) = NaN;
%         end
%     end

%     results.fairness.mean_delay_per_sta = mean_delays_per_sta;

%     % 지연 공평성
%     valid_mean_delays = mean_delays_per_sta(~isnan(mean_delays_per_sta));
%     if ~isempty(valid_mean_delays) && length(valid_mean_delays) > 1
%         results.fairness.delay_std = std(valid_mean_delays);
%         results.fairness.delay_cv = std(valid_mean_delays) / mean(valid_mean_delays);  % Coefficient of Variation
%     else
%         results.fairness.delay_std = NaN;
%         results.fairness.delay_cv = NaN;
%     end

%     %% =====================================================================
%     %  6. 패킷 통계
%     %  =====================================================================

%     if cfg.verbose >= 2
%         fprintf('[6/6] 패킷 통계 집계...\n');
%     end

%     % 생성된 패킷 수
%     total_generated = sum([STAs.num_of_packets]);

%     % 완료된 패킷 수
%     total_completed = metrics.cumulative.total_completed_pkts;

%     % 완료율
%     if total_generated > 0
%         completion_rate = total_completed / total_generated;
%     else
%         completion_rate = 0;
%     end

%     results.total_generated_packets = total_generated;
%     results.total_completed_packets = total_completed;
%     results.packet_completion_rate = completion_rate;

%     % 분할 전송 패킷 수
%     results.total_segmented_packets = results.packet_level.num_fragmented;
%     if total_completed > 0
%         results.segmentation_rate = results.total_segmented_packets / total_completed;
%     else
%         results.segmentation_rate = 0;
%     end

%     %% =====================================================================
%     %  7. 요약 (주요 메트릭)
%     %  =====================================================================

%     results.summary = struct();

%     % 지연 (ms 단위)
%     results.summary.mean_delay_ms = results.packet_level.mean_delay * 1000;
%     results.summary.std_delay_ms = results.packet_level.std_delay * 1000;
%     results.summary.p10_delay_ms = results.packet_level.p10_delay * 1000;
%     results.summary.p50_delay_ms = results.packet_level.p50_delay * 1000;
%     results.summary.p90_delay_ms = results.packet_level.p90_delay * 1000;
%     results.summary.p99_delay_ms = results.packet_level.p99_delay * 1000;

%     % 처리율
%     results.summary.throughput_mbps = results.throughput.throughput_mbps;
%     results.summary.channel_utilization = results.throughput.channel_utilization;

%     % UORA
%     results.summary.collision_rate = results.uora.collision_rate;
%     results.summary.success_rate = results.uora.success_rate;

%     % BSR
%     results.summary.implicit_bsr_ratio = results.bsr.implicit_ratio;
%     results.summary.explicit_bsr_count = results.bsr.total_explicit;
%     results.summary.implicit_bsr_count = results.bsr.total_implicit;
%     results.summary.total_bsr_count = results.bsr.total_bsr;
%     if isfield(results.bsr, 'buffer_empty_ratio')
%         results.summary.buffer_empty_ratio = results.bsr.buffer_empty_ratio;
%     else
%         results.summary.buffer_empty_ratio = NaN;
%     end

%     % 지연 분해 요약 (ms 단위)
%     results.summary.mean_uora_delay_ms = results.bsr.mean_uora_delay * 1000;
%     results.summary.std_uora_delay_ms = results.bsr.std_uora_delay * 1000;
%     results.summary.p10_uora_delay_ms = results.bsr.p10_uora_delay * 1000;
%     results.summary.p90_uora_delay_ms = results.bsr.p90_uora_delay * 1000;
%     results.summary.p99_uora_delay_ms = results.bsr.p99_uora_delay * 1000;

%     results.summary.mean_sched_delay_ms = results.bsr.mean_sched_delay * 1000;
%     results.summary.mean_frag_delay_ms = results.packet_level.mean_frag_delay * 1000;
%     results.summary.mean_overhead_delay_ms = results.bsr.mean_overhead_delay * 1000;

%     % 공평성
%     results.summary.jain_index = results.fairness.jain_index;

%     % 완료율
%     results.summary.completion_rate = completion_rate;

%     %% =====================================================================
%     %  8. 메타데이터
%     %  =====================================================================

%     results.metadata = struct();
%     results.metadata.scheme_id = cfg.scheme_id;
%     results.metadata.scheme_name = get_scheme_name(cfg.scheme_id);
%     results.metadata.num_STAs = cfg.num_STAs;
%     results.metadata.num_RUs = cfg.numRU_SA;
%     results.metadata.simulation_time = cfg.simulation_time;
%     results.metadata.warmup_time = cfg.warmup_time;
%     results.metadata.L_cell = cfg.L_cell;
%     results.metadata.rho = cfg.rho;
%     results.metadata.alpha = cfg.alpha;

%     %% =====================================================================
%     %  9. 경고 및 검증
%     %  =====================================================================

%     % 완료율 확인
%     completion_rate = results.packet_completion_rate;

%     if completion_rate < 0.5
%         warning('Packet completion rate < 50%% (%.1f%%). Network may be overloaded.', ...
%             completion_rate * 100);
%     elseif completion_rate < 0.8
%         if cfg.verbose >= 1
%             fprintf('  완료율: %.1f%% (시뮬레이션 시간 증가 권장)\n', completion_rate * 100);
%         end
%     end

%     if cfg.simulation_time < 5.0 && completion_rate < 0.9
%         if cfg.verbose >= 1
%             fprintf('  팁: 시뮬레이션 시간을 10초 이상으로 늘리면\n');
%             fprintf('       완료율과 통계의 정확도가 향상됩니다.\n');
%         end
%     end
% end

% %% =========================================================================
% %  Helper Functions
% %  =========================================================================

% function name = get_scheme_name(scheme_id)
% % GET_SCHEME_NAME: scheme_id를 이름으로 변환

%     switch scheme_id
%         case 0
%             name = 'Baseline (R=Q)';
%         case 1
%             name = 'v1 (Fixed Reduction)';
%         case 2
%             name = 'v2 (Proportional Reduction)';
%         case 3
%             name = 'v3 (EMA-based)';
%         otherwise
%             name = sprintf('Unknown (%d)', scheme_id);
%     end
% end

function results = ANALYZE_RESULTS_v2(STAs, AP, metrics, cfg)
% ANALYZE_RESULTS_V2: 시뮬레이션 결과 집계 및 분석 (FIXED)
%
% 수정 내역:
%   [FIX 1] Buffer Empty Ratio 계산 수정 (warmup 제외)
%   [FIX 2] BSR Count 추가 (ratio + count 모두 제공)
%
% 입력:
%   STAs    - 시뮬레이션 완료 후 단말 구조체 배열
%   AP      - 시뮬레이션 완료 후 AP 구조체
%   metrics - 메트릭 구조체 (init_metrics_struct)
%   cfg     - 설정 구조체
%
% 출력:
%   results - 결과 구조체 (계층적 구성)

    if cfg.verbose >= 1
        fprintf('\n========================================\n');
        fprintf('  결과 분석 시작 (FIXED)\n');
        fprintf('========================================\n\n');
    end

    results = struct();

    %% =====================================================================
    %  1. Packet-level 분석 (큐잉 지연)
    %  =====================================================================

    if cfg.verbose >= 2
        fprintf('[1/6] 패킷 지연 분석...\n');
    end

    % 유효한 지연 샘플 추출
    valid_idx = 1:metrics.packet_level.delay_idx;
    queuing_delays = metrics.packet_level.queuing_delays(valid_idx);
    queuing_delays = queuing_delays(~isnan(queuing_delays) & queuing_delays >= 0);

    if ~isempty(queuing_delays)
        results.packet_level = struct();
        results.packet_level.mean_delay = mean(queuing_delays);
        results.packet_level.median_delay = median(queuing_delays);
        results.packet_level.std_delay = std(queuing_delays);
        results.packet_level.min_delay = min(queuing_delays);
        results.packet_level.max_delay = max(queuing_delays);

        % 백분위수 (p10 추가)
        results.packet_level.p10_delay = prctile(queuing_delays, 10);
        results.packet_level.p50_delay = prctile(queuing_delays, 50);
        results.packet_level.p90_delay = prctile(queuing_delays, 90);
        results.packet_level.p95_delay = prctile(queuing_delays, 95);
        results.packet_level.p99_delay = prctile(queuing_delays, 99);

        % 지연 샘플 저장 (시각화용)
        results.packet_level.delay_samples = queuing_delays;
        results.packet_level.num_samples = length(queuing_delays);
    else
        % 지연 샘플 없음
        results.packet_level = struct();
        results.packet_level.mean_delay = NaN;
        results.packet_level.median_delay = NaN;
        results.packet_level.std_delay = NaN;
        results.packet_level.min_delay = NaN;
        results.packet_level.max_delay = NaN;
        results.packet_level.p10_delay = NaN;
        results.packet_level.p50_delay = NaN;
        results.packet_level.p90_delay = NaN;
        results.packet_level.p95_delay = NaN;
        results.packet_level.p99_delay = NaN;
        results.packet_level.delay_samples = [];
        results.packet_level.num_samples = 0;

        warning('No valid delay samples found');
    end

    % [개선] T_frag (단편화 지연) 집계
    valid_frag_idx = 1:metrics.packet_level.frag_idx;
    all_frag_delays = metrics.packet_level.frag_delays(valid_frag_idx);
    all_frag_delays = all_frag_delays(~isnan(all_frag_delays) & all_frag_delays >= 0);

    if ~isempty(all_frag_delays)
        results.packet_level.mean_frag_delay = mean(all_frag_delays);
        results.packet_level.num_fragmented = length(all_frag_delays);
    else
        results.packet_level.mean_frag_delay = 0;
        results.packet_level.num_fragmented = 0;
    end

    %% =====================================================================
    %  2. Throughput 분석
    %  =====================================================================

    if cfg.verbose >= 2
        fprintf('[2/6] 처리율 분석...\n');
    end

    results.throughput = struct();

    % 총 전송 데이터 (warmup 제외는 metrics에서 이미 처리됨)
    total_tx_bytes = metrics.cumulative.total_tx_bytes;
    results.throughput.total_tx_bytes = total_tx_bytes;
    results.throughput.total_tx_mb = total_tx_bytes / (1024^2);

    % 처리율 계산 (실제 측정 시간 기준)
    actual_sim_time = metrics.cumulative.simulation_end_time - cfg.warmup_time;

    if actual_sim_time > 0
        throughput_bps = (total_tx_bytes * 8) / actual_sim_time;
        results.throughput.throughput_bps = throughput_bps;
        results.throughput.throughput_mbps = throughput_bps / 1e6;

        % 채널 이용률 (전체 용량 대비)
        total_capacity = cfg.numRU_total * cfg.data_rate_per_RU;
        results.throughput.channel_utilization = throughput_bps / total_capacity;
    else
        results.throughput.throughput_bps = NaN;
        results.throughput.throughput_mbps = NaN;
        results.throughput.channel_utilization = NaN;
    end

    %% =====================================================================
    %  3. UORA 효율성 분석
    %  =====================================================================

    if cfg.verbose >= 2
        fprintf('[3/6] UORA 효율성 분석...\n');
    end

    results.uora = struct();

    total_attempts = metrics.cumulative.total_uora_attempts;
    total_success = metrics.cumulative.total_uora_success;
    total_collision = metrics.cumulative.total_uora_collisions;
    total_idle = metrics.cumulative.total_uora_idle;

    results.uora.total_attempts = total_attempts;
    results.uora.total_success = total_success;
    results.uora.total_collision = total_collision;
    results.uora.total_idle = total_idle;

    if total_attempts > 0
        results.uora.collision_rate = total_collision / total_attempts;
        results.uora.success_rate = total_success / total_attempts;
    else
        results.uora.collision_rate = 0;
        results.uora.success_rate = 0;
    end

    %% =====================================================================
    %  4. BSR 통계 분석 (FIXED: Count + Ratio)
    %  =====================================================================

    if cfg.verbose >= 2
        fprintf('[4/6] BSR 통계 분석...\n');
    end

    results.bsr = struct();

    %% ─────────────────────────────────────────────────────────────────────
    %  [FIX 1] Buffer Empty Ratio 계산 수정
    %  ─────────────────────────────────────────────────────────────────────
    
    % ⭐ Warmup 이후부터만 측정하도록 수정
    warmup_time = cfg.warmup_time;
    total_empty_time = 0;
    
    for i = 1:length(STAs)
        % 시뮬레이션 종료 시점에 아직 비어있는 경우 처리
        if STAs(i).is_buffer_currently_empty && STAs(i).buffer_empty_start_time > 0
            final_empty_duration = metrics.cumulative.simulation_end_time - STAs(i).buffer_empty_start_time;
            STAs(i).total_buffer_empty_time = STAs(i).total_buffer_empty_time + final_empty_duration;
        end

        % ⭐ Warmup 시간 제외 처리
        % 만약 buffer_empty_start_time이 warmup 이전이면, warmup 이후부터만 계산
        sta_empty_time = STAs(i).total_buffer_empty_time;
        
        % Warmup 기간에 발생한 empty time 제거 (근사)
        % 초기에 비어있었고, 첫 패킷 도착이 warmup 이후라면...
        % 이 부분은 정확한 계산을 위해 별도 로직 필요
        % 현재는 total_empty_time을 그대로 사용하되, 분모를 조정
        
        total_empty_time = total_empty_time + sta_empty_time;
    end

    % 실제 측정 시간 (워밍업 제외)
    actual_sim_time = metrics.cumulative.simulation_end_time - cfg.warmup_time;
    total_sim_time = cfg.num_STAs * actual_sim_time;

    if total_sim_time > 0
        % ⭐ 수정: warmup 동안의 empty time 비율 추정 및 제거
        % 근사: warmup / total_sim 비율만큼 빼기
        warmup_ratio = warmup_time / metrics.cumulative.simulation_end_time;
        estimated_warmup_empty = total_empty_time * warmup_ratio;
        
        corrected_empty_time = max(0, total_empty_time - estimated_warmup_empty);
        
        results.bsr.buffer_empty_ratio = corrected_empty_time / total_sim_time;
        results.bsr.buffer_empty_time_per_sta = corrected_empty_time / cfg.num_STAs;
        
        % 디버깅용
        results.bsr.total_empty_time_raw = total_empty_time;
        results.bsr.estimated_warmup_empty = estimated_warmup_empty;
        results.bsr.corrected_empty_time = corrected_empty_time;
    else
        results.bsr.buffer_empty_ratio = NaN;
        results.bsr.buffer_empty_time_per_sta = NaN;
    end

    %% ─────────────────────────────────────────────────────────────────────
    %  [FIX 2] BSR Count 추가 (Ratio + Count)
    %  ─────────────────────────────────────────────────────────────────────
    
    % BSR Count (절대 횟수)
    results.bsr.total_explicit = metrics.cumulative.total_explicit_bsr;
    results.bsr.total_implicit = metrics.cumulative.total_implicit_bsr;
    results.bsr.total_bsr = results.bsr.total_explicit + results.bsr.total_implicit;

    % BSR Ratio (비율)
    if results.bsr.total_bsr > 0
        results.bsr.explicit_ratio = results.bsr.total_explicit / results.bsr.total_bsr;
        results.bsr.implicit_ratio = results.bsr.total_implicit / results.bsr.total_bsr;
    else
        results.bsr.explicit_ratio = 0;
        results.bsr.implicit_ratio = 0;
    end

    % 지연 분해 집계 (T_uora, T_sched, T_overhead)
    total_decomp_samples = sum([STAs.delay_decomp_idx]);
    all_uora_delays = nan(total_decomp_samples, 1);
    all_sched_delays = nan(total_decomp_samples, 1);
    all_overhead_delays = nan(total_decomp_samples, 1);
    current_idx = 0;

    for i = 1:length(STAs)
        num_samples_sta = STAs(i).delay_decomp_idx;
        if num_samples_sta > 0
            % 1. 원본 데이터 (NaN 포함)
            uora_raw = STAs(i).uora_delays(1:num_samples_sta);
            sched_raw = STAs(i).sched_delays(1:num_samples_sta);
            overhead_raw = STAs(i).overhead_delays(1:num_samples_sta);

            % 2. T_uora를 기준으로 공통 마스크 생성
            valid_mask = ~isnan(uora_raw) & uora_raw >= 0;
            num_valid = sum(valid_mask);

            if num_valid > 0
                % 3. 공통 마스크를 3개 벡터 모두에 적용
                all_uora_delays(current_idx + 1 : current_idx + num_valid) = uora_raw(valid_mask);
                all_sched_delays(current_idx + 1 : current_idx + num_valid) = sched_raw(valid_mask);
                all_overhead_delays(current_idx + 1 : current_idx + num_valid) = overhead_raw(valid_mask);

                current_idx = current_idx + num_valid;
            end
        end
    end
    all_uora_delays = all_uora_delays(1:current_idx);
    all_sched_delays = all_sched_delays(1:current_idx);
    all_overhead_delays = all_overhead_delays(1:current_idx);

    % T_uora 통계 (분포 지표 포함)
    if ~isempty(all_uora_delays)
        results.bsr.mean_uora_delay = mean(all_uora_delays);
        results.bsr.std_uora_delay = std(all_uora_delays);
        results.bsr.median_uora_delay = median(all_uora_delays);
        results.bsr.p10_uora_delay = prctile(all_uora_delays, 10);
        results.bsr.p90_uora_delay = prctile(all_uora_delays, 90);
        results.bsr.p99_uora_delay = prctile(all_uora_delays, 99);
        results.bsr.num_uora_samples = length(all_uora_delays);
    else
        results.bsr.mean_uora_delay = NaN;
        results.bsr.std_uora_delay = NaN;
        results.bsr.median_uora_delay = NaN;
        results.bsr.p10_uora_delay = NaN;
        results.bsr.p90_uora_delay = NaN;
        results.bsr.p99_uora_delay = NaN;
        results.bsr.num_uora_samples = 0;
    end

    % T_sched 통계
    if ~isempty(all_sched_delays)
        results.bsr.mean_sched_delay = mean(all_sched_delays);
        results.bsr.median_sched_delay = median(all_sched_delays);
        results.bsr.p90_sched_delay = prctile(all_sched_delays, 90);
        results.bsr.num_sched_samples = length(all_sched_delays);
    else
        results.bsr.mean_sched_delay = NaN;
        results.bsr.median_sched_delay = NaN;
        results.bsr.p90_sched_delay = NaN;
        results.bsr.num_sched_samples = 0;
    end

    % T_overhead 통계
    if ~isempty(all_overhead_delays)
        results.bsr.mean_overhead_delay = mean(all_overhead_delays);
        results.bsr.median_overhead_delay = median(all_overhead_delays);
        results.bsr.p90_overhead_delay = prctile(all_overhead_delays, 90);
        results.bsr.num_overhead_samples = length(all_overhead_delays);
    else
        results.bsr.mean_overhead_delay = NaN;
        results.bsr.median_overhead_delay = NaN;
        results.bsr.p90_overhead_delay = NaN;
        results.bsr.num_overhead_samples = 0;
    end

    % BSR 대기 발생 패킷 비율
    total_completed_pkts = metrics.cumulative.total_completed_pkts;
    if total_completed_pkts > 0
        results.bsr.bsr_affected_packet_ratio = results.bsr.num_uora_samples / total_completed_pkts;
    else
        results.bsr.bsr_affected_packet_ratio = NaN;
    end


    %% =====================================================================
    %  5. Fairness 분석 (단말별)
    %  =====================================================================

    if cfg.verbose >= 2
        fprintf('[5/6] 공평성 분석...\n');
    end

    results.fairness = struct();

    % 단말별 처리율
    throughput_per_sta = zeros(cfg.num_STAs, 1);
    packets_per_sta = zeros(cfg.num_STAs, 1);

    for i = 1:cfg.num_STAs
        throughput_per_sta(i) = STAs(i).transmitted_data;

        % 완료된 패킷 수
        if isfield(STAs(i), 'tx_log_idx')
            packets_per_sta(i) = STAs(i).tx_log_idx;
        end
    end

    results.fairness.throughput_per_sta = throughput_per_sta;
    results.fairness.packets_per_sta = packets_per_sta;

    % Jain's Fairness Index
    if sum(throughput_per_sta) > 0
        results.fairness.jain_index = ...
            (sum(throughput_per_sta))^2 / ...
            (cfg.num_STAs * sum(throughput_per_sta.^2));
    else
        results.fairness.jain_index = NaN;
    end

    % 단말별 평균 지연
    mean_delays_per_sta = zeros(cfg.num_STAs, 1);

    for i = 1:cfg.num_STAs
        valid_delays = STAs(i).packet_queuing_delays(1:STAs(i).delay_idx);
        valid_delays = valid_delays(~isnan(valid_delays) & valid_delays >= 0);

        if ~isempty(valid_delays)
            mean_delays_per_sta(i) = mean(valid_delays);
        else
            mean_delays_per_sta(i) = NaN;
        end
    end

    results.fairness.mean_delay_per_sta = mean_delays_per_sta;

    %% =====================================================================
    %  6. Summary 통합 (핵심 메트릭)
    %  =====================================================================

    if cfg.verbose >= 2
        fprintf('[6/6] 통합 요약...\n');
    end

    results.summary = struct();

    % 지연
    results.summary.mean_delay_ms = results.packet_level.mean_delay * 1000;
    results.summary.p10_delay_ms = results.packet_level.p10_delay * 1000;
    results.summary.p90_delay_ms = results.packet_level.p90_delay * 1000;
    results.summary.p99_delay_ms = results.packet_level.p99_delay * 1000;

    % 처리율
    results.summary.throughput_mbps = results.throughput.throughput_mbps;
    results.summary.channel_utilization = results.throughput.channel_utilization;

    % UORA
    results.summary.collision_rate = results.uora.collision_rate;
    results.summary.success_rate = results.uora.success_rate;

    % BSR
    results.summary.explicit_bsr_ratio = results.bsr.explicit_ratio;
    results.summary.implicit_bsr_ratio = results.bsr.implicit_ratio;
    
    % ⭐ BSR Count 추가
    results.summary.explicit_bsr_count = results.bsr.total_explicit;
    results.summary.implicit_bsr_count = results.bsr.total_implicit;
    results.summary.total_bsr_count = results.bsr.total_bsr;

    if isfield(results.bsr, 'buffer_empty_ratio')
        results.summary.buffer_empty_ratio = results.bsr.buffer_empty_ratio;
    else
        results.summary.buffer_empty_ratio = NaN;
    end

    % 공평성
    results.summary.jain_index = results.fairness.jain_index;

    % 패킷 통계
    results.total_generated_packets = sum([STAs.num_of_packets]);
    results.total_completed_packets = metrics.cumulative.total_completed_pkts;

    if results.total_generated_packets > 0
        results.packet_completion_rate = ...
            results.total_completed_packets / results.total_generated_packets;
    else
        results.packet_completion_rate = NaN;
    end

    results.summary.completion_rate = results.packet_completion_rate;

    if cfg.verbose >= 1
        fprintf('\n========================================\n');
        fprintf('  결과 분석 완료 (FIXED)\n');
        fprintf('========================================\n\n');
        
        fprintf('⭐ BSR Count:\n');
        fprintf('  Explicit: %d회\n', results.bsr.total_explicit);
        fprintf('  Implicit: %d회\n', results.bsr.total_implicit);
        fprintf('  Total: %d회\n\n', results.bsr.total_bsr);
        
        fprintf('⭐ Buffer Empty (수정됨):\n');
        fprintf('  Raw: %.1f%%\n', results.bsr.total_empty_time_raw / total_sim_time * 100);
        fprintf('  Corrected: %.1f%%\n', results.bsr.buffer_empty_ratio * 100);
    end
end