<script lang="ts">
    import { getFiles } from "../api";
    import Files from "./Files.svelte";
    import Header from "./Header.svelte";
    import Footer from "./Footer.svelte";

    export let basePath = "";
</script>

<main>
    <Header {basePath} />

    {#await getFiles(basePath) then files}
        <Files {files} {basePath} />
    {:catch error}
        <p class="error">{error}</p>
    {/await}

    <Footer />
</main>
