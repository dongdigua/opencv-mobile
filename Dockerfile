FROM docker.1ms.run/debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    OPENCV_VERSION=4.13.0 \
    SOURCE_DIR=opencv-mobile-4.13.0 \
    PACKAGE_NAME=opencv-mobile-4.13.0-milkv-duo \
    OPENCV_SOURCE_ARCHIVE=opencv-4.13.0.zip \
    RISCV_TOOLCHAIN_DIR=Xuantie-900-gcc-linux-5.10.4-musl64-x86_64-V2.8.1 \
    RISCV_TOOLCHAIN_ARCHIVE=Xuantie-900-gcc-linux-5.10.4-musl64-x86_64-V2.8.1-20240115.tar.gz \
    RISCV_TOOLCHAIN_ROOT=/opt/Xuantie-900-gcc-linux-5.10.4-musl64-x86_64-V2.8.1 \
    BUILD_ROOT=/tmp/opencv-mobile-build

RUN sed -i 's#https\?://deb.debian.org#http://mirrors.tuna.tsinghua.edu.cn#g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y bash ca-certificates cmake patch unzip wget xz-utils zip \
    && rm -rf /var/lib/apt/lists/*


RUN cd /opt \
    && wget -q "https://occ-oss-prod.oss-cn-hangzhou.aliyuncs.com/resource//1705396382457/${RISCV_TOOLCHAIN_ARCHIVE}" \
    && tar -xf "${RISCV_TOOLCHAIN_ARCHIVE}" \
    && rm -f "${RISCV_TOOLCHAIN_ARCHIVE}" \
    && wget -q https://sophon-file.sophon.cn/sophon-prod-s3/drive/23/03/07/16/host-tools.tar.gz \
    && tar -xf host-tools.tar.gz \
    && rm -f host-tools.tar.gz \

WORKDIR /work

