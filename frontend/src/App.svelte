<script lang="ts">
    import { Router, Route } from "svelte-routing";
    import Home from "./lib/Home.svelte";

    export let url = "";
</script>

<Router {url}>
    <Route path="/*basePath" let:params><Home basePath="{params.basePath}" /></Route>
</Router>
