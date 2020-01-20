<script>
	import Item from './ContentItem.svelte'

	export let pages
</script>

<div class='content-list'>
	{#each pages as page}
		<Item page={page} />
	{/each}
</div>