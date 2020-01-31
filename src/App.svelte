<script>
	import Title from './components/Title.svelte'
	import Social from './components/Social.svelte'
	import ContentList from './components/ContentList.svelte'

	let links = [
		{
			name: "GitHub",
			href: "https://github.com/wperron",
		},
		{
			name: "Twitter",
			href: "https://twitter.com/_wperron",
		},
	]

	let promise = fetchPosts()

	async function fetchPosts() {
		return await fetch('/posts.json')
			.then(res => res.json())
	}
</script>

<main>
	<Title title='wperron' src='profile-small.jpg' desc="that's me!" />
	<hr />
	<Social links={links} />
	<hr />
	{#await promise}
		<p>waiting...</p>
	{:then posts}
		<ContentList posts={posts} />
	{:catch err}
		<p>Oops, something went wrong... 😬</p>
	{/await}
</main>

<style>
	main {
		max-width: 650px;
		margin: 0 auto;
	}
</style>