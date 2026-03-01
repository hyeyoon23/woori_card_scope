# 🃏 Woori Card Scope

우리카드의 530만개 고객 데이터를 기반으로 카드 이용 현황을 조회하고 분석하는 웹 애플리케이션입니다.

---

## 기술 스택

| 분류 | 기술 |
|------|------|
| Language | Java 21 |
| Runtime | Tomcat 9 |
| Frontend | JSP, HTML/CSS |
| Database | MySQL 8.0 (InnoDB Cluster) |
| Session Store | Redis 7 (Redisson Tomcat Session Manager) |
| Connection Pool | HikariCP |
| Load Balancer | Nginx (least_conn) |
| Infra | Docker Compose |

---

## 아키텍처

<img width="901" height="302" alt="woori-card-scope drawio (1)" src="https://github.com/user-attachments/assets/5a7be9ed-ca9c-4df5-ae02-b77a84d1b94f" />

### 애플리케이션 레이어 구조

```
Presentation Layer  (Servlet)
    │
Service Layer       (CustomerService, UserService)
    │
Data Access Layer   (CustomerDAO, UserDAO)
    │
DTO Layer           (CustomerDTO - record, UserDTO)
```

---

## Nginx 로드밸런싱 — least_conn

### 이 프로젝트에서 least_conn을 선택한 이유

우리카드 프로젝트에는 두 종류의 요청이 섞여 들어옵니다.

```
① 고객 목록 조회 (단순)           → 빠름 (0.1초)
② 고객 상세 조회 (중분류 집계 포함) → 느림 (1~2초)
```

Round Robin이면 이런 상황이 생깁니다.

```
WAS1: [느린요청] [느린요청] [느린요청] ← 꽉 참
WAS2: [빠른요청] [빠른요청] [빠른요청] ← 여유 있음

새 요청이 오면? → Round Robin은 그냥 WAS1으로 보냄 (꽉 찼는데도!)
```

least_conn이면?

```
WAS1: conns=10 (느린 요청들로 꽉 참)
WAS2: conns=2  (빠른 요청들 처리하고 여유)

새 요청 → WAS2로! (연결 수가 더 적으니까)
```

> Round Robin은 처리 시간과 무관하게 순번만 보기 때문에 특정 WAS에 느린 요청이 쌓일 수 있습니다.
> least_conn은 **현재 연결 수가 적은 서버**에 요청을 보내므로 이런 환경에서 더 균등한 부하 분산이 가능합니다.

---

### RR → WRR → SWRR 발전 흐름

**1. Round Robin (RR)**

- 서버 상태나 부하와 무관하게 순번대로 요청을 분배

```
요청1 → WAS1
요청2 → WAS2
요청3 → WAS1  ← WAS1이 느린 요청 처리중이어도 상관없이 보냄
요청4 → WAS2
```

**2. Weighted Round Robin (WRR)**

- 서버마다 weight를 두어 비중대로 분배
- weight 3:1이면 A → A → A → B 순으로 분배
- 특정 순간 한 서버에 요청이 몰리는 문제 존재

```
요청1 → WAS1
요청2 → WAS1
요청3 → WAS1  ← 요청 1~3이 한꺼번에 WAS1으로 몰림!
요청4 → WAS2
```

**3. Smooth Weighted Round Robin (SWRR)**

- WRR의 몰림 현상을 개선
- `current_weight`를 누적해서 요청을 고르게 분산
- weight 3:1 예시: A → A → B → A (중간에 B가 끼어들어 분산)

```
요청1 → WAS1  (current_weight: WAS1=3, WAS2=1)
요청2 → WAS1  (current_weight: WAS1=2, WAS2=2)
요청3 → WAS2  (current_weight: WAS1=1, WAS2=3) ← WAS2가 끼어듦!
요청4 → WAS1  (current_weight: WAS1=3, WAS2=1)
```

---

### least_conn 내부 동작

least_conn은 Round Robin 인프라(RR peer 구조) 위에서 동작하며, 동률이 발생하는 경우에만 SWRR 계산을 추가로 수행합니다.

