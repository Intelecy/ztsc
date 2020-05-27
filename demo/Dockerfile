FROM golang:1.14-alpine as builder

WORKDIR /go/src/app/

COPY go.* main.go /go/src/app/

RUN go build -o ztsc-demo-service main.go

FROM alpine:3.11

COPY --from=builder /go/src/app/ztsc-demo-service /usr/local/bin

ENTRYPOINT ["ztsc-demo-service"]
