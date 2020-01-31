<script>
	import Item from './ContentItem.svelte'

	export let posts
</script>

<div class='content-list'>
	{#each posts as post}
		<Item post={post} />
	{/each}
</div>