```
[1단계] 전체 서버 순회
  → 부하율(conns / weight)이 가장 낮은 서버를 best로 선정
  → 비교식: peer->conns * best->weight < best->conns * peer->weight
     (정수 나누기 소수점 잘림 방지를 위해 교차 곱으로 변환)

[2단계] 동률 처리 (many == 1 일 때만 진입)
  → 동률 서버들끼리 SWRR로 tie-breaking
  → current_weight가 가장 높은 서버를 선택
  → 선택된 서버는 total만큼 current_weight를 차감 (다음 요청에서 불리)

[3단계] best 확정
  → best->conns++ (연결 수 증가)
  → tried 비트맵에 시도 표시
```

> **핵심**: 동률이 없으면 1단계만으로 서버를 확정하므로 불필요한 연산을 최소화합니다.

---

### 주요 용어

| 용어 | 설명 |
|------|------|
| `peer` | 백엔드 서버 한 대 (WAS1 또는 WAS2) |
| `peer->conns` | 현재 이 서버에 붙어있는 연결 수 |
| `peer->weight` | 설정에서 지정한 가중치 (기본 1) |
| `peer->effective_weight` | 실제 사용되는 가중치 (에러 시 감소, 정상화 시 복구) |
| `peer->current_weight` | 요청을 못 받을수록 쌓이고, 받을수록 깎이는 값 |
| `best` | 순회 중 현재까지 찾은 가장 좋은 서버 후보 |
| `tried` | 비트맵으로 이미 시도한 서버를 기록 |

---

### 부하율 비교식의 원리

원래 비교하고 싶은 것은 부하율입니다.

```
peer->conns / peer->weight  <  best->conns / best->weight
```

정수 나누기는 소수점이 잘리므로, 양변에 `peer->weight × best->weight`를 곱해 나누기를 제거합니다.

```
peer->conns * best->weight  <  best->conns * peer->weight
```

→ **상대방의 weight로 환산하여 같은 단위로 비교**하는 방식입니다.

**예시**

```
WAS1: conns=2, weight=1  (약한 서버)
WAS2: conns=4, weight=3  (강한 서버)

단순 conns만 보면 WAS1이 더 여유있어 보임 (2 < 4)
근데 WAS2는 원래 3배 더 받아야 하는 서버!

부하율로 보면
  WAS1: 2/1 = 2.0  (과부하!)
  WAS2: 4/3 = 1.33 (여유)

교차 곱으로 변환하면 (소수점 잘림 방지)
  WAS2->conns * WAS1->weight  <  WAS1->conns * WAS2->weight
  4 * 1 = 4                   <  2 * 3 = 6   → WAS2가 더 낫다! ✓
```

---

### 동률 처리 흐름

```
서버 순회 중...

WAS1: 부하율 1.0 → best=WAS1, many=0, p=0
WAS2: 부하율 1.5 → 높음 → 스킵
WAS3: 부하율 1.0 → 동률! many=1
WAS4: 부하율 0.5 → 낮음! → best=WAS4, many=0, p=3  (WAS1,WAS3 동률 초기화!)
WAS5: 부하율 0.5 → 동률! many=1

1단계 끝: best=WAS4, many=1, p=3
→ WAS1, WAS2, WAS3는 고려 안 함 (WAS4보다 부하율이 높거나 이미 초기화됨)

2단계: WAS4, WAS5만 current_weight 경쟁
→ 더 오래 못 받은 서버가 선택됨
```

