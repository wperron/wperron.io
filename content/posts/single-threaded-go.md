---
draft: true
date: 2021-11-11T20:54:20.008Z
title: Can the Go runtime behave like the JavaScript even loop?
---

During a conversation on discord that started with Amos's great [Understanding
Rust futures by going way too deep][1] article where we ended discussing how
various different runties handled concurrent code execution, someone raised the
question: Is it possible to have Go execute on a single operating system thread,
similar to the JavaScript event loop? It hit that as much experience as I have
with Go and how much I've read on the Go runtime, I have never actually tried
that. So that's what I did! Enter an hour of my life that I'll never get back
and I'm not entirely sure what I learned from, but that was fun nonetheless.

## Down the blocking syscall rabbit hole

Our journey begins as all rabbit holes do; On Google. The first thing I did is
search for whether or not it was possible to limit the number of threads used by
the Go runtime. I quickly found [this StackOverflow question][2] that seemed to
be asking exactly what I wanted. The first thing we learn here is that there is
a [runtime.GOMAXPROCS][3] function in the standard library that allows us to
"[set] the maximum number of CPUs that can be executing simultaneously," which
seems like a promising start. The other interesting bit that we learn here is
that the Go runtime won't always start a new OS thread for a goroutine. If you
have spent any number of time with Go and have read a bit on the subject, that
won't necessarily surprise you. If you're curious about this subject, I highly
recomend checking out [this blog post by Dave Cheney on goroutines][4], it's a
great read. What _was_ new to me however is that there seems to be a heuristic
whereby the Go runtime _will_ open a new OS thread if all current threads are
_blocked,_ for example because they are executing a _blocking system call._

Here I took a little detour to find myself a system call that would block the
calling thread and that I could ideally control how long it blocked for in order
to create the perfect circumstances to force the Go runtime to open a new OS
thread. Normally, when testing asynchronous code execution for these types of
timing questions and inspect runtime behavior, I like to use a sleep function
wrapped in an async function. For example, take the following bit of JavaScript:

```javascript
async function sleep(n) {
  return new Promise((resolve) => {
    setTimeout(() => resolve(), n);
  });
}
```

Go does have a [time.Sleep][5] function, but navigating to [the source code][6]
it doesn't really tell us what it's doing under the hood, so I have no idea if
it's doing a syscall or not. Next I searched specifically for a "sleep syscall"
in Go somewhere and found the [syscall.Nanosleep][7] function. That sounds like
a good start! Except at this point I had to ditch my MacBook in favor of my
Linux desktop because it seems like that syscall doesn't exist on Mac(?) Armed
with my trusty Linux box, it was time to open the manpage for nanosleep. First
thing I see at the top is that nanosleep is in section 2 of the manual
(`nanosleep(2)`) so we know it is indeed a system call, and we get the following
description:

> nanosleep()  suspends the execution of the calling thread until either at
> least the time specified in req has elapsed, or the delivery of a signal that
> triggers the invocation of a handler in the calling thread  or  that
> terminates the process.

So it _is_ a blocking syscall, the quest continues!

Time to start poking at the Go runtime then. I started by writing a super simple
program that just called Nanosleep once, just to run it through strace and see
what happened.

```go
package main

import (
	"fmt"
	"syscall"
	"time"
)

func main() {
	fmt.Println(time.Now())

	if err := syscall.Nanosleep(&syscall.Timespec{
		Sec:  1,
		Nsec: 0,
	}, nil); err != nil {
		panic(err)
	}

	fmt.Println(time.Now())
}
```

Which I then built and ran:

```bash
$ go build -o gst main.go
$ strace ./gst
# Output truncated for brevity
# ...
write(1, "2021-11-12 08:21:04.358043926 -0"..., 552021-11-12 08:21:04.358043926 -0500 EST m=+0.000056067
) = 55
nanosleep({tv_sec=1, tv_nsec=0}, NULL)  = 0
futex(0x538058, FUTEX_WAKE_PRIVATE, 1)  = 1
write(1, "2021-11-12 08:21:05.358406162 -0"..., 552021-11-12 08:21:05.358406162 -0500 EST m=+1.000418343
) = 55
exit_group(0)                           = ?
+++ exited with 0 +++
```

And there, right at the end we can see our program calling into `nanosleep` for
1 second. If you're following along, you will have noticed that there's also a
_lot_ of noise in that strace output because the Go runtime does a bunch of
stuff on startup, so from now on I will be filtering strace to only look at
`nanosleep` syscalls so get a much cleaner output.

