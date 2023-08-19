---
title: "instrumenting async Go functions with OpenTelemetry"
date: 2023-08-19 12:14:00-0400
draft: true
---

This is a problem that is deceivingly easy, but contains a few gotchas.
Let's take a simple example: an HTTP server handler that performs a simple
task, and performs another async task at the same time. Could be anything,
writing to cache, sending a notification to an email service, whatever.

```go
package main

import (
    "fmt"
    "net/http"
    "time"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))

        go func() {
            time.Sleep(5*time.Second)
        }()
    })

    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

## Initial OpenTelemetry setup

TODO
