# phron-net/api

The public [Phron](https://phron.net) API: the Protocol Buffers definitions of the
Servers and Object Storage services, and a generated Go client for them
([ConnectRPC](https://connectrpc.com)).

| Service | Purpose |
| --- | --- |
| `zonhoren.phron.v1.ServerService` | Servers: create, resize, power, firewall, SSH keys, backups and snapshots, traffic |
| `zonhoren.phron.v1.StorageService` | Object Storage: buckets, access keys, bucket limits |

The API is served at `https://api.phron.net`. A call is an HTTPS `POST` to
`https://api.phron.net/zonhoren.phron.v1.<Service>/<Method>` with
`Authorization: Bearer <access token>`.

The Protocol Buffers package is `zonhoren.phron.v1`. The name is part of the URL
path and the wire format, so it stays as it is.

## Layout

- `proto/zonhoren/phron/v1/`: the `.proto` sources.
- `gen/zonhoren/phron/v1/`: generated Go messages (package `phronv1`).
- `gen/zonhoren/phron/v1/phronv1connect/`: generated ConnectRPC clients and server handlers.

## Using it from Go

```sh
go get github.com/phron-net/api
```

Authenticate as an API client of your Organization with the OAuth 2.0
client-credentials grant, then send the access token as a bearer token. The
token endpoint and scope for your Organization are shown on the API clients page
of the Phron console.

```go
package main

import (
	"context"
	"fmt"
	"net/http"

	"connectrpc.com/connect"

	phronv1 "github.com/phron-net/api/gen/zonhoren/phron/v1"
	"github.com/phron-net/api/gen/zonhoren/phron/v1/phronv1connect"
)

func bearer(token string) connect.Interceptor {
	return connect.UnaryInterceptorFunc(func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			req.Header().Set("Authorization", "Bearer "+token)
			return next(ctx, req)
		}
	})
}

func main() {
	token := "..." // from the client-credentials grant
	servers := phronv1connect.NewServerServiceClient(
		http.DefaultClient,
		"https://api.phron.net",
		connect.WithInterceptors(bearer(token)),
	)
	res, err := servers.ListServers(context.Background(),
		connect.NewRequest(&phronv1.ListServersRequest{}))
	if err != nil {
		panic(err)
	}
	for _, s := range res.Msg.Servers {
		fmt.Println(s.Id, s.Name, s.State)
	}
}
```

`phronv1connect.NewStorageServiceClient` works the same way. Access tokens are
short-lived: fetch a new one when it expires (for example with
`golang.org/x/oauth2/clientcredentials`).

## Maintaining this repository

The Go code in `gen/` is checked in so that `go get` works, and is generated from
`proto/` by [buf](https://buf.build) with locally installed, pinned plugins
(`protoc-gen-go` and `protoc-gen-connect-go`, versions in `scripts/tools.env`).
Nothing is sent to a hosted generator.

- `ci` (push to `main`, pull requests) lints the protos, regenerates, fails if
  `gen/`, `go.mod` or `go.sum` differ from what is committed, then runs
  `go vet ./...` and `go build ./...`.
- Regenerating: the generators are not run on developer workstations. Push a
  branch named `regen/<name>` (or dispatch the `regen` workflow); it runs
  `scripts/generate.sh` and prints `gen/`, `go.mod` and `go.sum` as a base64
  tarball in the job log between `-----BEGIN GEN-----` and `-----END GEN-----`.
  Decode it (`base64 -d | tar xz`), compare the printed `sha256`, and commit the
  result.

The `.proto` files are the same contract the service serves. Field names and
numbers never change incompatibly.

## License

Apache License 2.0. See [LICENSE](LICENSE).
