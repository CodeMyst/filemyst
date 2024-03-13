<script lang="ts">
    import Header from '$lib/Header.svelte';
    import '../app.css';
    import type { LayoutServerData } from './$types';

    export let data: LayoutServerData;
</script>

<Header username={data.username} />

<slot />
