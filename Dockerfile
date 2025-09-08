FROM alpine:3.16

ENV LANG=C.UTF-8

# aws-lambda runtime
RUN apk add --no-cache cmake make gcc g++ git bash zip curl-dev zlib-static libexecinfo-dev opencv-dev

WORKDIR /usr
RUN git clone https://github.com/aws/aws-sdk-cpp.git
RUN cd aws-sdk-cpp && git submodule update --init --recursive && \
    mkdir build && \
    cd build && \
    cmake .. -DBUILD_ONLY="s3" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_TESTING=OFF \
        -DCUSTOM_MEMORY_MANAGEMENT=OFF \
        -DCMAKE_INSTALL_PREFIX=~/install && \
    make && make install

RUN cd /usr && git clone https://github.com/awslabs/aws-lambda-cpp.git
RUN cd aws-lambda-cpp && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_PREFIX=~/install && \
    make && make install

WORKDIR /home
