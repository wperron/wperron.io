<script>
	export let page
</script>

<div class='content-item'>
	<a href={page.href} class='content-title'>{page.title}</a>
	<p class='content-text'>{page.desc}</p>
</div>

<style>
	.content-item {
		cursor: pointer;
	}

	.content-title {
		margin: 10;
		font-size: 2rem;
	}

	.content-text {
		margin: 0;
	}
</style>