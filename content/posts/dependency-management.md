---
title: "The Myths of Dependency Management"
date: 2020-12-12T16:50:44-04:00
draft: true
---

Let's take about dependency management for a minute. For the past few weeks I've been having
discussions in the Deno and Node.js communities and I have come to realize that we as an industry
have some deeply ingrained assumptions about dependency management. Since this is one of (if not _the_)
most contentious issue surrounding Deno and that it is even surfacing in Node.js around the
discussions surrounding the [implementation of URL imports](https://github.com/nodejs/node/discussions/36430), I thought it would be a good idea to take a good look at those assumptions and see if they
hold up. While this post is targetted specifically at the JavaScript community, I hope some of it
can also be applied to other ecosystems.

"npm identifiers are just short aliases for a url anyway"

> We're never going to put URLs into our imports because we want to be able to run things offline without depending on 3rd party servers to stay up & consistent over time, but if we can depend on local ./node_modules libs once compatibility is improved then that's great.

> Local caching alone loses all the benefits of using a package manager though.
I want to have a central repository of all the package versions with enforced monotonically increasing version numbers and a public, explicit chain of trust. Otherwise it's basically curl | sh

> Using URLs means there are no rules enforced, the code hosted at that URL can change out from under you without any warning.

> A new developer checking out our repo could fetch totally different packages than everyone else on the team and not have any warning about it being different, or any recourse if they wanted to fetch a previous version.

> Using URLs is like having an iframe to somebody else's website on your website.

> but you could also have a package-list file that lists all dependencies of dependencies as well as download mirrors, or hashes with peer-to-peer distribution.

> Personally I appreciate being able to choose my linter, compiler, dialect etc. I also tend to prefer distributed solutions. Deno running the entire environment is a negative for me, at least for now. To me, it just shows an approach of ignoring what already exists and reinventing the wheel.
