<script lang="ts">
	import type { Path } from '$app/types';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { locales, localizeHref } from '#lib/paraglide/runtime.js';
	import Seo from '#lib/components/seo/Seo.svelte';
	import './layout.css';

	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();
</script>

<Seo />

{@render children()}

<div style="display:none">
	{#each locales as locale (locale)}
		<a href={resolve(localizeHref(page.url.pathname, { locale }) as Path)}>{locale}</a>
	{/each}
</div>
