---
draft: false
date: 2022-05-11T08:54:20.008Z
title: Generics Make Go Better
---

We had to wait until February of 2022 to get support for generics in Go, and
when we finally got there, it turned out to be one of the most contentious
addition to the language we've seen in a while. Which is a shame really, because
along with 1.18 also came some really neat improvements to the Garbage Collector
that went by-and-large ignored because of all the attention generics were
getting. And while I'm in no way advocating that anyone should immediately go
and update their codebases to use generics, I do think that the way this feature
is being presented by the Go team doesn't really do it justice, or fails to
highlight what makes generics so valuable. In my opinion their addition to the
language make Go an objectively better language.

## Generics are undersold

With all of the discourse online about whether or not generics were needed in
the language at all, when I saw the [_When To Use Generics_ blog post][1] post
from the Go team, I was excited. Finally, I thought, we'd have _some_
authoritative source for when to use this feature. Maybe this would help steer
the discourse. What we got instead was ...disappointing.

There are some good bits in there for sure, but overall it feels like the Go
team is saying "use it for these very narrow, low-level use-cases, and beyond
that it's not much use" and I'm really bummed by that outcome. Especially since
the examples that they use are so short and cherry-picked. I think they're
underselling generics (or over-selling the existing interface and reflection
features) of Go and I want to offer some additional perspective on the topic.

## Replacing Interface Types with Type Parameters

One of the points in that article is that you should not replace functions that
already accept interface types with type parameters. The example they use is a
function that reads some bytes, and thus accepts an `io.Reader` parameter. In
that case, yeah I agree with the conclusion, changing the signature to use type
parameters only makes the signature harder to understand and doesn't bring any
added benefits. Here's a slightly modified version using a `Copy` function to
illustrate:

```go
// With interface types
func Copy(dst io.Writer, src io.Reader) (int, error) {}
// With type parameters
func Copy[W io.Writer, R io.Reader](dts W, src R) (int, error) {}
```

I'm not _terribly_ offended by the second version having used a lot of languages
that support generics in the past, but just because I'm accustomed to reading
such code doesn't make it better, and the case for the explicit nature of the
first version is strong in my opinion.

But here's the thing that goes unmentioned by the original blog post: This
example is inherently biased in favor of interface types. In this example, it's
fair to assume that the body of those functions doesn't need to know about the
concrete types of either of its parameters. It only needs to care about it's
_behavior_. I want to read some bytes here, and send them there. Whether one
side is an OS File, and the other side an in-memory buffer has no incidence over
what the code inside the body of this function should look like.

But that's not always the case. Take for example a comparison function. We could
write a function that compares two parameters and returns the biggest one of the
two for instance, maybe using the already existing `sort.Interface` interface.

```go
func Max(a, b sort.Interface) sort.Interface {
	if a.Less(b) {
		return b
	}
	return a
}
```

This function works but it's awkward. For one, it returns a `sort.Interface`
because we need a return type but at compile time we can't know what the
concrete type is. This means that at the callsite, we would need to cast the
result back to the concrete type we want. This isn't terribly unsafe, we should
already have that information at the callsite. But still, it just feels...
_awkward._

Moreover, this code doesn't account for the fact that `a` and `b` could be
different concrete types! We could pass an `int` and a `string` here, and the
compiler wouldn't bat an eye, instead we'd get a run-time panic. To fix this, we
have to inspect the concrete type at run-time, and either fail fast, or try to
resolve both types into a comparison that makes sense. At the simplest, our code
would look like this:

```go
func Max(a, b sort.Interface) (sort.Interface, error) {
	if a.(type) != b.(type) {
		return errors.New("mismatched types")
	}
	
	if a.Less(b) {
		return b
	}
	return a
}
```

This works, but now we've changed our function signature too. Or we can try to
resolve the types on both sides like so:

```go
func Max(a, b sort.Interface) sort.Interface {
	typeA, typeB := a.(type), b.(type)
	
	if typeA == typeB {
		if a.Less(b) {
			return b
		}
		return a
	}
	
	// ...
}
```

In this case, we've made our function _much_ longer, even for something as
simple as comparing two values. We have _potentially_ removed the error from the
return and thus kept the signature as is, depending on how the function is
implemented, _but_ we've introduced magic behavior in here as well. What happens
if I call this with a `string` and a `bool` ? Or a `uint32` and an `int16` ? The
behavior of this function can now be surprising to the callsite because of its
internal implementation. This is what a lot of dynamic languages do too, and
generally that's not really considered an advantage, at least not when we're
talking about production software.

If we used a type parameter though, we could solve this very nicely:

```go
func Max[Sortable sort.Interface](a, b Sortable) Sortable {
	if a.Less(b) {
		return b
	}
	return a
}
```

In this case, we've _effectively_ written the same code as the first example
where we compared both types at runtime, except we've moved this check to the
compilation step. Additionally, we've also fixed the drawback that that example
had; The `Sortable` type parameter gets resolved to whatever the concrete is at
the callsite, which means we don't need cast back the return value to a concrete
type, it already is!

The Go team seems to take great offense at the reduced readability (though in my
opinion that's arguable) but glosses over the _added safety_ that generics
provide here.

## _Don't_ Use Reflection

> Go has [run time reflection](https://pkg.go.dev/reflect). Reflection permits a
> kind of generic programming, in that it permits you to write code that works
> with any type.

Yes, _but._ This is far from a complete story here. The example they give of the
`encoding/json` is a good example where I agree with them that using generics
wouldn't be an improvements, and would probably even make for worse code.
However, run time reflection can be horrendously slow and produce unsafe code.
This also links to our previous example, we _can_ effectively check types at
runtime using `a.(type) == b.(type)`, and because we're using type assertions
here it's pretty fast.

But why leave something for run time, when you could simply let the compiler do
it for you, once, ahead of time? There's a class of problems, like json
serialization, where reflecting at run time makes sense. But I think there's
even more problems where it's more beneficial to move these checks to compile
time. In all but the most trivial cases, reflection is a big footgun; It's so
easy to miss a case in a switch statement and end up with certain types simply
unaccounted for. That's why the example above where I mention resolving the most
common type between the two parameters is left blank with a comment; I didn't
want to actually implement it, it's just too complex. And we're talking about a
function that compares two values together, this shouldn't be rocket science.

Maybe if Go had better support for pattern matching this wouldn't bother me so
much. The bottom line here is that I want to be able to lean on the tools
provided to me by the language, whether that's the compiler or the language
server, to produce _safer_ code. Generics help me do that in a lot of situations
whereas reflection leaves me to deal with that complexity on my own, with little
to no safeguard.

## In Conclusion

_When To Use Generics_ offers some interesting advice, and I'm glad this post
exists. But in my opinion, it misses the mark on what is the fundamental benefit
of generics: It's an additional safeguard in the language. It allows me to write
code in a way that makes me more confident that is _correct_ if the compilation
completes successfully. I guess all the language is missing now are proper
enums? 🤷

[1]: https://go.dev/blog/when-generics
