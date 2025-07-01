# 第一阶段：用 Maven 镜像构建项目
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# 先只复制pom.xml和相关文件，下载依赖缓存
COPY pom.xml .
# 如果有父模块或者多个模块，可以COPY对应的pom.xml文件
RUN mvn dependency:go-offline -B

# 复制源码
COPY src ./src

# 打包跳过测试
RUN mvn clean package -DskipTests

# 第二阶段：运行阶段，使用轻量JRE镜像
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# 复制构建好的jar包
COPY --from=builder /app/target/*.jar app.jar

# 暴露端口（根据项目实际端口调整）
EXPOSE 8080

# 运行命令
ENTRYPOINT ["java","-jar","app.jar"]
