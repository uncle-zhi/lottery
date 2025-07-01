# 构建镜像
docker build -t lottery-dapp ../

# 运行容器
docker run -d -p 8080:80 --name vue-app lottery-dapp
