# 인증 및 Redis 세션 연동 인수인계 문서 🚀

본 문서는 새롭게 추가된 **회원가입/로그인(인증)** 기능과 **WAS 다중화(2대) 환경에서의 Redis 세션 공유(Clustering)** 아키텍처에 대한 정보를 팀원들께 공유하기 위해 작성되었습니다.

---

## 1. 아키텍처 개요 (Redis Session Clustering)
기존에는 Nginx 밑에 두 대의 Tomcat 컨테이너(`was1`, `was2`)가 띄워져 있었지만, 사용자가 로그인했을 때 어떤 WAS로 요청이 가느냐에 따라 로그인(세션)이 풀리는 문제가 발생할 수 있었습니다.
이를 해결하기 위해 **Tomcat의 세션 저장소를 Redis로 통합**했습니다.

- **원리:** Tomcat의 `RedissonSessionManager`가 `JSESSIONID`를 키로 사용하여 브라우저 세션 객체를 Redis에 저장/조회합니다.
- **설정 위치:** 
  - `docker/redisson.yaml` (Redis 접속 정보)
  - `src/main/webapp/META-INF/context.xml` (Tomcat 세션 매니저 주입)

> **✨ 핵심 기대 효과:** Nginx 로드밸런싱에 의해 사용자의 다음 요청이 `was1`에서 `was2`로 넘어가더라도, Redis를 통해 동일한 `UserDTO` 세션을 꺼내오기 때문에 로그인 상태가 끊김 없이 완벽하게 유지됩니다!

---

## 2. 데이터베이스 스키마 변경 (MySQL)
회원 인증을 위해 `USERS` 테이블을 신규로 추가했습니다.
(`docker/mysql/init/schema.sql` 스크립트의 최하단에 반영됨)

```sql
CREATE TABLE IF NOT EXISTS `USERS` (
    `ID`       VARCHAR(50)  NOT NULL COMMENT '사용자 아이디 (로그인용)',
    `PASSWORD` VARCHAR(255) NOT NULL COMMENT '비밀번호',
    `NAME`     VARCHAR(50)  NOT NULL COMMENT '사용자 이름/닉네임',
    PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

> 💡 **초기 테스트 계정**  
> 어드민 로그인을 위해 기본 데이터가 주입되어 있습니다.
> - **아이디:** `admin`
> - **비밀번호:** `1234`

---

## 3. 백엔드 및 웹 계층 주요 소스코드

### 3.1 DTO / DAO / Service
- `UserDTO.java`: 유저 정보를 담는 객체. (Redis에 저장되기 위해 반드시 `Serializable` 인터페이스 구현)
- `UserDAO.java`: DB에서 `USERS` 테이블을 조회 및 삽입(회원가입)하는 클래스
- `UserService.java`: 로그인/회원가입 비즈니스 로직을 담당하며 최초 Application 구동 시 `ApplicationContextListener`를 통해 ServletContext에 공통 컨텍스트로 등록됩니다.

### 3.2 컨트롤러 (Servlet)
- `SignupServlet.java`: `/signup` 경로 처리 (GET: 화면, POST: 회원가입 수행)
- `LoginServlet.java`: `/login` 경로 처리 (GET: 화면, POST: 로그인 성공 시 Session에 `UserDTO` 객체 삽입)
- `LogoutServlet.java`: `/logout` 경로 처리 (Session invalidate)

### 3.3 보안 필터 (AuthFilter)
- `AuthFilter.java`: 로그인이 안 된 사용자가 `/customers/*` 나 `/api/*` 경로로 접근하면 가로채서 강제로 `/login` 페이지로 튕기게 만드는 수문장 역할입니다.

---

## 4. 프론트엔드 변경 사항 (JSP)
- **추가된 화면:** `login.jsp` (로그인), `signup.jsp` (회원가입)
- **메인 화면 연동:** `customers.jsp` 상단 헤더에 현재 접속한 사람의 **"OOO 님 환영합니다"** 문구와 **[로그아웃]** 버튼이 나오도록 UI를 추가했습니다.

---

## 5. 서버 기동 및 팀원 테스트 방법

현재 DB 스키마 추가 사항이 있으므로, 기존 DB 볼륨 등으로 인해 `schema.sql`이 덮어씌워지지 않았다면 반드시 컨테이너를 내린 후 클린 빌드하시는 것을 권장합니다.
(또는 접속 중인 MySQL 툴에서 `USERS` 테이블 생성 쿼리만 직접 수동 실행하셔도 됩니다.)

```bash
# 전체 서비스 내리기
docker compose down

# 새롭게 빌드하며 전체 서비스 기동
docker compose up -d --build
```

- 메인 페이지(`http://localhost/`) 접속 시 `/login` 으로 자동 이동되는지 확인합니다.
- `admin` / `1234` 로 로그인 후 고객 리스트 화면으로 잘 들어오는지 확인합니다.
- `/logout` 기능을 눌러 세션이 파기되는지 확인합니다.
