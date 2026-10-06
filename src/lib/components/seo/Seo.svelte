<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
</script>

<svelte:head>
	<link rel="icon" href="/ico/favicon.ico" />
	<link rel="apple-touch-icon" sizes="180x180" href="/ico/apple-touch-icon.png" />
	<link rel="icon" type="image/png" sizes="32x32" href="/ico/favicon-32x32.png" />
	<link rel="icon" type="image/png" sizes="16x16" href="/ico/favicon-16x16.png" />
	<link rel="manifest" href="/ico/site.webmanifest" />
	<title>LAMINHOCOBRA</title>
	<meta name="description" content={m.description()} />
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<meta charset="utf-8" />
	<link rel="canonical" href="https://laminhocobra.plup.dev" />

	<meta property="og:title" content="LAMINHOCOBRA" />
	<meta property="og:description" content={m.description()} />
	<meta property="og:url" content="https://laminhocobra.plup.dev" />
	<meta property="og:type" content="website" />

	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="LAMINHOCOBRA" />
	<meta name="twitter:description" content={m.description()} />

	<meta name="robots" content="index, follow" />
</svelte:head>
