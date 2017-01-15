# cwd
CWD :=  $(shell cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

# environment
export GOPATH := $(CWD)
export PATH := $(GOPATH)/bin:$(PATH)
export GO15VENDOREXPERIMENT := 1 # care for Go1.5

# build information
BRANCH 	:= $(shell git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
SHA 	:= $(shell git rev-parse --short HEAD)

# version
VERSION := $(BRANCH).$(shell date -u +%Y%m%d.%H%M%S)

# flags
COMMON_GO_LDFLAGS 	:= $(GO_LDFLAGS) -X main.version=$(VERSION)
RELEASE_GO_LDFLAGS 	:= $(COMMON_GO_LDFLAGS) -s

all: clean fmt lint build

prepare:
	@for dep in $(shell cd vendor; find * -type d -maxdepth 2 -mindepth 2); do \
      echo "Linking $$dep into $$GOPATH"; \
      rm -rf $$GOPATH/src/$$dep; \
        mkdir -p $$GOPATH/src/$${dep%/*}; \
        ln -fs $(shell pwd)/vendor/$$dep $$GOPATH/src/$$dep; \
    done

build: prepare
	CGO_ENABLED=0 go build $(GO_BUILD_FLAGS) -installsuffix cgo -ldflags "$(COMMON_GO_LDFLAGS)" -o bin/httpd ./src/cmd/httpd

release: deps prepare
	CGO_ENABLED=0 go build $(GO_BUILD_FLAGS) -installsuffix cgo -ldflags "$(RELEASE_GO_LDFLAGS)" -o bin/httpd ./src/cmd/httpd
	
	$(MAKE) clean_deps

dockerize: deps prepare
	CGO_ENABLED=0 GOOS=linux go build -a $(GO_BUILD_FLAGS) -installsuffix cgo -ldflags "$(RELEASE_GO_LDFLAGS)" -o bin/httpd ./src/cmd/httpd

	docker build -t go-scratch -f Dockerfile .

assets:
	go generate ./src/...

lint:
	golint ./src/...

fmt:
	go fmt ./src/...

test: gotest

gotest:
	go test -v ./src/...

run:
	./bin/editord

alltest:
	cd ./test && ./run_test.sh && cd -
	go test -v ./src/...
	go test -v ./test/func_test.go
	cd ./test && ./clean_test.sh && cd -

clean:
	rm -rf ./bin
	# cd ./test && ./clean.sh && cd -

clean_deps:
	# cleaning up source code, and leaving behind binaries...
	rm -rf $(CWD)/src/golang.org
	rm -rf $(CWD)/src/github.com

# helpers

save:
	godep save ./src/...

env:
	printenv | grep 'GO'
	go env

golint:
	golint

gvt:
	gvt

deps:
	gvt restore

# install any go tools we will need for this project
# and then clean up again afterwards, so we just have
# the binaries.
tools:
	go get -u github.com/golang/lint/golint
	go get -u github.com/FiloSottile/gvt
	go get -u github.com/alecthomas/gometalinter
	go get -u golang.org/x/tools/cmd/goimports

	$(MAKE) clean_deps
