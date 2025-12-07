%% explore_results.m
% Results 구조체 탐색
% BSR trace 또는 대안 데이터 찾기

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  Results 구조체 탐색\n');
fprintf('========================================\n\n');

%% 결과 로드

load('bsr_trace_results.mat');

%% Baseline 구조 탐색

fprintf('========================================\n');
fprintf('  Baseline 결과 구조\n');
fprintf('========================================\n\n');

baseline_fields = fieldnames(results.baseline);
fprintf('총 %d개 필드:\n', length(baseline_fields));
for i = 1:length(baseline_fields)
    fprintf('  %2d. %s\n', i, baseline_fields{i});
end
fprintf('\n');

%% BSR 관련 필드 상세 확인

fprintf('========================================\n');
fprintf('  BSR 관련 필드 상세\n');
fprintf('========================================\n\n');

% BSR 필드 찾기
if isfield(results.baseline, 'bsr')
    fprintf('bsr 필드 발견!\n');
    bsr_subfields = fieldnames(results.baseline.bsr);
    fprintf('  bsr 하위 필드:\n');
    for i = 1:length(bsr_subfields)
        fprintf('    %s\n', bsr_subfields{i});
    end
    fprintf('\n');
    
    % 각 하위 필드 확인
    for i = 1:length(bsr_subfields)
        field = bsr_subfields{i};
        val = results.baseline.bsr.(field);
        
        fprintf('  bsr.%s:\n', field);
        if isstruct(val)
            fprintf('    [구조체: %d 필드]\n', length(fieldnames(val)));
            disp(fieldnames(val));
        elseif iscell(val)
            fprintf('    [셀 배열: %s]\n', mat2str(size(val)));
        elseif isnumeric(val)
            fprintf('    [숫자: %s, 값=%s]\n', mat2str(size(val)), mat2str(val));
        else
            fprintf('    [%s]\n', class(val));
        end
    end
    fprintf('\n');
end

%% Station 데이터 확인

fprintf('========================================\n');
fprintf('  Station 관련 데이터\n');
fprintf('========================================\n\n');

% Station 필드 찾기
station_fields = baseline_fields(contains(baseline_fields, 'sta', 'IgnoreCase', true));
if ~isempty(station_fields)
    fprintf('Station 관련 필드:\n');
    for i = 1:length(station_fields)
        fprintf('  %s\n', station_fields{i});
    end
    fprintf('\n');
end

%% Queue 데이터 확인

fprintf('========================================\n');
fprintf('  Queue 관련 데이터\n');
fprintf('========================================\n\n');

queue_fields = baseline_fields(contains(baseline_fields, 'queue', 'IgnoreCase', true));
if ~isempty(queue_fields)
    fprintf('Queue 관련 필드:\n');
    for i = 1:length(queue_fields)
        fprintf('  %s\n', queue_fields{i});
        
        % 구조 확인
        val = results.baseline.(queue_fields{i});
        if isstruct(val)
            fprintf('    [구조체]\n');
            disp(fieldnames(val));
        elseif iscell(val)
            fprintf('    [셀 배열: %s]\n', mat2str(size(val)));
        else
            fprintf('    [%s]\n', class(val));
        end
    end
    fprintf('\n');
end

%% Trace 관련 필드 찾기

fprintf('========================================\n');
fprintf('  Trace/History/Log 관련 데이터\n');
fprintf('========================================\n\n');

trace_keywords = {'trace', 'history', 'log', 'record'};
trace_fields = {};

for i = 1:length(baseline_fields)
    field = baseline_fields{i};
    for j = 1:length(trace_keywords)
        if contains(field, trace_keywords{j}, 'IgnoreCase', true)
            trace_fields{end+1} = field;
            break;
        end
    end
end

if ~isempty(trace_fields)
    fprintf('Trace 관련 필드:\n');
    for i = 1:length(trace_fields)
        fprintf('  %s\n', trace_fields{i});
        
        % 구조 확인
        val = results.baseline.(trace_fields{i});
        if isstruct(val)
            fprintf('    [구조체: %d 필드]\n', length(fieldnames(val)));
        elseif iscell(val)
            fprintf('    [셀 배열: %s]\n', mat2str(size(val)));
        elseif isnumeric(val) || islogical(val)
            fprintf('    [배열: %s]\n', mat2str(size(val)));
        else
            fprintf('    [%s]\n', class(val));
        end
    end
    fprintf('\n');
else
    fprintf('❌ Trace 관련 필드 없음\n\n');
end

%% 모든 필드 타입 요약

fprintf('========================================\n');
fprintf('  전체 필드 타입 요약\n');
fprintf('========================================\n\n');

for i = 1:length(baseline_fields)
    field = baseline_fields{i};
    val = results.baseline.(field);
    
    if isstruct(val)
        type_str = sprintf('struct (%d fields)', length(fieldnames(val)));
    elseif iscell(val)
        type_str = sprintf('cell %s', mat2str(size(val)));
    elseif isnumeric(val) || islogical(val)
        type_str = sprintf('%s %s', class(val), mat2str(size(val)));
    else
        type_str = class(val);
    end
    
    fprintf('  %-20s: %s\n', field, type_str);
end

fprintf('\n========================================\n\n');