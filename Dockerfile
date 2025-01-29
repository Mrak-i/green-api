# Используем официальный образ Nginx
FROM nginx:alpine

# Создаём директорию
RUN mkdir -p /etc/nginx/certs

# Создаем нового пользователя и группу
RUN addgroup -g 1000 nonroot && adduser -u 1000 -G nonroot -D -H -s /bin/sh nonroot

# Меняем владельца директорий на нового пользователя
RUN chown -R nonroot:nonroot /usr/share/nginx/html /etc/nginx/conf.d /etc/nginx/certs

# Генерируем самоподписанный сертификат
RUN --mount=type=secret,id=private_key,env=PRIVATE_KEY && --mount=type=secret,id=certificate,env=CERTIFICATE
RUN cat /run/secrets/private_key > /etc/nginx/certs/server.key && cat /run/secrets/certificate > /etc/nginx/certs/server.crt

# Копируем содержимое проекта в корень веб-сервера Nginx
COPY ./ /usr/share/nginx/html

# Создаем файл nginx.conf
RUN echo 'server {\
    listen 80;\
    server_name localhost;\
    return 301 https://$host$request_uri;\
}\
\
server {\
    listen 443 ssl;\
    server_name localhost;\
    ssl_certificate /etc/nginx/certs/server.crt;\
    ssl_certificate_key /etc/nginx/certs/server.key;\
    root /usr/share/nginx/html;\
    index index.html;\
}' > /etc/nginx/conf.d/default.conf

# Указываем, какие порты будут использоваться
EXPOSE 80 443

# Переходим на нового пользователя перед запуском Nginx
USER nonroot

CMD ["nginx", "-g", "daemon off;"]
