FROM alpine:3.6

ARG LUA_VER="5.1.5"
ARG LUA_ROCKS_VER="3.0.0"

RUN apk add --update ncurses-libs
# required packages to build lua and run luarocks
RUN apk add libc-dev readline readline-dev gcc make wget ncurses-libs ncurses-dev openssl-dev

# install lua
RUN cd /tmp \
    && wget --no-check-certificate https://www.lua.org/ftp/lua-${LUA_VER}.tar.gz \
    && tar zxf lua-${LUA_VER}.tar.gz \
    && cd lua-${LUA_VER} \
    && make linux install \
    && cd /tmp \
    && rm -rf /tmp/*

# install luarocks
RUN cd /tmp \
    && wget --no-check-certificate https://luarocks.org/releases/luarocks-${LUA_ROCKS_VER}.tar.gz \
    && tar zxf luarocks-${LUA_ROCKS_VER}.tar.gz \
    && cd luarocks-${LUA_ROCKS_VER} \
    && ./configure \
    && make build \
    && make install \
    && cd /tmp \
    && rm -rf /tmp/*

COPY md5sum /usr/bin

RUN  luarocks install luasocket
RUN  luarocks install penlight
# RUN  luarocks install binser

# Lab open ports
EXPOSE 5500 5501 5502 5503 5504 5505 5506 5507 5508 5509

COPY entrypoint.sh /

WORKDIR /src

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "main.lua" ]