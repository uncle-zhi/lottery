#构建
docker build -f ./Dockerfile -t lottery-backend ../

#启动容器
docker run -d -p 8080:8080 lottery-backend