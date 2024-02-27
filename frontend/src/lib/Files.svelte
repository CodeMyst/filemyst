<script lang="ts">
    import { Link } from "svelte-routing";
    import { deleteFile, getFiles, type FileInfo, renameFile } from "../api";
    import { loggedInStore } from "../stores";
    import { onMount } from "svelte";
    import Modal from "./Modal.svelte";

    export let files: FileInfo[];
    export let basePath: string;

    let isLoggedIn = false;

    let showRenameModal = false;
    let renameModal: Modal;
    let currentRenamingFile: FileInfo;
    let newFileName: string;

    onMount(async () => {
        loggedInStore.subscribe(async (value) => {
            isLoggedIn = value;

            files = await getFiles(basePath);
        });

        if (basePath.startsWith('.')) {
            basePath = '/' + basePath;
        }
    });

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

    const canDeleteOrRenameFile = (file: string) => {
        if (basePath.includes('.trash') || file === '.trash') return false;

        return true;
    };

    const onDelete = async (file: string) => {
        await deleteFile(basePath + '/' + file);

        files = await getFiles(basePath);
    };

    const onRenameButton = (file: FileInfo) => {
        currentRenamingFile = file;
        showRenameModal = true;
    };

    const onRename = async () => {
        await renameFile(basePath + '/' + currentRenamingFile.name, newFileName);
        renameModal.close();
        showRenameModal = false;

        files = await getFiles(basePath);
    };
</script>

<div class="index">
    <table>
        <thead>
            <th>name</th>
            {#if isLoggedIn}
                <th></th>
                <th></th>
            {/if}
            <th>size</th>
            <th>last modified</th>
        </thead>
        <tbody>
            {#if basePath !== ''}
                <tr>
                    <td><Link to={parentDir(basePath)} class="dir">../</Link></td>
                    {#if isLoggedIn}
                        <td></td>
                        <td></td>
                    {/if}
                    <td></td>
                    <td></td>
                </tr>
            {/if}
            {#each files as file}
                <tr>
                    {#if file.is_dir}
                        <td><Link to={basePath + '/' + file.name} class="file dir">{file.name}/</Link></td>
                    {:else}
                        <td><a class="file" href={`${import.meta.env.VITE_API_URL}${basePath ? '/' + basePath : ''}/${file.name}`}>{file.name}</a></td>
                    {/if}

                    {#if isLoggedIn}
                        <td>
                            {#if canDeleteOrRenameFile(file.name)}
                                <button class="rename" on:click={() => onRenameButton(file)}>ren</button>
                            {/if}
                        </td>
                        <td>
                            {#if canDeleteOrRenameFile(file.name)}
                                <button class="delete" on:click={() => onDelete(file.name)}>del</button>
                            {/if}
                        </td>
                    {/if}

                    <td>{formatSize(file.size)}</td>
                    <td>{formatDate(file.last_modified)}</td>
                </tr>
            {/each}
        </tbody>
    </table>
</div>

{#if isLoggedIn && currentRenamingFile}
    <Modal bind:this={renameModal} bind:showModal={showRenameModal} title={`rename ${currentRenamingFile.name}`} submitTitle="rename" on:submit={onRename}>
        <form on:submit|preventDefault={onRename}>
            <input type="text" placeholder="new name" name="new_name" bind:value={newFileName} />
            <input type="submit" hidden />
        </form>
    </Modal>
{/if}

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

    tr:hover .delete,
    tr:hover .rename {
        opacity: 1;
    }

    .delete,
    .rename {
        opacity: 0;
        border: none;
        padding: 0.1rem;
        font-size: var(--fs-small);
    }

    .delete {
        color: var(--color-danger);
    }

    .rename {
        color: var(--color-primary);
    }

    .delete:hover {
        background-color: var(--color-danger);
        color: var(--color-bg1);
    }

    .rename:hover {
        background-color: var(--color-primary);
        color: var(--color-bg1);
    }
</style>

