<script lang="ts">
    import { Link } from "svelte-routing";
    import type { FileInfo } from "../api";

    export let files: FileInfo[];
    export let basePath: string;

    const formatDate = (dateString: string) => {
        const date = new Date(dateString);
        const day = date.getDate().toLocaleString('default', { minimumIntegerDigits: 2 });
        const month = date.toLocaleString('default', { month: 'short' }).toLowerCase();
        const year = date.getFullYear();
        const hours = date.getHours().toLocaleString('default', { minimumIntegerDigits: 2 });
        const minutes = date.getMinutes().toLocaleString('default', { minimumIntegerDigits: 2 });
        const seconds = date.getSeconds().toLocaleString('default', { minimumIntegerDigits: 2 });
        return `${day}-${month}-${year} ${hours}:${minutes}:${seconds}`;
    };

    const formatSize = (bytes: number) => {
        const thresh = 1000;

        if (Math.abs(bytes) < thresh) {
            return bytes + 'b';
        }

        const units = ['kb', 'mb', 'gb', 'tb'];
        let u = -1;
        const r = 10**2;

        do {
            bytes /= thresh;
            ++u;
        } while (Math.round(Math.abs(bytes) * r) / r >= thresh && u < units.length - 1);


        return bytes.toFixed(2) + units[u];
    };

    const parentDir = (path: string) => {
        return path.split("/").slice(0, -1).join("/");
    };
</script>

<div class="index">
    <table>
        <thead>
            <th>name</th>
            <th>size</th>
            <th>last modified</th>
        </thead>
        <tbody>
            {#if basePath !== ''}
                <tr>
                    <td><Link to={parentDir(basePath)} class="dir">../</Link></td>
                    <td></td>
                    <td></td>
                </tr>
            {/if}
            {#each files as file}
                <tr>
                    {#if file.is_dir}
                        <td><Link to={basePath + '/' + file.name} class="dir">{file.name}/</Link></td>
                    {:else}
                        <td><a href={`${import.meta.env.VITE_API_URL}${basePath ? '/' + basePath : ''}/${file.name}`}>{file.name}</a></td>
                    {/if}
                    <td>{formatSize(file.size)}</td>
                    <td>{formatDate(file.last_modified)}</td>
                </tr>
            {/each}
        </tbody>
    </table>
</div>

<style>
    .index {
        background-color: var(--color-bg1);
        border-radius: var(--border-radius);
        border: 1px solid var(--color-bg2);
        margin-top: 1rem;
    }

    table {
        width: 100%;
        border-spacing: 0;
        border-collapse: collapse;
        font-size: var(--fs-normal);
    }

    thead {
        border-bottom: 1px solid var(--color-bg2);
    }

    th, td {
        padding: 0.25rem 0.5rem;
        text-align: right;
        font-weight: normal;
    }

    td:first-child, th:first-child {
        text-align: left;
        width: auto;
    }

    td :global(a) {
        display: block;
        color: var(--color-fg);
        text-decoration: none;
    }

    td :global(a.dir) {
        color: var(--color-secondary);
    }

    td :global(a:hover) {
        text-decoration: underline;
    }
</style>

