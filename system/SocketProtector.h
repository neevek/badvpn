#ifndef SOCKETPROTECTOR_H_
#define SOCKETPROTECTOR_H_

#ifdef PROTECT_SOCKET
#include <sys/socket.h>
#include <tun2socks/tun2socks_api.h>
typedef int(*SocketFun)(int domain, int type, int protocol);
typedef int(*ProtectSocketFun)(int sock);
static const SocketFun _socket_fun = socket;
extern const SocketProtector *_socket_protector;
#define socket(domain, type, protocol) \
  _socket_protector ? \
  _socket_protector->protect(_socket_fun(domain, type, protocol), _socket_protector->context) : \
  _socket_fun(domain, type, protocol)
#endif

#endif /* end of include guard: SOCKETPROTECTOR_H_ */
