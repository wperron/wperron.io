<script>
	import { Router, Link, Route } from "svelte-routing"
	import { posts, links } from './stores.js'
	import Title from './components/Title.svelte'
	import Social from './components/Social.svelte'
	import Date from './components/Date.svelte'
	import Post from './Post.svelte'
</script>

<main>
	<Title title='wperron' src='profile-small.jpg' desc="that's me!" />
	<hr />
	<Router>
		<Route path="/">
			<Social links={links} />
			<hr />
			{#each $posts as post}
				<div class='content-item'>
					<Link to={`/blog/${post.attributes.slug}`}>
						<span class='content-title'>{post.attributes.title}</span>
					</Link>
					<Date date={post.attributes.date} />
					<p class='content-text'>{post.attributes.description}</p>
				</div>
			{/each}
		</Route>
		<Route path="blog/:slug" let:params>
			<Post slug={params.slug} />
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