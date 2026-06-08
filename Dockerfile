# syntax=docker/dockerfile:1

FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

RUN chmod +x mvnw
RUN ./mvnw -B -DskipTests dependency:go-offline

COPY src/ src/

RUN ./mvnw -B -DskipTests package

FROM eclipse-temurin:17-jre-alpine AS runtime

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8080

ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseContainerSupport"

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
