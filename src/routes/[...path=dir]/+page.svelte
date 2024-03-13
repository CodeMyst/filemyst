<script lang="ts">
    import type { PageData } from "./$types";

    export let data: PageData;
</script>

{#each data.entries as entry}
    <p>{entry.name}{entry.isDir ? '/' : ''}</p>
{/each}
