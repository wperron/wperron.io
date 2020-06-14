---
title: "Deno may be the most important development in Javascript since Node itself."
date: 2020-06-12T20:16:58-04:00
draft: false
---

I don't think anyone expected [Deno's announcement](https://www.youtube.com/watch?v=M3BM9TB-8yA)
at JS Conf EU 2018. I certainly wasn't. I was pretty content with Node as it were, as I think
most people were, and probably still are: It had been out in the world for over 9 years (11 now),
the community was huge, the ecosystem was mature, there was some great tooling developed around
it and it really managed to cut itself a place as a solid choice for backend programming. So how
could I have possibly foreseen Deno?

And that is precisely why I think Deno is so important.

> [...] In the javascript community we tend to get a little uncomfortable when
> we criticize each other's work, but I think it's really important for our collective growth.

This is a quote from Rich Harris from his [_Rethinking Reactivity_ talk](https://www.youtube.com/watch?v=AdNJ3fydeao) (of which there is a couple of versions available on YouTube). His comments
were targetted specifically towards the world of frontend framework, but I think its also painfully
of the backend world.

I think as a community we have simply come to accept a lot Node's quirks as normal, something
you just have to accept and move on with you're life. I personally came to Node long after it
was released, and I remember seeing `require` for the first time and sort of scratching my head
because I had never seen that in browserland. And I was told "this is how you import stuff in Node,
just roll with it". And I did. And I never really thought to put that into question after that.

But let's face it: `require` is _weird_ when you think about it. Before Deno came along I had never
really thought about the fact that `require` is really opaque in what it actually imports.
Does `require('./my-lib')` import a file called `my-lib.js` or is it importing `my-lib/index.js`?
this may seem like an unimportant issue, and maybe it's not worth spending time to fix it, but the fact
is, Deno makes it easy to be very explicit about what to import in a way that reminds a lot of other
language's module system. I like that. As a library consumer I must admit it doesn't have that much
of an impact. but as a library _author_ it makes life so much easier by giving clear guidelines
on how to structure code so that it can be imported in the way that is expected by both author and consumer.

Another element that has caused quite a bit of debate is the security aspect of Deno. Most of the concerns
I hear are either about how easy it is to "bypass" it by using the `-A` flag to give permissions, or
about how the security problem can be solved better at the virtualization layer, for instance with Docker or
Kubernetes or whatever workload orchestrator you're using. To address the first concern, I think it's a fair
point. It sure isn't perfect, but at least it acknowledges the issue. And while it can be used in a very
open way using the `-A` flag, it's also flexible enough to be very granular, for example only allowing access
to certain filesystem paths or network domains. In other words, it gives more options to software developers
to secure their application, but has no opinions on what the best choice is, and I like that.
I think the second is really missing the mark. Why rely on extra levels of virtualizations to restrict
access to system resources when v8 is _already_ essentially a virtual machine, and already acts as a
blackbox with no access to the system it runs in? We don't have to build extra infrastrucre and extra layers
to secure the runtime. So why do we?

That being said, the _real_ debate that Deno has stirred is around dependency management. Kitson Kelly
already made a [great post](https://www.kitsonkelly.com/posts/deno-is-a-browser-for-code/) on the subject
that I suggest you go and read, so I won't expand too long on the subject. When it comes down to it, there's
really two things that I really like about the way Deno deals with depencies. The first one is that it
doesn't have an opinion on where code comes from. Don't get me wrong, I think the npm CLI is actually
quite nice and easy to use. My issue with it is that it defaults to the central npm registry, and using
private packages from different registries requires me to do some extra setup to get it to work. It's extra
documentation I need to write so that all of my teammates use the same setup and the same registries and
it's extra toil that I frankly would just rather not have to deal with. Deno doesn't care. As long as the
domain where the dependency is hosted is accessible, it will fetch the code. There's no setup required,
no documentation to write. It just works. The second thing I like is that it strongly
couples my code with the code that it depends on. Again, I never really stopped to think about it before
Deno, but being able to declare _dependencies_ completely _separately_ from the code that will use it
makes absolutely no sense. It allows for dependencies to be declared, but never used.
Sure we can use solutions like tree shaking to solve the problem, or build linters
that will alert on unused dependencies, but the way Deno (and Go) deal with it is just much simpler: Just
declare your dependencies as you them, when you need them. that's it. No muss, no fuss. It solves
the issue at the source, rather than rely on extra machinery after the fact.

Now, that's not say that this way of doing things is perfect. For instance, a very good criticism of Deno's
dependency management strategy is that it makes it hard to update dependency versions across a large code base.
Indeed even Go realized this and created Go modules and the `go.mod` file. Still, the basic pattern is still the
same. I declare my dependencies as I go, and use `go mod tidy` to retroactively update my `go.mod` file. But we
had to wait for version 1.14 to get there. It was the result of a long and meticulous investigation on the issue.
It's a process that Deno will have to go through as well, and I would much rather wait for a solid, lean solution
than rush some half-baked solution. That's how we got `node_modules`, `require` and `package.json` in the
first place.

## TL;DR:

Deno's biggest contribution to the Javascript community is that it forces us to take a good hard look at some
of our practices and really evaluate whether they're the best we can do. Criticizing each other's work
can only be a good think for the collective growth of the Javascript community.

Maybe Deno is on to something and we should all be converting our code to run on Deno. Maybe it's missing
the mark completely and Node has actually been doing it perfectly right all along. And maybe _some_ of
Deno's innovations are really interesting and should be ported over to Node. I don't know. But at least
we're talking about it. We're re-evaluating things we thought we knew, and are experimenting with different
solutions to problems in the ecosystem.
