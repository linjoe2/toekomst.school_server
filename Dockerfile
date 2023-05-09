FROM heroiclabs/nakama-pluginbuilder:3.12.0 AS go-builder

ENV GO111MODULE on
ENV CGO_ENABLED 1

WORKDIR /backend

COPY go.mod .
COPY main.go .
COPY credentials ./credentials

COPY vendor/ vendor/
RUN go build --trimpath --mod=mod --buildmode=plugin -o ./backend.so


FROM heroiclabs/nakama:3.12.0
run mkdir /root/.aws
COPY credentials /root/.aws/credentials
COPY build/index.js /nakama/data/modules

COPY --from=go-builder /backend/backend.so /nakama/data/modules/
COPY local.yml /nakama/data/


ENV TZ=Europe/Amsterdam
