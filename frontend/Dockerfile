FROM oven/bun:1 as build

WORKDIR /app
COPY package.json /app/

RUN bun install

COPY . /app/

RUN bun run build

FROM nginx:1.19-alpine

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

