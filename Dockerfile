# ===================== Build Stage =====================
FROM rockylinux/rockylinux:9.6.20250531 AS build

# 基础工具 + JDK17 + Maven
RUN dnf clean all && \
    dnf -y --nobest --allowerasing update && \
    dnf -y --nobest --allowerasing install \
      java-17-openjdk-devel maven tzdata git which tar gzip && \
    dnf clean all

# 时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /src

# 先拷 POM 走依赖缓存
COPY pom.xml ./
RUN mvn -B -U -q -DskipTests=true dependency:go-offline

# 再拷源码并打包
COPY src ./src
RUN mvn -B -U -DskipTests=true clean package

# 允许通过 --build-arg 覆盖 jar 路径；默认取 target 下的第一个 SNAPSHOT jar
ARG JAR_FILE=target/*-SNAPSHOT.jar
RUN test -f ${JAR_FILE} || (echo "Jar not found: ${JAR_FILE}" && ls -al target && exit 1)

# ===================== Runtime Stage =====================
FROM rockylinux/rockylinux:9.6.20250531

# 仅安装运行所需 JRE（headless 更轻）
RUN dnf clean all && \
    dnf -y --nobest --allowerasing update && \
    dnf -y --nobest --allowerasing install \
      java-17-openjdk-headless tzdata && \
    dnf clean all

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /app

# 与上面的 ARG 不是同一个作用域，所以这里再声明一次（可由 --build-arg 传入）
ARG JAR_FILE=target/*-SNAPSHOT.jar
COPY --from=build /src/${JAR_FILE} /app/app.jar

EXPOSE 8080

# 预留 JVM 启动参数（流水线/环境可以通过 -e JAVA_OPTS="..." 注入）
ENV JAVA_OPTS=""

# 用 sh -c 以便 JAVA_OPTS 生效
ENTRYPOINT ["sh","-c","exec java $JAVA_OPTS -jar /app/app.jar"]
