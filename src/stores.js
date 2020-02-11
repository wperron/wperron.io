import { readable } from 'svelte/store';

export const posts = readable([], async function start(set) {
	const res = await fetch('/posts.json')
		.then(res => res.json())
	set(res)

	return function stop() {
		return
	}
})

export const links = [
	{
		name: "GitHub",
		href: "https://github.com/wperron",
	},
	{
		name: "Twitter",
		href: "https://twitter.com/_wperron",
	},
	{
		name: "My Resume",
		href: "https://wperron.io/resume-en.pdf",
	},
]