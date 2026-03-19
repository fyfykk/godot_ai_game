import argparse
import http.server
import os
import ssl


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("--dir", required=True)
	parser.add_argument("--cert", required=True)
	parser.add_argument("--key", required=True)
	parser.add_argument("--port", type=int, default=8443)
	args = parser.parse_args()

	os.chdir(args.dir)
	handler = http.server.SimpleHTTPRequestHandler
	server = http.server.ThreadingHTTPServer(("0.0.0.0", args.port), handler)
	context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
	context.load_cert_chain(certfile=args.cert, keyfile=args.key)
	server.socket = context.wrap_socket(server.socket, server_side=True)
	server.serve_forever()


if __name__ == "__main__":
	main()
