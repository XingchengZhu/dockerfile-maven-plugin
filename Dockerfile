# ====== Build Stage ======
FROM rockylinux/rockylinux:9.6.20250531 AS builder

# 基础工具 + OpenJDK 17 + Maven
RUN dnf clean all && \
    dnf -y --nobest --allowerasing update && \
    dnf -y --nobest --allowerasing install \
      java-17-openjdk-devel maven tzdata git which tar gzip && \
    dnf clean all

# 时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /app

# 先拷 POM 以利用缓存，再拷源码
COPY pom.xml ./
RUN mvn -B -U -q -DskipTests=true dependency:go-offline

COPY src ./src

# 打包（生成 target/*.jar）
RUN mvn -B -U -DskipTests=true clean package


# ====== Runtime Stage ======
FROM rockylinux/rockylinux:9.6.20250531

# 仅安装运行所需的 JRE
RUN dnf clean all && \
    dnf -y --nobest --allowerasing update && \
    dnf -y --nobest --allowerasing install \
      java-17-openjdk tzdata && \
    dnf clean all

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 应用目录
WORKDIR /app

# 将构建产物拷入运行镜像
# （如果你修改了 artifactId/version，请同步调整文件名或用通配）
COPY --from=builder /app/target/demo-jib-0.0.1-SNAPSHOT.jar /app/app.jar

EXPOSE 8080
CMD ["java", "-jar", "/app/app.jar"]
