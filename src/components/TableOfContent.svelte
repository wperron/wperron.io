<script>
	// export let title
	export let pages
</script>

<section class='table-of-content'>
	<!-- <h2>{title}</h2> -->
	<li>
		{#each pages as page}
			<li><a href={page.href}>{page.name}</a></li>
		{/each}
	</li>
</section>

<style>
	li {
		list-style-type: none;
	}
</style>