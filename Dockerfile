FROM erlang:20-alpine as builder

RUN apk update && apk add make g++

RUN mkdir /arweave
WORKDIR /arweave

COPY Makefile .
COPY Emakefile .
ADD lib lib
ADD src src

# E.g. "-DTARGET_TIME=5 -DRETARGET_BLOCKS=10" or "-DFIXED_DIFF=2"
ARG ERLC_OPTS

RUN make all

FROM erlang:20-alpine

# install coreutils in order to support diskmon's shell command: /bin/df -lk
# since BusyBox's df does not support that option
RUN apk update && apk add coreutils libstdc++

RUN mkdir /arweave
WORKDIR /arweave

COPY arweave-server .
COPY data data
COPY --from=builder /arweave/priv priv
COPY --from=builder /arweave/ebin ebin
COPY --from=builder /arweave/src/av/sigs src/av/sigs
COPY --from=builder /arweave/lib/prometheus/_build/default/lib/prometheus/ebin \
            lib/prometheus/_build/default/lib/prometheus/ebin
COPY --from=builder /arweave/lib/accept/_build/default/lib/accept/ebin \
            lib/accept/_build/default/lib/accept/ebin
COPY --from=builder /arweave/lib/prometheus_process_collector/_build/default/lib/prometheus_process_collector/ebin \
            lib/prometheus_process_collector/_build/default/lib/prometheus_process_collector/ebin

EXPOSE 1984
ENTRYPOINT ["./arweave-server"]
