FROM 10.29.230.150:31381/library/eclipse-temurin:8-jre

ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} /app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","/app.jar"]
