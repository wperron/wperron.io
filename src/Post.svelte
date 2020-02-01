<script>
	export let post
</script>

<div class='blog-post'>
	<h1>{post.attributes.title}</h1>
	<i>{post.attributes.date}</i>
	<p>{post.attributes.description}</p>
	<hr />
	<div class='blog-post-body'>
		{@html post.body}
	</div>
</div>