```bash
$ strace -e nanosleep ./gst
2021-11-12 08:26:57.879508501 -0500 EST m=+0.000077819
nanosleep({tv_sec=1, tv_nsec=0}, NULL)  = 0
2021-11-12 08:26:58.879807284 -0500 EST m=+1.000376632
+++ exited with 0 +++
```

## Capping the number of available CPUs

Now time to really get to the meat of what we're trying to acheive here.
Remember, the original question was about knowing how the Go runtime would
behave if it was limited to a single operating system thread. So I started by
modifying the program we have right now to start a completely arbitrary number
of goroutines, say 10, that will each call the `nanosleep` syscall to make sure
we're blocking all of these goroutines. This is obviously a worst-case scenario
and not something you'll likely encounter in the real world, but it works for
this experiment.

```go
package main

import (
	"fmt"
	"sync"
	"syscall"
	"time"
)

func main() {
	fmt.Println(time.Now())

	wg := new(sync.WaitGroup)
	wg.Add(10)
	for i := 0; i < 15; i++ {
		go func(i int) {
			if err := syscall.Nanosleep(&syscall.Timespec{
				Sec:  300,
				Nsec: 0,
			}, nil); err != nil {
				panic(err)
			}
			wg.Done()
		}(i)
	}

	wg.Wait()
	fmt.Println("Hello, World!")
	fmt.Println(time.Now())
}
```

Now if build this, it should execute for about 1 second because all of these
nanosleep are executing concurrently, and we should see 10 calls to nanosleep in
strace and...

```bash
$ go build -o gst main.go
$ strace -e nanosleep ./gst
2021-11-12 08:35:40.751919244 -0500 EST m=+0.000043524
nanosleep({tv_sec=1, tv_nsec=0}, NULL)  = 0
2021-11-12 08:35:41.752482398 -0500 EST m=+1.000606708
+++ exited with 0 +++
```

Oh... huh?

Well, as it turns out, I'm still very new to strace, and what's happening here
is that because we're starting multiple goroutines that are each immediately
blocked, the Go runtime is spawning new OS threads to accommodate the new
goroutines, just as expected, but strace doesn't follow child processes by
default. To fix this, we need to add the `--follow-forks` (or `-f` for short)
argument to strace. Doing so, we get this:

```bash
$ strace -f -e nanosleep ./gst
strace: Process 43633 attached
strace: Process 43634 attached
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, strace: Process 43635 attached
strace: Process 43636 attached
NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
[pid 43635] nanosleep({tv_sec=0, tv_nsec=3000},  <unfinished ...>
[pid 43633] <... nanosleep resumed>NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
[pid 43635] <... nanosleep resumed>NULL) = 0
[pid 43633] <... nanosleep resumed>NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, 2021-11-12 08:38:25.534424471 -0500 EST m=+0.000110511
 <unfinished ...>
[pid 43632] nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
[pid 43633] <... nanosleep resumed>NULL) = 0
[pid 43635] nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
[pid 43636] nanosleep({tv_sec=1, tv_nsec=0}, strace: Process 43637 attached
 <unfinished ...>
[pid 43634] nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
[pid 43633] <... nanosleep resumed>NULL) = 0
strace: Process 43638 attached
strace: Process 43639 attached
strace: Process 43640 attached
[pid 43638] nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
[pid 43637] nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
[pid 43640] nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
[pid 43633] <... nanosleep resumed>NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
strace: Process 43641 attached
strace: Process 43642 attached
[pid 43639] nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
[pid 43642] nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
[pid 43633] <... nanosleep resumed>NULL) = 0
strace: Process 43643 attached
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
[pid 43641] nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
[pid 43633] <... nanosleep resumed>NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=40000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=80000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=160000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=320000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=640000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=1280000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=2560000}, NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, NULL) = 0
[pid 43632] <... nanosleep resumed>NULL) = 0
[pid 43635] <... nanosleep resumed>NULL) = 0
[pid 43636] <... nanosleep resumed>NULL) = 0
[pid 43640] <... nanosleep resumed>NULL) = 0
[pid 43638] <... nanosleep resumed>NULL) = 0
[pid 43637] <... nanosleep resumed>NULL) = 0
[pid 43634] <... nanosleep resumed>NULL) = 0
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000},  <unfinished ...>
[pid 43639] <... nanosleep resumed>NULL) = 0
[pid 43642] <... nanosleep resumed>NULL) = 0
[pid 43633] <... nanosleep resumed>NULL) = 0
[pid 43641] <... nanosleep resumed>NULL) = 0
[pid 43641] --- SIGURG {si_signo=SIGURG, si_code=SI_TKILL, si_pid=43632, si_uid=1000} ---
[pid 43633] nanosleep({tv_sec=0, tv_nsec=20000}, 2021-11-12 08:38:26.535401496 -0500 EST m=+1.001087546
 <unfinished ...>) = ?
[pid 43643] +++ exited with 0 +++
[pid 43642] +++ exited with 0 +++
[pid 43641] +++ exited with 0 +++
[pid 43640] +++ exited with 0 +++
[pid 43638] +++ exited with 0 +++
[pid 43637] +++ exited with 0 +++
[pid 43636] +++ exited with 0 +++
[pid 43635] +++ exited with 0 +++
[pid 43634] +++ exited with 0 +++
[pid 43633] +++ exited with 0 +++
[pid 43639] +++ exited with 0 +++
+++ exited with 0 +++
```

