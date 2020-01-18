<script>
	import Title from './components/Title.svelte'
	import Card from './components/Card.svelte'
	import Social from './components/Social.svelte'
	import TableOfContent from './components/TableOfContent.svelte'

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

	let pages = [
		{
			name: "Reading List",
			href: "#"
		}
	]
</script>

<main>
	<Title title='wperron' src='profile-small.jpg' desc="that's me!" />

	<hr />

	<Social links={links} />

	<hr />

	<TableOfContent pages={pages} />
</main>

<style>
	main {
		max-width: 650px;
		margin: 0 auto;
	}
</style>