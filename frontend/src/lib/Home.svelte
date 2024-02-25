<script lang="ts">
    import { getFiles } from "../api";
    import Files from "./Files.svelte";
    import Header from "./Header.svelte";

    export let basePath = "";
</script>

<main>
    <Header />

    {#await getFiles(basePath) then files}
        <Files {files} {basePath} />
    {:catch error}
        <p class="error">{error}</p>
    {/await}
</main>
