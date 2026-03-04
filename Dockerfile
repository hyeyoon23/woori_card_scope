# ─────────────────────────────────────────
# Stage 1: Maven 빌드
# ─────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /workspace

# pom.xml 먼저 복사 → 의존성 레이어 캐시 활용
COPY pom.xml .
RUN mvn dependency:go-offline -q

# 소스 복사 후 WAR 빌드
COPY src ./src
RUN mvn package -DskipTests -q

# ─────────────────────────────────────────
# Stage 2: Tomcat 런타임
# ─────────────────────────────────────────
FROM tomcat:9.0-jdk21-temurin

ENV APP_NAME=sample-project
ENV LOG_DIR=/usr/local/tomcat/logs

RUN rm -rf /usr/local/tomcat/webapps/*

# ── Redisson Tomcat Session Manager JARs (Tomcat lib 레벨 필요) ──
RUN curl -sL -o /usr/local/tomcat/lib/redisson-all.jar \
    https://repo1.maven.org/maven2/org/redisson/redisson-all/3.27.0/redisson-all-3.27.0.jar && \
    curl -sL -o /usr/local/tomcat/lib/redisson-tomcat-9.jar \
    https://repo1.maven.org/maven2/org/redisson/redisson-tomcat-9/3.27.0/redisson-tomcat-9-3.27.0.jar

# ── Redisson 설정 → Tomcat conf ──
COPY docker/redisson.yaml /usr/local/tomcat/conf/redisson.yaml

# ── Maven 빌드 결과물 배포 ──
COPY --from=build /workspace/target/woori_card_scope.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
