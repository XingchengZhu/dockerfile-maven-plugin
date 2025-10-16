# 单阶段：构建 + 运行都在同一个镜像里（简单但体积较大）
FROM 10.29.230.150:31381/library/m.daocloud.io/docker.io/rockylinux/rockylinux:9.6.20250531

# 基础工具 + OpenJDK 1.8 + Maven
RUN dnf clean all && \
    dnf -y --nobest --allowerasing update && \
    dnf -y --nobest --allowerasing install \
      java-1.8.0-openjdk-devel maven tzdata git which tar gzip && \
    dnf clean all

# 时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /app

# 先拷 POM 利用依赖缓存
COPY pom.xml ./
RUN mvn -B -U -q -DskipTests=true dependency:go-offline

# 再拷源码并打包
COPY src ./src
RUN mvn -B -U -DskipTests=true clean package

EXPOSE 8080

# 直接运行 target 产物；用 sh -c 允许通配符匹配 jar 名
ENTRYPOINT ["sh","-c","exec java -jar /app/target/*.jar"]