> 📎 least_conn 내부 구현이 궁금하다면: [ngx_http_upstream_least_conn_module.c (GitHub)](https://github.com/nginx/nginx/blob/master/src/http/modules/ngx_http_upstream_least_conn_module.c)

---

## WAS 이중화와 세션 동기화 — Redis 도입 배경

### 문제 정의

WAS를 2대로 이중화하면서 **세션 기반 인증**을 유지해야 합니다.
사용자가 WAS1에서 로그인한 뒤, 다음 요청이 Nginx에 의해 WAS2로 라우팅되면
세션이 존재하지 않아 **로그인이 풀리는 문제**가 발생합니다.

### 세션 동기화 방식 비교 (Trade-off)

이중화된 WAS 환경에서 세션을 동기화하는 5가지 방식을 검토했습니다.

| 방식 | 장점 | 단점 | 판정 |
|------|------|------|------|
| **DB 저장** | 구현 간단, 영속성 보장 | Disk I/O → 느림, 매 요청마다 DB 조회 부하 | ❌ |
| **Redis 저장** | Memory I/O → 빠름, WAS 무관하게 세션 공유 | Redis 장애 시 세션 유실 가능 | ✅ |
| **JWT** | 서버 상태 불필요, 수평 확장 용이 | 토큰이 클라이언트에 존재 → **세션 제어권 상실** (은행권 부적합) | ❌ |
| **Sticky Session** | 설정 간단 (nginx `ip_hash`) | 세션 생성한 WAS로만 라우팅 → **이중화의 장점을 충분히 활용하기 어려움** + WAS 장애 시 **세션 복구가 보장되지 않음** | ❌ |
| **Tomcat Clustering** | 별도 인프라 불필요 | WAS 간 세션 복제에 TCP/멀티캐스트 필요 → **WAS 증설 시 트래픽 폭증** (N² 문제) | ❌ |

### Redis를 선택한 이유

1. **복제 불필요** — 외부 저장소에 단일 저장하므로 WAS 간 세션 복제가 필요 없음
2. **빠른 I/O** — 인메모리 기반으로 Disk I/O 대비 수십 배 빠름
3. **제어권 유지** — 서버 측에서 세션을 관리하므로 강제 로그아웃, 세션 만료 등 통제 가능
4. **수평 확장 용이** — WAS를 몇 대로 늘려도 Redis만 바라보면 되므로 유지보수 부담 최소

### 적용 방식 — Redisson Tomcat Session Manager

별도의 세션 관리 코드 없이, Tomcat의 세션 매니저를 Redisson으로 교체하여
**기존 `HttpSession` API를 그대로 사용**하면서 세션이 자동으로 Redis에 저장됩니다.

```xml
<!-- META-INF/context.xml -->
<Manager className="org.redisson.tomcat.RedissonSessionManager"
         configPath="${catalina.base}/redisson.yaml"
         readMode="REDIS" updateMode="DEFAULT" />
```

```yaml
# redisson.yaml
singleServerConfig:
  address: "redis://${REDIS_HOST}:${REDIS_PORT}"
```

#### 동작 흐름

```
1. 사용자가 WAS1에서 로그인
2. HttpSession에 UserDTO 저장 → Redisson이 자동으로 Redis에 직렬화하여 저장
3. 다음 요청이 Nginx에 의해 WAS2로 라우팅
4. WAS2의 Redisson Session Manager가 JSESSIONID로 Redis에서 세션 조회
5. 동일한 UserDTO가 역직렬화되어 세션 유지 → 로그인 상태 유지
```

> **주의**: Redis에 저장되는 세션 객체(`UserDTO`)는 반드시 `Serializable`을 구현해야 합니다.
> 패키지 변경 시 기존 세션과 호환되지 않으므로 Redis FLUSHALL이 필요합니다.

### 인증 흐름 (Sequence Diagram)

#### 로그인 흐름
<img width="1097" height="1155" alt="image" src="https://github.com/user-attachments/assets/5034acf5-a09c-44d7-b8fc-f60c0183ad0a" />

#### WAS 간 세션 공유 흐름
<img width="839" height="906" alt="image" src="https://github.com/user-attachments/assets/1028e85d-1d39-4365-8c8d-9b02b458130f" />

---

## 주요 기능

### 고객 목록 조회
- 기준시점(분기) 기반 전체 고객 목록 조회
- 필터: 등급 / 연령대 / 성별 / 지역 / 고객번호(SEQ)

#### 페이징 — Deferred Join 방식

약 500만 건의 데이터에서 단순 `OFFSET` 페이징을 사용하면, 페이지가 뒤로 갈수록 **건너뛸 행을 전부 읽고 버리기 때문에** 성능이 급격히 저하됩니다.

**일반 OFFSET 페이징 (느림)**

```sql
SELECT * FROM CARD_TRANSACTION
ORDER BY SEQ
LIMIT 20 OFFSET 100000;
-- → 100,000행을 읽고 버린 뒤 20행만 반환 (비효율)
```

**Deferred Join 페이징 (빠름)**

서브쿼리에서 PK(SEQ)만 먼저 추출한 뒤, 메인 테이블과 JOIN하여 필요한 컬럼만 가져옵니다.

```sql
-- 실제 CustomerDAO.findAll() 코드
SELECT SUBSTR(c.BAS_YH, 1, 4) AS BAS_YH, c.SEQ,
       MAX(c.MBR_RK) AS MBR_RK, MAX(c.AGE) AS AGE,
       MAX(c.SEX_CD) AS SEX_CD, MAX(c.HOUS_SIDO_NM) AS HOUS_SIDO_NM,
       SUM(c.TOT_USE_AM) AS TOT_USE_AM
FROM CARD_TRANSACTION c
JOIN (
    -- ① 서브쿼리: PK만 빠르게 추출 (커버링 인덱스 활용)
    SELECT DISTINCT SEQ FROM CARD_TRANSACTION
    ORDER BY SEQ LIMIT ? OFFSET ?
) tmp ON c.SEQ = tmp.SEQ          -- ② Deferred Join
GROUP BY SUBSTR(c.BAS_YH, 1, 4), c.SEQ
ORDER BY c.SEQ, SUBSTR(c.BAS_YH, 1, 4);
```

| 단계 | 역할 |
|------|------|
| ① 서브쿼리 | **PK(SEQ)만** 대상으로 OFFSET → 인덱스만 스캔하므로 빠름 |
| ② JOIN | 선별된 SEQ에 해당하는 행만 메인 테이블에서 조회 |

> **핵심**: OFFSET이 크더라도 서브쿼리는 인덱스만 탐색하므로 실제 데이터 행을 읽지 않습니다. 메인 테이블 접근은 `LIMIT` 개수(20건)만큼만 발생하여 페이지 깊이와 무관하게 일정한 성능을 유지합니다.

#### 동적 쿼리 — `StringBuilder + List<Object>` 방식

파라미터가 `null`이 아닌 경우에만 `WHERE` 조건을 추가하는 방식으로, SQL Injection을 방지하면서 유연한 검색을 구현합니다.

**핵심 헬퍼 메서드** (`CustomerDAO.java`)

```java
/** 동적 쿼리 필터 조건 추가 */
private void appendFilter(StringBuilder sql, List<Object> params,
        String column, String value) {
    if (value != null && !value.isEmpty()) {
        sql.append(" AND ").append(column).append(" = ?");
        params.add(value);
    }
}
```

**실제 사용 — `findByFilter()`**

```java
public List<CustomerDTO.ListAllDTO> findByFilter(String mbrRk, String age, String sexCd,
        String housSidoNm, String seq, int page, int pageSize) throws SQLException {

    List<Object> innerParams = new ArrayList<>();

    // 1) 내부 서브쿼리: 필터 조건에 맞는 SEQ만 추출 (Deferred Join)
    StringBuilder innerSql = new StringBuilder(
            "SELECT DISTINCT SEQ FROM CARD_TRANSACTION WHERE 1=1");

    appendFilter(innerSql, innerParams, "MBR_RK", mbrRk);     // null이면 스킵
    appendFilter(innerSql, innerParams, "AGE", age);           // null이면 스킵
    appendFilter(innerSql, innerParams, "SEX_CD", sexCd);      // null이면 스킵
    appendFilter(innerSql, innerParams, "HOUS_SIDO_NM", housSidoNm);
    appendFilter(innerSql, innerParams, "SEQ", seq);

    innerSql.append(" ORDER BY SEQ LIMIT ? OFFSET ?");
    innerParams.add(pageSize);
    innerParams.add(offset);

    // 2) 파라미터 바인딩: PreparedStatement로 SQL Injection 방지
    for (int i = 0; i < allParams.size(); i++) {
        pstmt.setObject(i + 1, allParams.get(i));
    }
}
```

> **`WHERE 1=1`을 사용하는 이유**: 첫 번째 조건이든 마지막 조건이든 항상 `AND`로 시작할 수 있어 분기 처리가 필요 없습니다.

### 고객 상세 조회
- 고객번호(SEQ) 기반 상세 정보 조회
- 가장 많이 소비한 중분류 1개 (Spending Type)
- 현재 등급 및 다음 등급까지 남은 금액 / 진행률

### 등급 체계

| 코드 | 등급명 | 다음 등급 기준 |
|------|--------|----------------|
| 25 | 기타 | 500만원 → Gold |
| 24 | Gold | 1,000만원 → Platinum |
| 23 | Platinum | 1,500만원 → VIP |
| 22 | VIP | 2,000만원 → VVIP |
| 21 | VVIP | 최고 등급 |

---

## 구현 시 고려사항

- `PreparedStatement` 사용으로 SQL Injection 방지
- `try-with-resources` 로 Connection / Statement / ResultSet 자원 해제
- HikariCP 커넥션 풀을 Read / Write 분리하여 각각 관리
- DTO는 `record` 타입으로 불변 객체 보장
- 세션 객체는 `Serializable` 구현 필수 (Redis 직렬화/역직렬화)
- `AuthFilter`로 보호 경로 일괄 접근 제어

---

# 데이터베이스 설계

## 1. InnoDB Cluster 구성

본 프로젝트는 **MySQL InnoDB Cluster** 기반으로 데이터베이스를 구성하여 다음을 달성했습니다.

- **고가용성(High Availability, HA)** → 특정 DB 인스턴스에 장애가 발생해도 서비스 지속 가능
- **읽기 트래픽 분산(Scale-out)** → Secondary 노드를 활용한 조회 부하 분산
- **자동 장애조치(Failover)** → Primary 장애 발생 시 자동으로 다른 노드가 승격

---

### 1-1. 기본 구성

#### ① MySQL Server 4대 (mysql1 ~ mysql4)

- 총 4개의 MySQL 인스턴스를 하나의 클러스터로 구성
- 구성 방식: **Single-Primary 모드**
  - 1대 → **Primary (R/W)**
  - 3대 → **Secondary (R/O)**

> Secondary를 3대로 구성하여 읽기 부하 분산 여유 확보, Primary 장애 시 승격 후보 확보, 1대 장애까지 안정적 운영 가능

---

#### ② Group Replication (핵심 엔진)

Group Replication은 다음 기능을 수행합니다.

- Primary에서 발생한 트랜잭션을 Secondary로 복제
- 클러스터 멤버십 관리
- 장애 감지
- Primary 자동 재선출 (Failover)
- 트랜잭션 커밋 전 **합의(Consensus)** 수행

즉, 단순 복제가 아니라 **합의 기반 고가용성 복제 시스템**입니다.

---

#### ③ MySQL Shell (AdminAPI)

MySQL Shell의 AdminAPI를 사용하여 클러스터를 구성했습니다.

- `dba.createCluster()` → 클러스터 생성
- `cluster.addInstance()` → 인스턴스 추가
- `cluster.status()` → 상태 조회

---

#### ④ MySQL Router (R/W 분리)

MySQL Router를 사용하여 애플리케이션이 DB 토폴로지를 인지하지 않도록 구성했습니다.

| 포트 | 역할 |
|------|------|
| **6446** | Read/Write → 항상 현재 Primary |
| **6447** | Read Only → Secondary로 분산 |

애플리케이션은 Router에만 연결하며, Primary 변경 시에도 **코드 수정 없이 자동 반영**됩니다.

---

## 2. Voting(Quorum)과 Primary 승격

### 2-1. Quorum (과반수 원칙)

Group Replication은 **과반수(majority) 기반 합의 시스템**입니다.

**Quorum 공식**

```
Quorum = ⌊N / 2⌋ + 1
```

본 프로젝트 구성:

```
N = 4
Quorum = 3
```

즉,
- 최소 **3대가 살아 있어야 정상 동작**
- 1대 장애까지는 자동 복구 가능
- 2대 이상 장애 시 Quorum 붕괴 → 쓰기 차단 가능

이는 **Split-Brain 방지**를 위한 설계입니다.

---

### 2-2. Primary 선출 규칙

Single-Primary 모드에서 Primary 장애 발생 시 다음 기준으로 승격됩니다.

1. `group_replication_member_weight` 값이 높은 인스턴스 우선
2. 동일할 경우 `server_uuid`가 가장 낮은 인스턴스 선택
3. 수동 지정도 가능 (`group_replication_set_as_primary`)

> 승격은 랜덤이 아닌, **결정적 규칙 기반**

---

### 2-3. 합의 알고리즘 (XCom, Paxos Variant)

Group Replication은 내부적으로 **XCom**이라는 그룹 통신 레이어를 사용하며, 이는 **Paxos 계열 합의 알고리즘 기반**입니다.

**특징**
- 트랜잭션 커밋 전, 그룹 과반수 합의를 거침
- 멤버 상태 변경도 합의 기반으로 결정
- 네트워크 분할 시 과반 확보 그룹만 클러스터 유지

> 단순 복제가 아니라 "트랜잭션과 멤버 상태를 그룹 단위로 합의하여 확정하는 구조"입니다.

---

## 3. 클러스터 구성 절차

### Step 1. 초기화

```bash
docker compose down -v
docker compose up -d
```

- 볼륨까지 삭제하여 완전 초기 상태로 시작
- InnoDB Cluster 메타데이터 초기화 목적

---

### Step 2. 데이터 적재 (Cluster 구성 전)

Cluster 구성 전에 **mysql1(Seed)** 에 먼저 데이터 적재

**수행 작업**
- card_db 생성
- CARD_TRANSACTION 테이블 생성
- 복합 PK 설정

```sql
PRIMARY KEY (BAS_YH, SEQ)
```

- 약 500만 건 데이터 적재

**설계 의도**
- 4대 각각 로딩하지 않음
- 1대(Seed)에만 로딩
- 이후 clone 방식으로 자동 복제

---

### Step 3. Cluster 구성 (mysqlsh + AdminAPI)

```js
dba.configureInstance()
dba.createCluster('wooriCardCluster')
cluster.addInstance(..., { recoveryMethod: 'clone' })
```

- 모든 인스턴스를 GR 요구사항에 맞게 구성
- mysql1을 Seed로 클러스터 생성
- mysql2/3/4를 clone 방식으로 자동 동기화

---

### Step 4. Router 부트스트랩

```bash
mysqlrouter --bootstrap root@mysql1:3306 ...
```

Router가:
- 클러스터 메타데이터 조회
- 설정 파일 자동 생성
- 6446(R/W) / 6447(R/O) 포트 생성

---

### Step 5. 검증

```sql
SELECT COUNT(*) FROM CARD_TRANSACTION;
```

- Secondary(mysql2~4)에서 row 수 동일 확인
- clone 및 replication 정상 여부 검증

---

## 4. Failover Test (Primary 장애 시 자동 승격 테스트)

InnoDB Cluster의 핵심 기능 중 하나는 **Primary 장애 발생 시 자동으로 Secondary가 승격되는지 여부**입니다.

---

### 4-1. 현재 Primary 확인

```js
cluster.status()
```

예시 출력:

```json
"primary": "mysql1:3306"
```

→ 현재 Primary가 mysql1임을 확인

---

### 4-2. Primary 강제 중지 (장애 시뮬레이션)

```bash
docker stop woori-card-scope-mysql1
```

- Primary(mysql1)를 강제로 중단
- 실제 운영 환경에서의 장애 상황을 가정

---

### 4-3. Failover 대기

```bash
sleep 15
```

- Group Replication이 장애를 감지하고
- 새로운 Primary를 선출할 시간을 확보

(일반적으로 수 초 ~ 10초 내에 자동 선출됨)

---

### 4-4. 새로운 Primary 확인

```bash
docker exec -it woori-card-scope-mysqlsh \
mysqlsh root@mysql2:3306 -- \
cluster status
```

예시 출력:

```json
"primary": "mysql2:3306"
```

→ mysql2가 새로운 Primary로 승격됨 확인

또는 Router를 통해 확인:

```sql
SELECT @@hostname;
```

---

### 4-5. 기존 Primary 복구

```bash
docker start woori-card-scope-mysql1
```

- mysql1 재기동
- 자동으로 Secondary로 클러스터에 재합류

상태 확인 후 예시 출력:

```json
"mysql1:3306": {
  "mode": "R/O",
  "status": "ONLINE"
}
```
