FROM docker.io/golang:latest AS build

ADD https://github.com/pocketbase/pocketbase.git#v0.29.2 /build

# use our slightly modified github oauth-provider file, which doesn't request the users email
COPY github.go /build/tools/auth/github.go

WORKDIR /build/examples/base
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -ldflags='-s -w' -trimpath -o /build/app/pocketbase

WORKDIR /build/app
# Copy all needed libraries of the executables to current dir.. (Copied from:   https://blog.2read.net/posts/building-a-minimalist-docker-container-with-alpine-linux-and-golang/)
RUN ldd pocketbase | tr -s [:blank:] '\n' | grep ^/ | xargs -I % install -D % ./%
RUN mkdir pb_public pb_data pb_migrations


FROM scratch
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=build /build/app .

CMD ["/pocketbase", "serve", "--http", "0.0.0.0:8090"]
