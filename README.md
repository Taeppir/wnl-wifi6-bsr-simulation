# WiFi 6 BSR Simulation Framework

IEEE 802.11ax (WiFi 6) Buffer Status Report (BSR) 정책 시뮬레이션 프레임워크

## 개요

이 프로젝트는 WiFi 6 업링크 전송에서 BSR 정책이 성능에 미치는 영향을 분석합니다.
다양한 BSR 감소 정책(v0~v3)을 비교하여 지연, 충돌률, 처리량 등을 평가합니다.

### BSR 정책

| 정책 | 설명 |
|------|------|
| v0 (Baseline) | R = Q (실제 큐 크기 그대로 보고) |
| v1 | Fixed Reduction (고정 감소량) |
| v2 | Proportional Reduction (비례 감소) |
| v3 | EMA-based (지수 이동 평균 기반) |

## 디렉토리 구조

```
├── core/                 # 시뮬레이션 엔진
├── config/               # 설정 파일
│   └── experiment_configs/  # 실험별 설정
├── initialization/       # 네트워크 엔티티 초기화
├── policies/             # BSR 정책 구현
├── metrics/              # 성능 메트릭 계산
├── traffic/              # 트래픽 생성 모델
├── utils/                # 유틸리티 함수
├── tests/                # 테스트 코드
├── experiments/          # 실험 실행 스크립트
│   ├── phase0/          # 베이스라인 특성화
│   ├── phase1/          # 부하 스윕 실험
│   └── phase2/          # 정책 최적화
├── analysis/             # 결과 분석
│   ├── scripts/         # 분석 스크립트
│   ├── notebooks/       # 탐색용 노트북
│   └── toolkit/         # 분석 헬퍼 함수
└── results/              # 결과 저장
```

## 시작하기

### 요구사항

- MATLAB R2020a 이상

### 실행 방법

1. **경로 설정**
```matlab
run('setup_paths.m')
```

2. **단일 시뮬레이션 실행**
```matlab
run('run_single_experiment.m')
```

3. **전체 정책 비교 실험**
```matlab
run('run_experiments.m')
```

### 실험 설정

`config/config_default.m`에서 기본 파라미터를 수정할 수 있습니다:

```matlab
cfg.num_STAs = 20;           % 단말 수
cfg.simulation_time = 10.0;  % 시뮬레이션 시간 (초)
cfg.scheme_id = 0;           % BSR 정책 (0~3)
cfg.L_cell = 0.30;           % 셀 부하
```

## 실험 단계

### Phase 1: 부하 스윕
- `exp1_01`: Unsaturated 환경 탐색
- `exp1_02`: 2D 파라미터 맵
- `exp1_03`: ON 기간 길이 영향

### Phase 2: 정책 최적화
- `exp2_01`: 정책 비교
- `exp2_02`: v3 Threshold 스윕
- `exp2_03`: v3 파라미터 최적화

## 분석

분석 스크립트는 `analysis/scripts/`에 있습니다:

```matlab
% 예: Exp 1-1 분석
run('analysis/scripts/analyze_exp1_01_unsaturated.m')
```

## 주요 메트릭

- **지연**: 평균, P90, P99 큐잉 지연
- **UORA**: 충돌률, 성공률
- **BSR**: Explicit/Implicit BSR 비율
- **처리량**: Mb/s
- **공평성**: Jain's Fairness Index
