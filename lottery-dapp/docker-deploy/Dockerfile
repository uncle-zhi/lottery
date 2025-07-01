# 使用官方 Node 镜像作为构建阶段
FROM node:20-alpine AS build

# 设置工作目录
WORKDIR /app

# 拷贝 package.json 和 lock 文件
COPY package*.json ./

# 安装依赖
RUN npm install

# 拷贝项目源代码
COPY . .

# 构建项目
RUN npm run build

# 使用 nginx 提供静态服务
FROM nginx:stable-alpine AS production

# 删除默认配置
RUN rm -rf /etc/nginx/conf.d/default.conf

# 复制自定义 nginx 配置（如果有）
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 复制构建好的静态文件
COPY --from=build /app/dist /usr/share/nginx/html

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
