<script>
	import { posts } from './stores.js'
	import Date from './components/Date.svelte'

	export let slug

	let post = null
	const unsubscribe = posts.subscribe(all => {
		const match = all.filter(x => x.attributes.slug === slug)
		if (match.length > 1) {
			throw new Error('Found more than one lsug, expected only one.')
		}
		post = match[0]
	})
</script>

<div class='blog-post'>
	<h1>{post.attributes.title}</h1>
	<Date date={post.attributes.date} />
	<p>{post.attributes.description}</p>
	<hr />
	<div class='blog-post-body'>
		{@html post.body}
	</div>
</div>