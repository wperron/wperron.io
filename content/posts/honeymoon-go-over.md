---
date: 2022-12-26 15:18:00
author: William Perron
draft: false
title: My Honeymoon With Go Is Over
---

I first got into Go after gravitating around Node.js for a while and I have to
say: It was a breath of fresh air. It fixed most of the issues I had with
asynchronous code, and it did away with all the fluff, keeping the language
simple. I loved it. I loved how simple and predictable it was. And I still do!

I'm just done pretending like it's perfect. Since then I've explored a lot of
other things. I got into Deno. I got into Rust. I expanded my horizons. And
coming back to Go after that, just brought all of its quirks to the surface.
It's not the perfect language that I was sold. It's strongly typed... Except for
the cases where you can totally get around the type system. We don't have Enums
because we have `iota`... Except that makes it unnecessarily painful to deal
with. There's plenty of opportunity for nil pointer exceptions, in fact, a lot
of code out there is susceptible to nil pointer exceptions, but those aren't
checked because we made a pinky promise that if there's no error present, the
pointer _has_ to be valid... But the compiler doesn't provide such guarantee.

I still really like Go though. I don't want this to be a Go-bashing post. I feel
very productive in Go, it has an amazing green thread runtime, the GC is pretty
darn good and the async primitives are very nice to use. All-in-all it's still a
great language, one that I'll keep using in the future. I've just taken off my
pink-tinted glasses.
