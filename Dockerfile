FROM tomcat:9.0-jdk21-temurin AS build

WORKDIR /workspace
COPY src ./src

# ── Redisson Tomcat Session Manager JARs ──
RUN curl -sL -o /tmp/redisson-all.jar \
    https://repo1.maven.org/maven2/org/redisson/redisson-all/3.27.0/redisson-all-3.27.0.jar && \
    curl -sL -o /tmp/redisson-tomcat-9.jar \
    https://repo1.maven.org/maven2/org/redisson/redisson-tomcat-9/3.27.0/redisson-tomcat-9-3.27.0.jar && \
    curl -sL -o /tmp/jstl-1.2.jar \
    https://repo1.maven.org/maven2/javax/servlet/jstl/1.2/jstl-1.2.jar

RUN set -eux; \
    mkdir -p build/WEB-INF/classes; \
    cp -R src/main/webapp/* build/; \
    cp -R src/main/resources/* build/WEB-INF/classes/; \
    cp /tmp/jstl-1.2.jar build/WEB-INF/lib/; \
    CLASSPATH="build/WEB-INF/lib/*:/usr/local/tomcat/lib/servlet-api.jar"; \
    find src/main/java -name '*.java' > sources.txt; \
    javac -encoding UTF-8 \
    -cp "$CLASSPATH" \
    -processorpath build/WEB-INF/lib/lombok-1.18.38.jar \
    -d build/WEB-INF/classes @sources.txt; \
    cd build; \
    jar -cvf app.war .

FROM tomcat:9.0-jdk21-temurin

ENV APP_NAME=sample-project
ENV LOG_DIR=/usr/local/tomcat/logs

RUN rm -rf /usr/local/tomcat/webapps/*

# ── Redisson JARs → Tomcat lib (Session Manager는 Tomcat 레벨) ──
COPY --from=build /tmp/redisson-all.jar /usr/local/tomcat/lib/
COPY --from=build /tmp/redisson-tomcat-9.jar /usr/local/tomcat/lib/

# ── Redisson 설정 → Tomcat conf ──
COPY docker/redisson.yaml /usr/local/tomcat/conf/redisson.yaml

COPY --from=build /workspace/build/app.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
