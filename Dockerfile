# 单阶段：构建 + 运行
FROM 10.29.230.150:31381/library/m.daocloud.io/docker.io/rockylinux/rockylinux:9.6.20250531

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

WORKDIR /app

# 先拷 POM 预拉依赖（利用缓存）
COPY pom.xml ./

# 安装构建工具（Maven + JDK）并预取依赖；最后不清 cache（留着给后续步骤复用）
RUN dnf clean all && \
    dnf -y --nobest --allowerasing update && \
    dnf -y --nobest --allowerasing install \
      java-17-openjdk-devel maven tzdata git which tar gzip && \
    mvn -B -U -q -DskipTests=true dependency:go-offline

# 再拷源码并构建
COPY src ./src
RUN mvn -B -U -DskipTests=true clean package

# 复制产物到固定位置，并瘦身：安装 JRE、卸载构建工具、清理构建残留
RUN cp target/app.jar /app/app.jar && \
    dnf -y --nobest --allowerasing install java-17-openjdk-headless && \
    dnf -y remove maven java-17-openjdk-devel && \
    dnf -y autoremove && \
    dnf clean all && rm -rf /var/cache/dnf /root/.m2 /app/target

EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
