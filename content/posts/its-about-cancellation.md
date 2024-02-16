---
title: It's All About Cancellation
draft: false
date: 2024-02-16
---

Asynchronous vs synchronous programming is a hot topic these days, and arguably
always was. We talk about things like [function coloring][1] and [argue][2]
[over][3] [async][4] implementations left and right. We fight over whether the
best way to deal with asynchronous code is to make `await` a keyword to slap in
front of a function or a sort of method attached to a Future or Promise or to
simply not have any distinction and let the caller decide (think Goroutines).

What's almost always left out of those conversations is the fact that
asynchronous code is just plain different than synchronous code. It behaves
differently. As soon as you make a function asynchronous, you now have to
contend with the everything that comes with that choice. What happens if the
program needs to exit while the asynchronous function runs? What if we want to
make sure that it won't run forever without ever stopping?

Take Go for example, a language where functions may be asynchronous under the
hood without the caller having to even know about it. If, like me, you've spent
any amount of time working with Go, you've likely noticed that code that depends
on asynchronous behavior is littered with `context.Context`, and for good
reason: We want to stop ongoing tasks when the program receives the SIGTERM
signal, or we want to stop waiting for a response after some timeout.

That's cancellation for you. Cancellation is _table stake_ when it comes to
asynchronous programming. And at the end of the day, no matter what language you
use, or the features that it has, or however much it "colors" its concurrent
functions, you _will_ have to deal with this gnarly, complicated, tedious stuff.

Asynchronous programming is inherently different, let's stop pretending it
isn't. Futures (or Promises) are hard, because _concurrency_ is hard.

[1]: https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/
[2]: https://bitbashing.io/async-rust.html
[3]: https://without.boats/blog/why-async-rust/
[4]: https://www.reddit.com/r/rust/comments/16kzqpi/why_is_async_code_in_rust_considered_especially/

