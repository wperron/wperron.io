<script>
	export let title
	export let src
	export let desc
</script>

<section class='title'>
	<img src={src} alt={desc} width="100px" />
	<div>
		<h1>{title}</h1>
		<p>Software Developer, DevOps Advocate, Git ninja and Cloud Computing Enthusiast.</p>
	</div>
</section>

<style>
	.title {
		display: flex;
		margin: 30px 0;
	}

	.title img {
		margin-right: 20px;
		display: block;
		max-width:230px;
		max-height:95px;
		min-width: 100px;
		width: auto;
		height: auto;
	}

	.title h1 {
		font-size: 3em;
		font-weight: 600;
		margin: 0;
	}

	@media only screen and (max-width: 400px) {
		.title {
			display: flex;
			flex-direction: column;
			margin: 30px 0;
		}

		.title img {
			margin-right: auto;
			display: block;
			max-width:230px;
			max-height:95px;
			width: auto;
			height: auto;
		}
	}
</style>
