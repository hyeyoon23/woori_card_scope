<img width="901" height="302" alt="woori-card-scope drawio (1)" src="https://github.com/user-attachments/assets/5a7be9ed-ca9c-4df5-ae02-b77a84d1b94f" />

# 데이터베이스 설계

## **1. InnoDB Cluster 구성**

본 프로젝트는 **MySQL InnoDB Cluster** 기반으로 데이터베이스를 구성하여 다음을 달성했습니다.

- **고가용성(High Availability, HA)**
    
    → 특정 DB 인스턴스에 장애가 발생해도 서비스 지속 가능
    
- **읽기 트래픽 분산(Scale-out)**
    
    → Secondary 노드를 활용한 조회 부하 분산
    
- **자동 장애조치(Failover)**
    
    → Primary 장애 발생 시 자동으로 다른 노드가 승격
    

---

### **1-1. 기본 구성**

### **① MySQL Server 4대 (mysql1 ~ mysql4)**

- 총 4개의 MySQL 인스턴스를 하나의 클러스터로 구성
- 구성 방식: **Single-Primary 모드**
    - 1대 → **Primary (R/W)**
    - 3대 → **Secondary (R/O)**

> Secondary를 3대로 구성하여
> 
- 읽기 부하 분산 여유 확보
- Primary 장애 시 승격 후보 확보
- 1대 장애까지 안정적 운영 가능

---

### **② Group Replication (핵심 엔진)**

Group Replication은 다음 기능을 수행합니다.

- Primary에서 발생한 트랜잭션을 Secondary로 복제
- 클러스터 멤버십 관리
- 장애 감지
- Primary 자동 재선출 (Failover)
- 트랜잭션 커밋 전 **합의(Consensus)** 수행

즉, 단순 복제가 아니라

**합의 기반 고가용성 복제 시스템**입니다.

---

### **③ MySQL Shell (AdminAPI)**

MySQL Shell의 AdminAPI를 사용하여 클러스터를 구성했습니다.

- dba.createCluster() → 클러스터 생성
- cluster.addInstance() → 인스턴스 추가
- cluster.status() → 상태 조회

이를 통해 수동 설정 없이 자동화된 클러스터 구성이 가능합니다.

---

### **④ MySQL Router (R/W 분리)**

MySQL Router를 사용하여 애플리케이션이 DB 토폴로지를 인지하지 않도록 구성했습니다.

| **포트** | **역할** |
| --- | --- |
| **6446** | Read/Write → 항상 현재 Primary |
| **6447** | Read Only → Secondary로 분산 |

애플리케이션은 Router에만 연결하며,
Primary 변경 시에도 **코드 수정 없이 자동 반영**됩니다.

---

## **🗳 2. Voting(Quorum)과 Primary 승격**

### **2-1. Quorum (과반수 원칙)**

Group Replication은 **과반수(majority) 기반 합의 시스템**입니다.

### **Quorum 공식**

```java
Quorum = ⌊N / 2⌋ + 1
```

본 프로젝트 구성:

```java
N = 4
Quorum = 3
```

즉,

- 최소 **3대가 살아 있어야 정상 동작**
- 1대 장애까지는 자동 복구 가능
- 2대 이상 장애 시 Quorum 붕괴 → 쓰기 차단 가능

이는 **Split-Brain 방지**를 위한 설계입니다.

---

### **2-2. Primary 선출 규칙**

Single-Primary 모드에서 Primary 장애 발생 시 다음 기준으로 승격됩니다.

1. group_replication_member_weight 값이 높은 인스턴스 우선
2. 동일할 경우 server_uuid가 가장 낮은 인스턴스 선택
3. 수동 지정도 가능 (group_replication_set_as_primary)

> 승격은 랜덤이 아닌, **결정적 규칙 기반**
> 

---

### **2-3. 합의 알고리즘 (XCom, Paxos Variant)**

Group Replication은 내부적으로 **XCom**이라는 그룹 통신 레이어를 사용하며,
이는 **Paxos 계열 합의 알고리즘 기반**입니다.

### **특징**

- 트랜잭션 커밋 전, 그룹 과반수 합의를 거침
- 멤버 상태 변경도 합의 기반으로 결정
- 네트워크 분할 시 과반 확보 그룹만 클러스터 유지

즉,

> 단순 복제가 아니라
“트랜잭션과 멤버 상태를 그룹 단위로 합의하여 확정하는 구조” 입니다.
> 

---

## **3. 클러스터 구성 절차**

### **Step 1. 초기화**

```bash
docker compose down -v
docker compose up -d
```

- 볼륨까지 삭제하여 완전 초기 상태로 시작
- InnoDB Cluster 메타데이터 초기화 목적

---

### **Step 2. 데이터 적재 (Cluster 구성 전)**

Cluster 구성 전에 **mysql1(Seed)** 에 먼저 데이터 적재

### **수행 작업**

- card_db 생성
- CARD_TRANSACTION 테이블 생성
- 복합 PK 설정

```sql
PRIMARY KEY (BAS_YH, SEQ)
```

- 약 500만 건 데이터 적재

### **설계 의도**

- 4대 각각 로딩하지 않음
- 1대(Seed)에만 로딩
- 이후 clone 방식으로 자동 복제

---

### **Step 3. Cluster 구성 (mysqlsh + AdminAPI)**

```jsx
dba.configureInstance()
dba.createCluster('wooriCardCluster')
cluster.addInstance(..., { recoveryMethod: 'clone' })
```

- 모든 인스턴스를 GR 요구사항에 맞게 구성
- mysql1을 Seed로 클러스터 생성
- mysql2/3/4를 clone 방식으로 자동 동기화

---

### **Step 4. Router 부트스트랩**

```bash
mysqlrouter --bootstrap root@mysql1:3306 ...
```

Router가:

- 클러스터 메타데이터 조회
- 설정 파일 자동 생성
- 6446(R/W) / 6447(R/O) 포트 생성

---

### **Step 5. 검증**

```sql
SELECT COUNT(*) FROM CARD_TRANSACTION;
```

- Secondary(mysql2~4)에서 row 수 동일 확인
- clone 및 replication 정상 여부 검증
