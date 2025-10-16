 单阶段 Maven + Jib 流水线（私有仓库 / HTTP）

本项目使用 **Maven + Jib** 在 **无需 Docker/Podman 守护进程** 的情况下，直接从源码构建并**推送容器镜像**到私有仓库。

> * **无需 Dockerfile**：Jib 会自动分层打包 `dependencies/classes/resources`。
> * **支持 HTTP 私库**：通过 `-Djib.allowInsecureRegistries=true -DsendCredentialsOverHttp=true`。
> * **可收集测试报告**：先在宿主机跑 `mvn test`，再执行 Jib 构建。

---

## 目录

* [前置条件](#前置条件)
* [流水线命令（推荐：先测后构建）](#流水线命令推荐先测后构建)
* [POM 约定](#pom-约定)
* [镜像运行验证](#镜像运行验证)
* [常见问题排查](#常见问题排查)
* [可选参数速查](#可选参数速查)

---

## 前置条件

* Maven 已安装并可访问公网或内部 Maven 仓库（首次构建会下载依赖）。
* 目标与基础镜像仓库：`10.29.230.150:31381`（HTTP 私库）。
* 账户：`admin / Admin123`。
* 代码使用 **Java 8**（pom 已设定 `<java.version>1.8</java.version>`）。

---

## 流水线命令（推荐：先测后构建）

### 1) 运行单元测试并生成报告（失败不阻断）

```bash
mvn -B -U -fae -DskipTests=false -Dmaven.test.failure.ignore=true clean test
```

Jenkins 测试报告收集路径：

```
**/target/surefire-reports/*.xml, **/target/failsafe-reports/*.xml
```

### 2) 使用 Jib 构建并推送镜像

```bash
mvn -B -U -DskipTests=true \
  -Djib.from.image=10.29.230.150:31381/library/eclipse-temurin:8-jre \
  -Djib.from.auth.username=admin -Djib.from.auth.password=Admin123 \
  -Djib.to.image=10.29.230.150:31381/library/testrepo:test \
  -Djib.to.auth.username=admin -Djib.to.auth.password=Admin123 \
  -Djib.allowInsecureRegistries=true \
  -DsendCredentialsOverHttp=true \
  clean package jib:build
```

> 说明
>
> * `jib.from.image`：基础运行时镜像（这里用 Java 8 JRE）。也可以换成你私库里的其它基础镜像。
> * `jib.to.image`：目标镜像（项目镜像）推送到私库。
> * `allowInsecureRegistries + sendCredentialsOverHttp`：允许 HTTP 并在 HTTP 下发送凭据（仅限可信内网）。
> * 已在 `pom.xml` 内配置 `jib-maven-plugin`，此处命令行参数会覆盖 `<configuration>` 占位值。

---

## POM 约定

* POM 已设定：

  * Java 8 编译目标：`maven-compiler-plugin` (`source/target=1.8`)
  * Spring Boot 2.7.x
  * `maven-surefire-plugin` 生成测试报告
  * `jib-maven-plugin`（内含占位 `from/to`，以命令行覆盖）

> 如需改端口，在 `pom.xml` 里 Jib 的 `<container><ports><port>8080</port></ports></container>` 或命令行覆盖：
> `-Djib.container.ports=8080`

---

## 镜像运行验证

构建成功后可在任意有容器引擎的机器上验证：

```bash
# Podman（或 Docker）均可
podman run --rm -p 8080:8080 10.29.230.150:31381/library/testrepo:test
# 访问：http://<宿主机IP>:8080/
```

---

## 常见问题排查

1. **报错 `Network is unreachable (connect failed)` 访问 `registry-1.docker.io`**

   * 通常是基础镜像在 DockerHub，但你的环境无法直连公网。
   * 解决：把基础镜像也**预拉到私库**，用 `-Djib.from.image=<你的私库镜像>`（本 README 已使用私库 `eclipse-temurin:8-jre`）。

2. **报错 “Required credentials … were not sent because the connection was over HTTP”**

   * 需要同时启用：

     * `-Djib.allowInsecureRegistries=true`
     * `-DsendCredentialsOverHttp=true`

3. **认证失败**

   * 检查用户名/密码是否正确；也可在 `~/.m2/settings.xml` 配置 `<servers>`，用 `-Djib.to.auth.username` / `-Djib.to.auth.password` 覆盖。

4. **端口不通 / 服务未启动**

   * 检查应用是否监听 `8080`（或在 Jib 配置中修改端口），并确认运行命令的端口映射。

5. **需要固定标签**

   * 追加：`-Djib.to.tags=latest,build-20251016`

---

## 可选参数速查

* 允许 HTTP 私库：
  `-Djib.allowInsecureRegistries=true -DsendCredentialsOverHttp=true`
* 指定基础镜像与凭据：
  `-Djib.from.image=<REG>/<REPO>:<TAG> -Djib.from.auth.username=... -Djib.from.auth.password=...`
* 指定目标镜像与凭据：
  `-Djib.to.image=<REG>/<REPO>:<TAG> -Djib.to.auth.username=... -Djib.to.auth.password=...`
* 额外标签：
  `-Djib.to.tags=latest,dev`
* 运行端口：
  `-Djib.container.ports=8080`

