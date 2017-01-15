package main

import (
	"flag"
	"log"

	"github.com/valyala/fasthttp"
)

// BAZINGA BAZINGA!
const BAZINGA = "Bazinga!"

var (
	// version is a variable set while build to a known git branch and timestamp.
	version string
	// listener is the host:port to listen to
	listenAddr = flag.String("listener", ":8080", "host listener <host>:<port> (default :8080)")
	// enable compression
	compress = flag.Bool("compress", false, "enable compression (default: false)")
)

func main() {
	// parse given flags
	flag.Parse()

	// Run the daemon, we are in the psudo main loop
	run()
}

// Frun represents the main run loop
func run() {

	// create request handler
	h := requestHandler
	if *compress {
		h = fasthttp.CompressHandler(h)
	}

	// check if listener is configured
	if len(*listenAddr) > 0 {

		if err := fasthttp.ListenAndServe(*listenAddr, h); err != nil {
			log.Fatalf("Error: %s", err)
		}

	}

	// wait forever
	select {}

}

// FrequestHandler is the main handler passed to fasthttp
func requestHandler(ctx *fasthttp.RequestCtx) {
	// Logger may be cached in local variables.
	logger := ctx.Logger()

	logger.Printf("%s", ctx.Request.Header.UserAgent())

	switch string(ctx.Path()) {
	default:
		defaultHandler(ctx)
	}
}

// FgraphqlHandler is GraphQL request handler
func graphqlHandler(ctx *fasthttp.RequestCtx) {

}

// FdefaultHandler is the default request handler
func defaultHandler(ctx *fasthttp.RequestCtx) {
	ctx.Error(BAZINGA, fasthttp.StatusNotFound)
}
