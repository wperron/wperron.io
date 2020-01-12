<script>
	export let links
</script>

<section class="social">
	<h2>Where to find me</h2>
	<ul>
		{#each links as link}
			<li>{link.name}: <a href={link.href} target="_blank">{link.href}</a></li>
		{/each}
	</ul>
</section>

<style>
	li {
		list-style-type: none;
	}
</style>