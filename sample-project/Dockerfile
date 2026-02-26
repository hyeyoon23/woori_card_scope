FROM tomcat:9.0-jdk21-temurin AS build

WORKDIR /workspace
COPY src ./src

RUN set -eux; \
    mkdir -p build/WEB-INF/classes; \
    cp -R src/main/webapp/* build/; \
    cp -R src/main/resources/* build/WEB-INF/classes/; \
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
COPY --from=build /workspace/build/app.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