CMD set -eux; \
    rm -rf "${BUILD_ROOT}" "/work/build/${PACKAGE_NAME}"; \
    mkdir -p "${BUILD_ROOT}" /work/build; \
    cd "${BUILD_ROOT}"; \
    test -f "/work/${OPENCV_SOURCE_ARCHIVE}"; \
    cp "/work/${OPENCV_SOURCE_ARCHIVE}" ./; \
    unzip -q "${OPENCV_SOURCE_ARCHIVE}"; \
    rm "${OPENCV_SOURCE_ARCHIVE}"; \
    cd "opencv-${OPENCV_VERSION}"; \
    truncate -s 0 cmake/OpenCVFindLibsGrfmt.cmake; \
    rm -rf modules/gapi; \
    truncate -s 0 cmake/platforms/OpenCV-Linux.cmake; \
    rm modules/core/src/cuda_*; \
    rm modules/core/src/direct*; \
    rm modules/core/src/gl_*; \
    rm modules/core/src/intel_gpu_*; \
    rm modules/core/src/ocl*; \
    rm modules/core/src/opengl.cpp; \
    rm modules/core/src/ovx.cpp; \
    rm modules/core/src/umatrix.hpp; \
    rm modules/core/src/va_intel.cpp; \
    rm modules/core/src/va_wrapper.impl.hpp; \
    rm modules/core/include/opencv2/core/cuda*.hpp; \
    rm modules/core/include/opencv2/core/directx.hpp; \
    rm modules/core/include/opencv2/core/ocl*.hpp; \
    rm modules/core/include/opencv2/core/opengl.hpp; \
    rm modules/core/include/opencv2/core/ovx.hpp; \
    rm modules/core/include/opencv2/core/private.cuda.hpp; \
    rm modules/core/include/opencv2/core/va_*.hpp; \
    rm -rf modules/core/include/opencv2/core/cuda; \
    rm -rf modules/core/include/opencv2/core/opencl; \
    rm -rf modules/core/include/opencv2/core/openvx; \
    rm modules/photo/src/denoising.cuda.cpp; \
    rm modules/photo/include/opencv2/photo/cuda.hpp; \
    find modules -type d | xargs -i rm -rf {}/src/cuda; \
    find modules -type d | xargs -i rm -rf {}/src/opencl; \
    find modules -type d | xargs -i rm -rf {}/perf/cuda; \
    find modules -type d | xargs -i rm -rf {}/perf/opencl; \
    find modules -type f | xargs -i sed -i '/opencl_kernels/d' {}; \
    find modules -type f | xargs -i sed -i '/cuda.hpp/d' {}; \
    find modules -type f | xargs -i sed -i '/opengl.hpp/d' {}; \
    find modules -type f | xargs -i sed -i '/ocl_defs.hpp/d' {}; \
    find modules -type f | xargs -i sed -i '/ocl.hpp/d' {}; \
    find modules -type f | xargs -i sed -i '/ovx_defs.hpp/d' {}; \
    find modules -type f | xargs -i sed -i '/ovx.hpp/d' {}; \
    find modules -type f | xargs -i sed -i '/va_intel.hpp/d' {}; \
    patch -p1 -i /work/patches/opencv-${OPENCV_VERSION}-no-gpu.patch; \
    patch -p1 -i /work/patches/opencv-${OPENCV_VERSION}-no-rtti.patch; \
    patch -p1 -i /work/patches/opencv-${OPENCV_VERSION}-no-zlib.patch; \
    patch -p1 -i /work/patches/opencv-${OPENCV_VERSION}-link-openmp.patch; \
    patch -p1 -i /work/patches/opencv-${OPENCV_VERSION}-fix-windows-arm-arch.patch; \
    patch -p1 -i /work/patches/opencv-${OPENCV_VERSION}-minimal-install.patch; \
    cp /work/patches/draw_text.h /work/patches/mono_font_data.h modules/imgproc/src/; \
    cp /work/patches/fontface.html ./; \
    patch -p1 -i /work/patches/opencv-${OPENCV_VERSION}-drawing-mono-font.patch; \
    rm -rf modules/highgui; \
    cp -r /work/highgui modules/; \
    rm -rf 3rdparty; \
    rm -rf apps data doc samples platforms; \
    rm -rf modules/java; \
    rm -rf modules/js; \
    rm -rf modules/python; \
    rm -rf modules/ts; \
    rm -rf modules/dnn; \
    sed -e "s/__VERSION__/${OPENCV_VERSION}/g" /work/patches/Info.plist > ./Info.plist; \
    cp /work/opencv4_cmake_options.txt ./options.txt; \
    cp -r /work/toolchains .; \
    cd ..; \
    mv "opencv-${OPENCV_VERSION}" "${SOURCE_DIR}"; \
    zip -9 -r "${SOURCE_DIR}.zip" "${SOURCE_DIR}"; \
    rm -rf "${SOURCE_DIR}"; \
    unzip -q "${SOURCE_DIR}.zip"; \
    cd "${SOURCE_DIR}"; \
    patch -p1 -i /work/patches/opencv-${OPENCV_VERSION}-no-atomic.patch; \
    mkdir build && cd build; \
    export RISCV_ROOT_PATH="${RISCV_TOOLCHAIN_ROOT}"; \
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=../toolchains/riscv64-unknown-linux-musl.toolchain.cmake \
        -DCMAKE_C_FLAGS="-fno-rtti -fno-exceptions" \
        -DCMAKE_CXX_FLAGS="-fno-rtti -fno-exceptions" \
        -DCMAKE_INSTALL_PREFIX=install \
        -DCMAKE_BUILD_TYPE=Release \
        $(cat ../options.txt) \
        -DBUILD_opencv_world=OFF \
        -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON \
        -DWITH_OPENMP=OFF \
        -DOPENCV_DISABLE_THREAD_SUPPORT=ON \
        -DWITH_CVI=ON \
        -DWITH_HAL_RVV=OFF \
        -DOPENCV_EXTRA_FLAGS="-ggdb -D__riscv_vector_071 -mrvv-vector-bits=128" \
        ..; \
    cmake --build . -j "$(nproc)"; \
    cmake --build . --target install; \
    mkdir -p "/work/build/${PACKAGE_NAME}"; \
    cp -rf install/* "/work/build/${PACKAGE_NAME}/"; \
    rm -rf "${BUILD_ROOT}"