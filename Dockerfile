FROM alpine:3.16

# docker build -t zig-container .
# docker run --rm -it zig-container /bin/sh

ARG ZIG_VERSION=0.13.0
ARG ZIG_URL=https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz
ARG ZIG_SHA256=d45312e61ebcc48032b77bc4cf7fd6915c11fa16e4aad116b66c9468211230ea

WORKDIR /usr/src

COPY zig-manager /usr/local/bin/zig-manager

RUN chmod +x /usr/local/bin/zig-manager

RUN set -ex \
	&& /usr/local/bin/zig-manager fetch "$ZIG_URL" "$ZIG_SHA256" \
	&& /usr/local/bin/zig-manager extract

ENV PATH="/usr/local/bin/zig:${PATH}"

WORKDIR /app

COPY . .

CMD ["/bin/sh"]