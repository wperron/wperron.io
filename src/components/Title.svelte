<script>
	export let title
	export let src
	export let desc
</script>

<section class='title'>
	<img src={src} alt={desc} width="100px" />
	<div>
		<h1>{title}</h1>
		<p>Software Developer, DevOps Advocate and Cloud Computing Enthusiast.</p>
	</div>
</section>

<style>
	.title {
		display: block;
		margin: 30px 0;
	}

	.title img {
		float: left;
		margin-right: 20px;
	}

	.title h1 {
		font-size: 3em;
		font-weight: 600;
		margin: 0;
	}
</style>