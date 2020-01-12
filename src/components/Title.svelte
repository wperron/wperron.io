<script>
	export let title
	export let src
	export let desc
</script>

<section class='title'>
	<img src={src} alt={desc} />
	<h1>{title}</h1>
	<p>Software Developer, Devops Advocate and Cloud Computing Enthusiast.</p>
</section>

<style>
	h1 {
		color: #ff3e00;
		font-size: 3em;
		font-weight: 100;
	}
</style>