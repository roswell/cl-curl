FROM alpine:3.18

WORKDIR /tmp

RUN apk add --no-cache ca-certificates curl openssl make gcc musl-dev linux-headers gnupg patch zlib-dev zlib-static git sbcl
RUN set -x \
    # I frequently build arm executables on an arm64 computer. Need to add this
    # otherwise SBCL can get confused
    && case "$(cat /etc/apk/arch)" in \
         armv7) SBCL_ARCH=arm;; \
         aarch64) SBCL_ARCH=arm64;; \
         x86_64) SBCL_ARCH=x86-64;; \
         *) echo "Unknown arch" >&2; exit 1;; \
       esac \
    && export SBCL_ARCH

RUN set -x \
    && git clone --depth=1 --branch static-executable-v2-2.2.0 https://github.com/daewok/sbcl.git \
    && mv sbcl sbcl- \
    && cd /tmp/sbcl- \
    && echo '"2.2.0-static-curl"' > version.lisp-expr \
    && sed -i -e 's/"--help"/"--runtime-help"/g' -e 's/"--version"/"--runtime-version"/g' src/runtime/runtime.c \
    && sed -i -e 's/"--help"/"--runtime-help"/g' -e 's/"--version"/"--runtime-version"/g' src/code/toplevel.lisp \
    && sed -i -e "s/CFLAGS += -marm -march=armv5/CFLAGS += -marm/" src/runtime/Config.arm-linux \
    && sh make.sh --fancy --with-sb-linkable-runtime --with-sb-prelink-linkage-table \
    && sh install.sh

RUN set -x \
    && apk add --no-cache curl-dev curl-static nghttp2-static openssl-libs-static brotli-static zlib-static libidn2-static \
    && curl -O https://beta.quicklisp.org/quicklisp.lisp \
    && sbcl --load quicklisp.lisp --eval '(quicklisp-quickstart:install)' --eval '(quit)' \
    && git clone https://github.com/roswell/cl-curl.git ~/quicklisp/local-projects/roswell/cl-curl \
    && sbcl --load ~/quicklisp/setup.lisp \
            --eval "(ql:quickload :cl-curl)" \
            --eval "(cl-curl:init)" \
            --load /tmp/sbcl-/tools-for-build/dump-linkage-info.lisp \
            --eval '(sb-dump-linkage-info:dump-to-file "/tmp/linkage-info.sexp")' \
    && sbcl --load ~/quicklisp/setup.lisp \
            --eval "(ql:quickload :cl-curl)" \
            --eval '(sb-ext:save-lisp-and-die "/tmp/sb-curl.core")'

RUN set -x \
    && apk add --no-cache libunistring-static \
    && sbcl --script /tmp/sbcl-/tools-for-build/create-linkage-table-prelink-info-override.lisp \
            /tmp/linkage-info.sexp \
            /tmp/linkage-table-prelink-info-override.c \
    && while read l; do \
         eval "${l%%=*}=\"${l#*=}\""; \
       done < /usr/local/lib/sbcl/sbcl.mk \
    && $CC $CFLAGS -Wno-builtin-declaration-mismatch -o /tmp/linkage-table-prelink-info-override.o -c /tmp/linkage-table-prelink-info-override.c \
    && cd /usr/local/lib/sbcl; \
       $CC -no-pie -static $LINKFLAGS -o /tmp/static-sbcl $LIBSBCL /tmp/linkage-table-prelink-info-override.o --static -static-libgcc -static-libstdc++ \
           -static -lcurl -lnghttp2 -lssl -lcrypto -lz -lbrotlidec -lbrotlicommon -lidn2 -lunistring

RUN set -x \
    && /tmp/static-sbcl \
       --core /tmp/sb-curl.core \
       --non-interactive \
       --eval '(sb-ext:save-lisp-and-die "/tmp/sbcl" :executable t :compression t)'
