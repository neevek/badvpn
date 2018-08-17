#!/usr/bin/env bash

if [[ "$NDK" = "" ]]; then
  echo "\$NDK is empty"
  exit 1
fi

SRC_DIR=$(pwd)
API=21

mkdir -p toolchain build
ANDROID_TOOLCHAIN=$SRC_DIR/toolchain/$API
if [[ ! -d $ANDROID_TOOLCHAIN/sysroot ]]; then
  $NDK/build/tools/make-standalone-toolchain.sh \
    --arch=arm \
    --stl=libc++ \
    --install-dir=$ANDROID_TOOLCHAIN \
    --platform=android-$API \
    --force
fi

export SRCDIR=`pwd`
export OUTDIR=`pwd`/build
export CC=$ANDROID_TOOLCHAIN/bin/arm-linux-androideabi-clang
export CXX=$ANDROID_TOOLCHAIN/bin/arm-linux-androideabi-g++
export CFLAGS="-Os -fPIE -I$ANDROID_TOOLCHAIN/sysroot/usr/include"
export LDFLAGS="-pie -fPIE -L$ANDROID_TOOLCHAIN/sysroot/usr/lib"
export ENDIAN="little"
export KERNEL="2.6"

CFLAGS="${CFLAGS} -std=gnu99"
INCLUDES=( "-I${SRCDIR}" "-I${SRCDIR}/lwip/src/include/ipv4" "-I${SRCDIR}/lwip/src/include/ipv6" "-I${SRCDIR}/lwip/src/include" "-I${SRCDIR}/lwip/custom" )
DEFS=( -DBADVPN_THREAD_SAFE=0 -DBADVPN_LINUX -DBADVPN_BREACTOR_BADVPN -D_GNU_SOURCE )

[[ $KERNEL = "2.4" ]] && DEFS=( "${DEFS[@]}" -DBADVPN_USE_SELFPIPE -DBADVPN_USE_POLL ) || DEFS=( "${DEFS[@]}" -DBADVPN_USE_SIGNALFD -DBADVPN_USE_EPOLL )

[[ $ENDIAN = "little" ]] && DEFS=( "${DEFS[@]}" -DBADVPN_LITTLE_ENDIAN ) || DEFS=( "${DEFS[@]}" -DBADVPN_BIG_ENDIAN )

SOURCES="
base/BLog_syslog.c
system/BReactor_badvpn.c
system/BSignal.c
system/BConnection_unix.c
system/BConnection_common.c
system/BTime.c
system/BUnixSignal.c
system/BNetwork.c
system/BDatagram_unix.c
flow/StreamRecvInterface.c
flow/PacketRecvInterface.c
flow/PacketPassInterface.c
flow/StreamPassInterface.c
flow/SinglePacketBuffer.c
flow/BufferWriter.c
flow/PacketBuffer.c
flow/PacketStreamSender.c
flow/PacketPassConnector.c
flow/PacketProtoFlow.c
flow/PacketPassFairQueue.c
flow/PacketProtoEncoder.c
flow/PacketProtoDecoder.c
socksclient/BSocksClient.c
tuntap/BTap.c
lwip/src/core/udp.c
lwip/src/core/memp.c
lwip/src/core/init.c
lwip/src/core/pbuf.c
lwip/src/core/tcp.c
lwip/src/core/tcp_out.c
lwip/src/core/sys.c
lwip/src/core/netif.c
lwip/src/core/def.c
lwip/src/core/mem.c
lwip/src/core/tcp_in.c
lwip/src/core/stats.c
lwip/src/core/ip.c
lwip/src/core/timeouts.c
lwip/src/core/inet_chksum.c
lwip/src/core/ipv4/icmp.c
lwip/src/core/ipv4/ip4.c
lwip/src/core/ipv4/ip4_addr.c
lwip/src/core/ipv4/ip4_frag.c
lwip/src/core/ipv6/ip6.c
lwip/src/core/ipv6/nd6.c
lwip/src/core/ipv6/icmp6.c
lwip/src/core/ipv6/ip6_addr.c
lwip/src/core/ipv6/ip6_frag.c
lwip/custom/sys.c
tun2socks/tun2socks.c
base/DebugObject.c
base/BLog.c
base/BPending.c
flowextra/PacketPassInactivityMonitor.c
tun2socks/SocksUdpGwClient.c
udpgw_client/UdpGwClient.c
libancillary/fd_send.c
libancillary/fd_recv.c
libancillary/unix_sock_ancil.c
"

set -e
set -x

OBJS=()
for f in $SOURCES; do
    obj=${f//\//_}.o
    "${CC}" -c ${CFLAGS} "${INCLUDES[@]}" "${DEFS[@]}" "${SRCDIR}/${f}" -o "${obj}"
    OBJS=( "${OBJS[@]}" "${obj}" )
done

"${CC}" ${LDFLAGS} "${OBJS[@]}" -o $OUTDIR/tun2socks -pthread
