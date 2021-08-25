---
title: Rust and Go have the same error handling
date: 2021-02-25T10:40:58-04:00
draft: false
---

I've been in a couple of discussions on Discord recently that digress into a
debate on which has the better error handling model, Rust or Go. This is a false
dichotomy, they have the same error model.

Now, I like both languages. I think they both do interesting things and I would
be happy to use either. One thing that I like in both is that they looked at the
current state of error handling in different languages and decided that it
wasn't good enough for them. They decided to step off the beaten path and really
examine the way errors _should_ be handled and came up with a model that they
thought was better.

Fundamentally, they both came up with the same solution. The same semantics.
Instead of having errors be wildcards that could cut across the call stack, they
both decided that instead, errors should be returned directly to the caller and
not break the call stack. That's it, really. Errors are just normal values
returned by the function.

Any differences in how both languages choose to express this idea syntactically
is purely an artifact of each language's compiler and type system. the `Result`
type in Rust is simply the natural point one must arrive to when applying the
idea of "errors as value" to the Rust type system. Returning multiple values,
including an error value, in Go is the natural point one must arrive to when
applying the same concept to Go's compiler and type system.

Any comparison or argument for or against either language's error handling is
actually just a comparison of their type system.
