FROM golang:1.23.1-alpine3.20

WORKDIR /app

COPY go.mod go.sum ./

RUN apk add build-base

RUN go mod download

COPY files/ ./files
COPY assets/ ./assets
COPY views/ ./views
COPY main.go ./

RUN CGO_ENABLED=1 GOOS=linux go build -o filemyst

EXPOSE 8080
CMD ["./filemyst"]
