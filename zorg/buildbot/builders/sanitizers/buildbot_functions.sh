#!/usr/bin/env bash

function buildbot_update {
    REV_ARG=
    if [ "$BUILDBOT_REVISION" != "" ]; then
        REV_ARG="-r$BUILDBOT_REVISION"
    fi
    if [ -d llvm ]; then
        svn cleanup llvm
    fi
    for subtree in llvm/tools/clang llvm/projects/compiler-rt llvm/projects/libcxx llvm/projects/libcxxabi
    do
      if [ -d ${subtree} ]; then
        svn cleanup "${subtree}"
      fi
    done

    if [ -d llvm -a -d llvm/projects/libcxxabi ]; then
        svn up llvm $REV_ARG
        if [ "$REV_ARG" == "" ]; then
            REV_ARG="-r"$(svn info llvm | grep '^Revision:' | awk '{print $2}')
        fi
        for subtree in llvm/tools/clang llvm/projects/compiler-rt llvm/projects/libcxx llvm/projects/libcxxabi
        do
          svn up "${subtree}" $REV_ARG
        done
    else
        svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm $REV_ARG
        if [ "$REV_ARG" == "" ]; then
            REV_ARG="-r"$(svn info llvm | grep '^Revision:' | awk '{print $2}')
        fi
        svn co http://llvm.org/svn/llvm-project/cfe/trunk llvm/tools/clang $REV_ARG
        svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk llvm/projects/compiler-rt $REV_ARG
        svn co http://llvm.org/svn/llvm-project/libcxx/trunk llvm/projects/libcxx $REV_ARG
        svn co http://llvm.org/svn/llvm-project/libcxxabi/trunk llvm/projects/libcxxabi $REV_ARG
    fi
}

function set_chrome_suid_sandbox {
  export CHROME_DEVEL_SANDBOX=/usr/local/sbin/chrome-devel-sandbox
}

function fetch_depot_tools {
  ROOT=$1
  (
    cd $ROOT
    if [ ! -d depot_tools ]; then
      git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    fi
  )
  export PATH="$ROOT/depot_tools:$PATH"
}

function check_out_chromium {
  CHROME_CHECKOUT=$1
  (
  if [ ! -d $CHROME_CHECKOUT ]; then
    mkdir $CHROME_CHECKOUT
    pushd $CHROME_CHECKOUT
    fetch --nohooks chromium --nosvn=True 

    # Sync to LKGR, see http://crbug.com/109191
    mv .gclient .gclient-tmp
    cat .gclient-tmp  | \
        sed 's/"safesync_url": ""/"safesync_url": "https:\/\/chromium-status.appspot.com\/git-lkgr"/' > .gclient
    rm .gclient-tmp
    popd
  fi
  cd $CHROME_CHECKOUT/src
  git checkout master
  git pull
  gclient sync --nohooks --jobs=16
  )
}

function gclient_runhooks {
  CHROME_CHECKOUT=$1
  CLANG_BUILD=$2
  CUSTOM_GYP_DEFINES=$3
  (
  cd $CHROME_CHECKOUT/src
  
  # Clobber Chromium to catch possible LLVM regressions early.
  rm -rf out/Release
  
  export COMMON_GYP_DEFINES="use_allocator=none use_aura=1 clang_use_chrome_plugins=0 component=static_library"
  export GYP_DEFINES="$CUSTOM_GYP_DEFINES $COMMON_GYP_DEFINES"
  export GYP_GENERATORS=ninja
  export CLANG_BIN=$CLANG_BUILD/bin
  export CC="$CLANG_BIN/clang"
  export CXX="$CLANG_BIN/clang++"
  
  gclient runhooks
  )
}

function build_stage1_clang {
  mkdir -p ${STAGE1_DIR}
  cmake_stage1_options="${CMAKE_COMMON_OPTIONS}"
  (cd ${STAGE1_DIR} && cmake ${cmake_stage1_options} $LLVM && \
    ninja clang compiler-rt llvm-symbolizer)
}

function common_stage2_variables {
  local stage1_clang_path=$ROOT/${STAGE1_DIR}/bin
  cmake_stage2_common_options="\
    ${CMAKE_COMMON_OPTIONS} \
    -DCMAKE_C_COMPILER=${stage1_clang_path}/clang \
    -DCMAKE_CXX_COMPILER=${stage1_clang_path}/clang++ \
    "
  llvm_symbolizer_path=${stage1_clang_path}/llvm-symbolizer
}

