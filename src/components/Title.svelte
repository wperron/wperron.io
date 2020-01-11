<script>
	export let title
	export let src
	export let desc
</script>

<section id='title'>
	<img src={src} alt={desc} />
	<h1>{title}</h1>
</section>

<style>
	h1 {
		color: #ff3e00;
		/* text-transform: uppercase; */
		font-size: 3em;
		font-weight: 100;
		font-family: 'consolas'
	}
</style>