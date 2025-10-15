# demo-jib (Route B: Maven + Jib)

A minimal Spring Boot (Java 8) project that builds a container image with **Jib** (no local Docker needed).

## Build & Test
```bash
mvn -B -U -DskipTests=false clean test
```

JUnit XML will appear in `target/surefire-reports/`.

## Build Container Image with Jib

Push to your registry (HTTP registry supported):

```bash
mvn -B -U -DskipTests=true \  -Dimage=10.29.230.150:31381/library/demo-jib:test \  clean package jib:build
```

- Jib does **not** require Docker/Podman.
- For HTTP registry, `allowInsecureRegistries` is already enabled in `pom.xml`.
- If auth is required, put credentials in `~/.m2/settings.xml`:
```xml
<settings>
  <servers>
    <server>
      <id>10.29.230.150:31381</id>
      <username>admin</username>
      <password>Admin123</password>
    </server>
  </servers>
</settings>
```
Then run with:
```bash
mvn -Dimage=10.29.230.150:31381/library/demo-jib:test \    -Djib.to.auth.username=admin -Djib.to.auth.password=Admin123 \    clean package jib:build
```

## Run locally (without container)
```bash
mvn spring-boot:run
# open http://localhost:8080/hello
```

