<script lang="ts">
	import { asset } from '$app/paths';
	import { m } from '#lib/paraglide/messages.js';

	type Status = 'idle' | 'loading' | 'running' | 'error';

	let canvas: HTMLCanvasElement;
	let status = $state<Status>('idle');

	// The game only starts on a click: browsers keep audio muted until the user interacts,
	// and it avoids downloading ~10 MB of assets for someone who never plays.
	async function play() {
		status = 'loading';
		try {
			// Emscripten output lives in static/, so it must be loaded at runtime instead of bundled
			const gameUrl = new URL(asset('game/lacobra.js'), location.href);
			const { default: createGame } = await import(/* @vite-ignore */ gameUrl.href);
			await createGame({
				canvas,
				print: () => {},
				// lacobra.wasm and lacobra.data sit next to the script, not next to the page
				locateFile: (file: string) => new URL(file, gameUrl).href
			});
			status = 'running';
		} catch (error) {
			console.error(error);
			status = 'error';
		}
	}

	function onkeydown(event: KeyboardEvent) {
		// Keep the arrow keys from scrolling the page while playing
		if (status === 'running' && event.key.startsWith('Arrow')) event.preventDefault();
	}
</script>

<svelte:head>
	<title>La Minhocobra del Arco-Iro</title>
</svelte:head>

<svelte:window {onkeydown} />

<main
	class="flex min-h-screen flex-col items-center justify-center gap-4 bg-neutral-950 p-4 text-neutral-100"
>
	<h1 class="text-center text-2xl font-bold sm:text-3xl">La Minhocobra del Arco-Iro</h1>
	<p class="max-w-xl text-center text-sm text-neutral-400">{m.game_subtitle()}</p>
	<div class="flex flex-col items-start gap-3 rounded border border-white p-4 text-left">
		<p class="max-w-xl text-sm text-neutral-400">{m.game_instructions_1()}</p>
		<p class="max-w-xl text-sm text-neutral-400">{m.game_instructions_2()}</p>
		<p class="max-w-xl text-sm text-neutral-400">{m.game_instructions_3()}</p>
	</div>

	<div class="relative aspect-5/3 w-full max-w-250 overflow-hidden rounded-lg bg-black">
		<!-- raylib looks the canvas up by this exact id -->
		<canvas
			bind:this={canvas}
			id="canvas"
			class="h-full w-full"
			oncontextmenu={(event) => event.preventDefault()}
		></canvas>

		{#if status !== 'running'}
			<div class="absolute inset-0 flex items-center justify-center bg-black/80">
				{#if status === 'idle'}
					<button
						class="rounded-lg bg-emerald-500 px-8 py-3 text-xl font-bold text-black hover:bg-emerald-400"
						onclick={play}
					>
						{m.game_play()}
					</button>
				{:else if status === 'loading'}
					<p class="animate-pulse text-lg">{m.game_loading()}</p>
				{:else}
					<p class="text-lg text-red-400">{m.game_error()}</p>
				{/if}
			</div>
		{/if}
	</div>

	<p class="text-center text-sm text-neutral-400">{m.game_controls()}</p>
</main>
