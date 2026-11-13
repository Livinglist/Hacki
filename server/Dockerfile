FROM golang:1.27-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/hacki-server ./cmd/hacki-server \
    && mkdir /data

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/hacki-server /hacki-server
COPY --from=build --chown=65532:65532 /data /data
ENV HACKI_LISTEN_ADDR=0.0.0.0:8080 \
    HACKI_CACHE_PATH=/data/cache.sqlite \
    HACKI_CACHE_TTL=30m
WORKDIR /data
USER 65532:65532
EXPOSE 8080
VOLUME ["/data"]
ENTRYPOINT ["/hacki-server"]
