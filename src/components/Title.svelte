<script>
	export let title
	export let src
	export let desc
</script>

<section class='title'>
	<img src={src} alt={desc} width="100px" />
	<h1>{title}</h1>
	<p>Software Developer, DevOps Advocate and Cloud Computing Enthusiast.</p>
</section>

<style>
	.title {
		display: block;
	}

	.title img {
		float: left;
		margin-right: 20px;
	}

	.title h1 {
		color: #9575cd;
		font-size: 3em;
		font-weight: 100;
	}
</style>