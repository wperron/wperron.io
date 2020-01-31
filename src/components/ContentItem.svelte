<script>
	export let post
</script>

<div class='content-item'>
	<a href='#' class='content-title'>{post.attributes.title}</a>
	<p class='content-text'>{post.attributes.date}</p>
	<p class='content-text'>{post.attributes.description}</p>
</div>

<style>
	.content-item {
		cursor: pointer;
	}

	.content-title {
		margin: 10;
		font-size: 1.5rem;
	}

	.content-text {
		margin: 0;
	}
</style>