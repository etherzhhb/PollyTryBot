#!/usr/bin/env bash

set -x
set -e
set -u

echo @@@BUILD_STEP tsan build debug-clang@@@
make -f Makefile.old clean
make -f Makefile.old DEBUG=1 CC=clang CXX=clang++

echo @@@BUILD_STEP tsan test debug-clang@@@
./tsan_test

echo @@@BUILD_STEP tsan stats/output@@@
make -f Makefile.old clean
make -f Makefile.old DEBUG=1 CC=clang CXX=clang++ CFLAGS="-DTSAN_COLLECT_STATS=1 -DTSAN_DEBUG_OUTPUT=2"

echo @@@BUILD_STEP tsan build SHADOW_COUNT=4@@@
make -f Makefile.old clean
make -f Makefile.old DEBUG=1 CC=clang CXX=clang++ CFLAGS=-DTSAN_SHADOW_COUNT=4

echo @@@BUILD_STEP tsan test SHADOW_COUNT=4@@@
./tsan_test

echo @@@BUILD_STEP tsan build SHADOW_COUNT=2@@@
make -f Makefile.old clean
make -f Makefile.old DEBUG=1 CC=clang CXX=clang++ CFLAGS=-DTSAN_SHADOW_COUNT=2

echo @@@BUILD_STEP tsan test SHADOW_COUNT=2@@@
./tsan_test

echo @@@BUILD_STEP tsan build release-gcc@@@
make -f Makefile.old clean
make -f Makefile.old DEBUG=0 CC=gcc CXX=g++

echo @@@BUILD_STEP tsan test release-gcc@@@
./tsan_test

echo @@@BUILD_STEP tsan output_tests@@@
(cd ../../test/tsan && ./test_output.sh)

echo @@@BUILD_STEP tsan analyze@@@
./check_analyze.sh

echo @@@BUILD_STEP tsan Go runtime@@@
(cd go && ./buildgo.sh)

echo @@@BUILD_STEP tsan racecheck_unittest@@@
TSAN_PATH=`pwd`
LIBTSAN_A=$TSAN_PATH/rtl/libtsan.a
SUPPRESS_WARNINGS="-Wno-format-security -Wno-null-dereference -Wno-unused-private-field"
EXTRA_COMPILER_FLAGS="-fsanitize=thread -DTHREAD_SANITIZER -fPIC -g -O2 $SUPPRESS_WARNINGS"
(cd $RACECHECK_UNITTEST_PATH && \
make clean && \
OMIT_DYNAMIC_ANNOTATIONS_IMPL=1 make l64 -j16 CC=clang CXX=clang++ LDOPT="-pie -Wl,--whole-archive $LIBTSAN_A -Wl,--no-whole-archive -ldl" OMIT_CPP0X=1 EXTRA_CFLAGS="$EXTRA_COMPILER_FLAGS" EXTRA_CXXFLAGS="$EXTRA_COMPILER_FLAGS" && \
bin/racecheck_unittest-linux-amd64-O0 --gtest_filter=-*Ignore*:*Suppress*:*EnableRaceDetectionTest*:*Rep*Test*:*NotPhb*:*Barrier*:*Death*:*PositiveTests_RaceInSignal*:StressTests.FlushStateTest:*Mmap84GTest:*.LibcStringFunctions:LockTests.UnlockingALockHeldByAnotherThread:LockTests.UnlockTwice:PrintfTests.RaceOnPutsArgument)

#Ignore: ignores do not work yet
#Suppress: suppressions do not work yet
#EnableRaceDetectionTest: the annotation is not supported
#Rep*Test: uses inline assembly
#NotPhb: not-phb is not supported
#Barrier: pthread_barrier_t is not fully supported yet
#Death: there is some flakyness
#PositiveTests_RaceInSignal: signal() is not intercepted yet
#StressTests.FlushStateTest: uses suppressions
#Mmap84GTest: too slow, causes paging
#LockTests.UnlockingALockHeldByAnotherThread: causes tsan report and non-zero exit code
#LockTests.UnlockTwice: causes tsan report and non-zero exit code
#PrintfTests.RaceOnPutsArgument: seems to be an issue with tsan shadow eviction, lit tests contain a similar test and it passes