Whoa, that's a lot of output! Surely then, that's not our code that's doing
that?

A lot of these nanosleep look like `[pid 43633] nanosleep({tv_sec=0,
tv_nsec=20000}, NULL) = 0` and we're sleeping for 1 seconds, 0 nanoseconds. I
haven't explored these in much detail, I can only assume that they come from the
magic of the Go runtime under the hood. So from now, I'll be adding the `-o
strace.out` argument to strace to pipe the output to a file that I can then grep
after the fact.

```bash
$ strace -f -o strace.out -e nanosleep ./gst
2021-11-12 08:41:39.412736348 -0500 EST m=+0.000039566
2021-11-12 08:41:40.41354644 -0500 EST m=+1.000849708
$ grep 'tv_sec=1' strace.out | wc -l
10
```

10 calls to nanosleep, we're on the right track!

If you recall that [StackOverflow post][2] from earlier, we can use
`runtime.GOMAXPROCS` to limit how many CPUs the Go runtime will use. So let's go
ahead and add that to an `init` function in our little program and see what
happens.

```go
import "runtime"

func init() {
  runtime.GOTMAXPROCS(1)
}
```

And now through strace:

```bash
$ strace -f -o strace.out -e nanosleep ./gst
2021-11-12 13:18:43.737277942 -0500 EST m=+0.000177097
2021-11-12 13:18:44.739359918 -0500 EST m=+1.002259083
$ grep 'tv_sec=1' strace.out
47424 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
47427 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
47428 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
47426 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
47429 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
47430 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
47431 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
47432 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
47433 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
47434 nanosleep({tv_sec=1, tv_nsec=0},  <unfinished ...>
```

Mhm, that's not exactly what we were looking for. We still have 10 calls to
nanosleep, so that's good, but they each have their own pid, meaning they are
each started on a new OS thread. For some people this is expected: Tuning the
number of CPUs is not the same thing as tuning the number of OS threads. Setting
the number of CPUs to 1 basically means that the main thread and all of the
child processes of the program will run on the same CPU core. But operating
systems can run more than a single thread on each core. In fact, most operating
systems can run tens of thousands, if not more, threads on the entire machine.
What's happening here when we tune the number of CPUs down to 1 is that we're
still creating OS threads for our goroutines, but we defer to the kernel to
balance when each one gets to do some work and when it goes to sleep again.

## Checking out `debug.SetMaxThreads`

We're back to the drawing board, and back to that initial Google search we did.
In the results, I also found [this thread from Go's own issue tracker][8] which
is treasure trove of information. First we get a bit more clarification on the
heuristics behind whether or not a goroutine is blocked on a syscall or not:
"When epoll/kqueue/completion ports can be used (e.g. for network), Go uses
that." If you're not aware of what epoll is, that's a great subject to go
research. I'm no expert on the subject but in essence epoll is a mechanism by
which a program can ask the kernel to be notified of a state change in a
syscall. It's used often in network syscalls for example. But back to the issue
at hand: Further down this thread, there's also a note from Russ Cox that points
to the [runtime/debug's SetMaxThreads][9] function that was added in Go 1.2.

So let's try this out:

```go
import (
  "runtime"
  "runtime/debug"
)

func init() {
  runtime.GOMAXPROCS(1)
  runtime.SetMaxThreads(1)
}
```

And now running it:

```bash
$ strace -f -o strace.out -e nanosleep ./gst
runtime: program exceeds 1-thread limit
fatal error: thread exhaustion

goroutine 1 [running, locked to thread]:
runtime.throw({0x4a2c08, 0x0})
	/usr/local/go/src/runtime/panic.go:1198 +0x71 fp=0xc000098de8 sp=0xc000098db8 pc=0x42fdb1
runtime.checkmcount()
	/usr/local/go/src/runtime/proc.go:760 +0x8c fp=0xc000098e10 sp=0xc000098de8 pc=0x4338ec
runtime/debug.setMaxThreads(0x1)
	/usr/local/go/src/runtime/proc.go:6317 +0x65 fp=0xc000098e30 sp=0xc000098e10 pc=0x457bc5
runtime/debug.SetMaxThreads(...)
	/usr/local/go/src/runtime/debug/garbage.go:134
main.init.0()
	/home/wperron/github.com/wperron/go-single-thread/main.go:14 +0x29 fp=0xc000098e48 sp=0xc000098e30 pc=0x4897c9
runtime.doInit(0x5227c0)
	/usr/local/go/src/runtime/proc.go:6498 +0x123 fp=0xc000098f80 sp=0xc000098e48 pc=0x43f3e3
runtime.main()
	/usr/local/go/src/runtime/proc.go:238 +0x1e6 fp=0xc000098fe0 sp=0xc000098f80 pc=0x432446
runtime.goexit()
	/usr/local/go/src/runtime/asm_amd64.s:1581 +0x1 fp=0xc000098fe8 sp=0xc000098fe0 pc=0x45b561
```

Oh. That's doesn't look good.

Looking at the trace, I can pin it to line 14 in my application, which
corresponds to the line where we call `debug.SetMaxThreads` so that seems odd.
My suspicion here is that either Go itself or some function we called is using
some goroutine under the hood, so our program just isn't getting very far, let's
test that by bumping the number of threads to 5.

```bash
$ strace -f -o strace.out -e nanosleep ./gst
2021-11-12 17:12:32.740302049 -0500 EST m=+0.000151949
runtime: program exceeds 5-thread limit
fatal error: thread exhaustion

runtime stack:
runtime.throw({0x4a2c08, 0x0})
	/usr/local/go/src/runtime/panic.go:1198 +0x71
runtime.checkmcount()
	/usr/local/go/src/runtime/proc.go:760 +0x8c
runtime.mReserveID()
	/usr/local/go/src/runtime/proc.go:776 +0x36
runtime.startm(0xc000028000, 0x0)
	/usr/local/go/src/runtime/proc.go:2477 +0x90
runtime.handoffp(0xc0ffffffff)
	/usr/local/go/src/runtime/proc.go:2519 +0x2ac
runtime.retake(0x4fb42aadd15e)
	/usr/local/go/src/runtime/proc.go:5537 +0x1e7
runtime.sysmon()
	/usr/local/go/src/runtime/proc.go:5445 +0x333
runtime.mstart1()
	/usr/local/go/src/runtime/proc.go:1407 +0x93
runtime.mstart0()
	/usr/local/go/src/runtime/proc.go:1365 +0x79
runtime.mstart()
	/usr/local/go/src/runtime/asm_amd64.s:248 +0x5

goroutine 1 [semacquire]:
sync.runtime_Semacquire(0x0)
	/usr/local/go/src/runtime/sema.go:56 +0x25
sync.(*WaitGroup).Wait(0x4bea40)
	/usr/local/go/src/sync/waitgroup.go:130 +0x71
main.main()
	/home/wperron/github.com/wperron/go-single-thread/main.go:34 +0x145

goroutine 6 [syscall]:
syscall.Syscall(0x23, 0xc00006a7a0, 0x0, 0x0)
	/usr/local/go/src/syscall/asm_linux_amd64.s:20 +0x5
syscall.Nanosleep(0x0, 0x0)
	/usr/local/go/src/syscall/zsyscall_linux_amd64.go:641 +0x47
main.main.func1(0x0)
	/home/wperron/github.com/wperron/go-single-thread/main.go:24 +0x45
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96

goroutine 7 [syscall]:
syscall.Syscall(0x23, 0xc00006afa0, 0x0, 0x0)
	/usr/local/go/src/syscall/asm_linux_amd64.s:20 +0x5
syscall.Nanosleep(0x0, 0x0)
	/usr/local/go/src/syscall/zsyscall_linux_amd64.go:641 +0x47
main.main.func1(0x0)
	/home/wperron/github.com/wperron/go-single-thread/main.go:24 +0x45
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96

goroutine 8 [syscall]:
syscall.Syscall(0x23, 0xc00006b7a0, 0x0, 0x0)
	/usr/local/go/src/syscall/asm_linux_amd64.s:20 +0x5
syscall.Nanosleep(0x0, 0x0)
	/usr/local/go/src/syscall/zsyscall_linux_amd64.go:641 +0x47
main.main.func1(0x0)
	/home/wperron/github.com/wperron/go-single-thread/main.go:24 +0x45
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96

goroutine 9 [runnable]:
main.main·dwrap·1()
	/home/wperron/github.com/wperron/go-single-thread/main.go:23
runtime.goexit()
	/usr/local/go/src/runtime/asm_amd64.s:1581 +0x1
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96

goroutine 10 [runnable]:
main.main·dwrap·1()
	/home/wperron/github.com/wperron/go-single-thread/main.go:23
runtime.goexit()
	/usr/local/go/src/runtime/asm_amd64.s:1581 +0x1
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96

goroutine 11 [runnable]:
main.main·dwrap·1()
	/home/wperron/github.com/wperron/go-single-thread/main.go:23
runtime.goexit()
	/usr/local/go/src/runtime/asm_amd64.s:1581 +0x1
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96

goroutine 12 [runnable]:
main.main·dwrap·1()
	/home/wperron/github.com/wperron/go-single-thread/main.go:23
runtime.goexit()
	/usr/local/go/src/runtime/asm_amd64.s:1581 +0x1
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96

goroutine 13 [runnable]:
main.main·dwrap·1()
	/home/wperron/github.com/wperron/go-single-thread/main.go:23
runtime.goexit()
	/usr/local/go/src/runtime/asm_amd64.s:1581 +0x1
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96

goroutine 14 [runnable]:
main.main·dwrap·1()
	/home/wperron/github.com/wperron/go-single-thread/main.go:23
runtime.goexit()
	/usr/local/go/src/runtime/asm_amd64.s:1581 +0x1
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96

goroutine 15 [syscall]:
syscall.Syscall(0x23, 0xc000066fa0, 0x0, 0x0)
	/usr/local/go/src/syscall/asm_linux_amd64.s:20 +0x5
syscall.Nanosleep(0x0, 0x0)
	/usr/local/go/src/syscall/zsyscall_linux_amd64.go:641 +0x47
main.main.func1(0x0)
	/home/wperron/github.com/wperron/go-single-thread/main.go:24 +0x45
created by main.main
	/home/wperron/github.com/wperron/go-single-thread/main.go:23 +0x96
```

Different error message, progress is being made!

So at this point what we're seeing here is that we get past the initial setup
phase, and eventually hit a point where one of the goroutines we're starting is
trying to spawn a new thread, hits the limit and the program crashes. In this
trace we can see that we have a few goroutines up while that happens, and we can
see that our goroutines were blocked on a syscall, which kinda what we're
expecting to see.

If we take a look at the godoc comment for `debug.SetMaxThreads` we realize that
this is indeed the expected behavior:

> SetMaxThreads sets the maximum number of operating system threads that the Go
> program can use. If it attempts to use more than this many, the program
> crashes. SetMaxThreads returns the previous setting. The initial setting is
> 10,000 threads. 
> 
> SetMaxThreads is useful mainly for limiting the damage done by programs that
> create an unbounded number of threads. The idea is to take down the program
> before it takes down the operating system.

In other words, `SetMaxProcs` isn't there to put a cap on the number of OS
threads that the runtime can use, it's only intended as an escape hatch to
prevent a program running hot to hit the ulimit on a server and taking the
entire machine with it.

## Conclusion

And that's really as far as it goes unfortunately. It's a slightly disappointing
outcome to the original question we had, instead it shows that Go simply cannot
do concurrent computation without the use of OS threads, which is something we
already knew. What I did learn from that experiment though is that there's some
interesting heuristics at play here to determine whether or not spawning a
goroutine will spawn a new OS thread with it, so I didn't completely wasted that
hour of my life! If you're curious, you can [check out the source code
here][10].

[1]: https://fasterthanli.me/articles/understanding-rust-futures-by-going-way-too-deep 
[2]: https://stackoverflow.com/questions/39245660/number-of-threads-used-by-go-runtime 
[3]: https://pkg.go.dev/runtime#GOMAXPROCS
[4]: https://dave.cheney.net/2015/08/08/performance-without-the-event-loop
[5]: https://pkg.go.dev/time#Sleep 
[6]: https://cs.opensource.google/go/go/+/refs/tags/go1.17.3:src/time/sleep.go;l=9
[7]: https://pkg.go.dev/syscall#Nanosleep
[8]: https://github.com/golang/go/issues/4056
[9]: https://pkg.go.dev/runtime/debug#SetMaxThreads
[10]: https://github.com/wperron/go-single-threaded
