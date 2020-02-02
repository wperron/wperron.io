<script>
	export let date
	$: dateobj = new Date(date)
</script>

<p>
	<i><time datetime={date}>{dateobj.toDateString()}</time></i>
</p>

<style>
	p {
		margin: 0;
	}
</style>