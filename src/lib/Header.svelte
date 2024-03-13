<script lang="ts">
    import Modal from "./Modal.svelte";

    export let username: string | undefined;

    let showUploadModal = false;
    let uploadModal: Modal;
    let uploadForm: HTMLFormElement;
    let files: FileList;
    let progressBarElement: HTMLElement;
    let uploadInProgress = false;

    let showLoginModal = false;
    let loginButton: HTMLInputElement;

    const onLogin = async () => {
        loginButton.click();
    };

    const onLogout = () => {
    };

    const onUpload = async () => {
    };

    const formatFileList = (fileList: FileList) => {
        let files = [];

        for (let i = 0; i < fileList.length; i++) {
            files.push(fileList.item(i)!.name);
        }

        return files.join(', ');
    };
</script>

<header>
    <h1>filemyst</h1>

    <div class="buttons">
        {#if username}
            <button on:click={() => showUploadModal = true}>upload</button>
            <form method="post" class="logout-form">
                <button class="logout" on:click={onLogout} formaction="?/logout">logout {username}</button>
            </form>
        {:else}
            <button on:click={() => showLoginModal = true}>login</button>
        {/if}
    </div>
</header>

{#if !username}
    <Modal bind:showModal={showLoginModal} title="login" submitTitle="login" on:submit={onLogin}>
        <form method="post">
            <input type="text" name="username" id="username" placeholder="username" />
            <input type="password" name="password" id="password" placeholder="password" />
            <input bind:this={loginButton} type="submit" hidden formaction="?/login">
        </form>
    </Modal>
{/if}

{#if username}
    <Modal bind:this={uploadModal} bind:showModal={showUploadModal} title="upload" submitTitle="upload" on:submit={onUpload}>
        <form bind:this={uploadForm} on:submit|preventDefault={onUpload}>
            <input type="file" name="files[]" id="files" bind:files multiple hidden />
            <label class="file-label" for="files">drop or press to select files</label>
            {#if files}
                <span class="file-list">{formatFileList(files)}</span>
            {/if}
            {#if uploadInProgress}
                <div class="progress-bar">
                    <div class="progress-bar-complete" bind:this={progressBarElement} />
                </div>
            {/if}
        </form>
    </Modal>
{/if}

<style>
    header {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
    }

    h1 {
        font-size: var(--fs-large);
        font-weight: normal;
        margin: 0;
    }

    form {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }

    .logout-form {
        gap: 0;
    }

    .logout {
        height: 100%;
    }

    input {
        width: 15rem;
    }

    .buttons {
        display: flex;
        gap: 1rem;
    }

    .file-label {
        background-color: var(--color-bg1);
        padding: 2rem;
        font-size: var(--fs-small);
        border-radius: var(--border-radius);
        cursor: pointer;
        border: 1px solid var(--color-bg2);
        transition: all 0.1s;
    }

    .file-label:hover {
        background-color: var(--color-bg2);
        border-color: var(--color-bg3);
    }

    .file-list {
        font-size: var(--fs-small);
        max-width: 15rem;
        text-wrap: wrap;
    }

    .progress-bar {
        background-color: var(--color-bg1);
        border: 1px solid var(--color-bg2);
        height: 1rem;
        width: 100%;
        border-radius: var(--border-radius);
    }

    .progress-bar-complete {
        background-color: var(--color-success);
        height: 100%;
        width: 0%;
        transition: width 0.25s;
        border-radius: var(--border-radius);
    }
</style>