function build_stage2_msan {
  echo @@@BUILD_STEP build libcxx/msan@@@
  
  common_stage2_variables
  export MSAN_SYMBOLIZER_PATH="${llvm_symbolizer_path}"
  
  local memory_sanitizer_kind="Memory"
  BUILDBOT_MSAN_ORIGINS=${BUILDBOT_MSAN_ORIGINS:-}
  if [ "$BUILDBOT_MSAN_ORIGINS" != "" ]; then
      memory_sanitizer_kind="MemoryWithOrigins"
  fi

  mkdir -p ${STAGE2_LIBCXX_MSAN_DIR}
  (cd ${STAGE2_LIBCXX_MSAN_DIR} && \
    cmake \
      ${cmake_stage2_common_options} \
      -DLLVM_USE_SANITIZER=${memory_sanitizer_kind} \
      $LLVM && \
    ninja cxx cxxabi) || echo @@@STEP_FAILURE@@@

  echo @@@BUILD_STEP build clang/msan@@@

  local msan_ldflags="-lc++abi -Wl,--rpath=${ROOT}/${STAGE2_LIBCXX_MSAN_DIR}/lib -L${ROOT}/${STAGE2_LIBCXX_MSAN_DIR}/lib"
  # See http://llvm.org/bugs/show_bug.cgi?id=19071, http://www.cmake.org/Bug/view.php?id=15264
  local cmake_bug_workaround_cflags="$msan_ldflags -fsanitize=memory -w"
  local msan_cflags="-I${ROOT}/${STAGE2_LIBCXX_MSAN_DIR}/include -I${ROOT}/${STAGE2_LIBCXX_MSAN_DIR}/include/c++/v1 $cmake_bug_workaround_cflags"
  mkdir -p ${STAGE2_MSAN_DIR}
  (cd ${STAGE2_MSAN_DIR} && \
   cmake ${cmake_stage2_common_options} \
     -DLLVM_USE_SANITIZER=${memory_sanitizer_kind} \
     -DLLVM_ENABLE_LIBCXX=ON \
     -DCMAKE_C_FLAGS="${msan_cflags}" \
     -DCMAKE_CXX_FLAGS="${msan_cflags}" \
     -DCMAKE_EXE_LINKER_FLAGS="${msan_ldflags}" \
     $LLVM && \
   ninja clang) || echo @@@STEP_FAILURE@@@
}

function build_stage2_asan {
  echo @@@BUILD_STEP build clang/asan@@@

  common_stage2_variables
  # Turn on init-order checker as ASan runtime option.
  export ASAN_SYMBOLIZER_PATH="${llvm_symbolizer_path}"
  export ASAN_OPTIONS="check_initialization_order=true:detect_stack_use_after_return=1:detect_leaks=1"
  local cmake_asan_options=" \
    ${cmake_stage2_common_options} \
    -DLLVM_USE_SANITIZER=Address \
    "
  mkdir -p ${STAGE2_ASAN_DIR}
  (cd ${STAGE2_ASAN_DIR} && \
   cmake ${cmake_asan_options} $LLVM && \
   ninja clang) || echo @@@STEP_FAILURE@@@
}

function build_stage2_ubsan {
  echo @@@BUILD_STEP build clang/ubsan@@@

  common_stage2_variables
  export UBSAN_OPTIONS="external_symbolizer_path=${llvm_symbolizer_path}:print_stacktrace=1"
  local cmake_ubsan_options=" \
    ${cmake_stage2_common_options} \
    -DCMAKE_BUILD_TYPE=Debug \
    -DLLVM_USE_SANITIZER=Undefined \
    "
  mkdir -p ${STAGE2_UBSAN_DIR}
  (cd ${STAGE2_UBSAN_DIR} &&
    cmake ${cmake_ubsan_options} $LLVM && \
    ninja clang) || echo @@@STEP_FAILURE@@@
}

function check_stage2 {
  local sanitizer_name=$1
  local build_dir=$2
  echo @@@BUILD_STEP check-llvm ${sanitizer_name}@@@

  (cd ${build_dir} && ninja check-llvm) || echo @@@STEP_WARNINGS@@@

  echo @@@BUILD_STEP check-clang ${sanitizer_name}@@@

  (cd ${build_dir} && ninja check-clang) || echo @@@STEP_FAILURE@@@
}

function check_stage2_msan {
  check_stage2 msan "${STAGE2_MSAN_DIR}"
}

function check_stage2_asan {
  check_stage2 asan "${STAGE2_ASAN_DIR}"
}

function check_stage2_ubsan {
  check_stage2 ubsan "${STAGE2_UBSAN_DIR}"
}
