FROM alpine/git:latest AS source

ARG CLOUDFLARED_VERSION

WORKDIR /src

RUN git clone https://github.com/cloudflare/cloudflared.git . && \
    git checkout "tags/${CLOUDFLARED_VERSION}"

FROM golang:1.25 AS builder

ARG TARGETOS
ARG TARGETARCH
ARG CLOUDFLARED_VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0

WORKDIR /build

COPY --from=source /src /build

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -v \
    -mod=vendor \
    -ldflags="-w -s -X main.Version=${CLOUDFLARED_VERSION}" \
    -o /out/cloudflared \
    github.com/cloudflare/cloudflared/cmd/cloudflared


FROM gcr.io/distroless/base-debian11:nonroot

COPY --from=builder /out/cloudflared /usr/local/bin/cloudflared

USER nonroot
ENTRYPOINT ["/usr/local/bin/cloudflared", "--no-autoupdate"]
