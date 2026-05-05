FROM eclipse-temurin:21-jdk-jammy AS builder

WORKDIR /build

# Copy wrapper and Gradle configuration files to cache dependencies
COPY gradlew settings.gradle build.gradle ./
COPY gradle gradle/

# Copying module configurations
COPY app/build.gradle app/
COPY modules/ modules/

# We remove the source code in modules, leaving only the build files for dependency caching.
RUN find modules -name "src" -type d -exec rm -rf {} +

# Pre-downloading dependencies
RUN ./gradlew :app:dependencies --no-daemon

# Copy the source code
COPY app/src app/src
COPY modules/ modules/

# Building a JAR artifact
RUN ./gradlew :app:bootJar --no-daemon -x test

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-jammy

LABEL maintainer="Platform Team" \
      project="Platform" \
      module="app"

# Installing curl to use healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Creating a system user to run the process (non-root)
RUN groupadd -r platform && useradd -r -g platform platform

WORKDIR /app
RUN chown platform:platform /app

# We copy only the finished artifact
COPY --from=builder --chown=platform:platform /build/app/build/libs/*.jar app.jar

USER platform

# JVM settings for running in a container
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080

# Checking application readiness via Actuator
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Using exec to send graceful shutdown signals
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]