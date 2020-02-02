<script>
	import { Router, Link, Route } from "svelte-routing"
	import Title from './components/Title.svelte'
	import Social from './components/Social.svelte'
	import Date from './components/Date.svelte'
	import Post from './Post.svelte'

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
	let posts = null

	async function fetchPosts() {
		let res = await fetch('/posts.json')
			.then(res => res.json())
		posts = res
		return res
	}

	function getPostBySlug(slug) {
		const match = posts.filter(post => post.attributes.slug === slug)
		if (match.length > 1) {
			throw new Error('Found more than one slug, expected only one.')
		}
		return match[0]
	}
</script>

<main>
	<Title title='wperron' src='profile-small.jpg' desc="that's me!" />
	<hr />
	<Router>
		<Route path="/">
			<Social links={links} />
			<hr />
			{#await promise}
				<p>waiting...</p>
			{:then posts}
				{#each posts as post}
					<div class='content-item'>
						<Link to={`/blog/${post.attributes.slug}`}>
							<span class='content-title'>{post.attributes.title}</span>
						</Link>
						<Date date={post.attributes.date} />
						<p class='content-text'>{post.attributes.description}</p>
					</div>
				{/each}
			{:catch err}
				<p>Oops, something went wrong... 😬</p>
			{/await}
		</Route>
		<Route path="blog/:slug" let:params>
			<Post post={getPostBySlug(params.slug)} />
		</Route>
	</Router>
</main>

<style>
	main {
		max-width: 650px;
		margin: 0 auto;
	}

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