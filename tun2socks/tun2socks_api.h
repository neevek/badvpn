#ifndef TUN2SOCKS_API_H_
#define TUN2SOCKS_API_H_
#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  int(*protect)(int sock, void *context);
  void *context;
} SocketProtector;

extern int start_tun2socks(
  int argc, char **argv, const SocketProtector *sock_protector);
extern void shutdown_tun2socks();

#ifdef __cplusplus
}
#endif
#endif /* end of include guard: TUN2SOCKS_API_H_ */
