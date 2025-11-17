FROM cgr.dev/chainguard/wolfi-base

LABEL maintainer="maintainers@indieweb2.gitlab"
LABEL version="0.1.0"

RUN apk add --no-cache deno ipfs

WORKDIR /app
COPY . /app

CMD ["deno", "task", "start"]
