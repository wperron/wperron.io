<script>
	import Date from './components/Date.svelte'

	export let post
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