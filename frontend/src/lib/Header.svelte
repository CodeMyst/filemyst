<script lang="ts">
    import { onMount } from "svelte";
    import { login } from "../api";
    import { loggedInStore } from "../stores";
    import Modal from "./Modal.svelte";

    export let basePath = '';

    let showUploadModal = false;
    let uploadModal: Modal;
    let uploadForm: HTMLFormElement;
    let files: FileList;
    let progressBarElement: HTMLElement;
    let uploadInProgress = false;

    let showLoginModal = false;
    let loginModal: Modal;
    let loginForm: HTMLFormElement;
    let username: string;
    let password: string;
    let invalidLogin = false;

    let loggedIn = false;

    onMount(() => {
        if (localStorage.getItem('filemyst-token'))  {
            loggedInStore.set(true);
        }

        loggedInStore.subscribe((value) => {
            loggedIn = value;
        });
    });

    const onLogin = async () => {
        const ok = await login(username, password);

        invalidLogin = !ok;

        loginForm.reset();

        if (ok) {
            loggedInStore.set(true);
            loginModal.close();
            showLoginModal = false;
        }
    };

    const onLogout = () => {
        localStorage.removeItem('filemyst-token');
        loggedInStore.set(false);
    };

    const onUpload = async () => {
        const formData = new FormData();

        for (let i = 0; i < files.length; i++) {
            formData.append('files[]', files[i]);
        }

        const xhr = new XMLHttpRequest();
        xhr.open('post', `${import.meta.env.VITE_API_URL}${basePath ? '/' + basePath : ''}`, true);

        xhr.upload.onprogress = (e) => {
            if (e.lengthComputable) {
                let percentComplete = (e.loaded / e.total) * 100;
                progressBarElement.style.width = `${percentComplete}%`;
            }
        };

        xhr.upload.onloadend = () => {
            uploadInProgress = false;
            uploadModal.close();
            showUploadModal = false;
            window.location.reload();
        };

        xhr.setRequestHeader('Authorization', `Bearer ${localStorage.getItem('filemyst-token')}`);

        xhr.send(formData);

        uploadInProgress = true;
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
        {#if loggedIn}
            <button on:click={() => showUploadModal = true}>upload</button>
            <button on:click={onLogout}>logout</button>
        {:else}
            <button on:click={() => showLoginModal = true}>login</button>
        {/if}
    </div>
</header>

{#if !loggedIn}
    <Modal bind:this={loginModal} bind:showModal={showLoginModal} title="login" submitTitle="login" on:submit={onLogin}>
        {#if invalidLogin}
            <p class="invalid">incorrect username or password</p>
        {/if}
        <form bind:this={loginForm} on:submit|preventDefault={onLogin}>
            <input type="text" name="username" id="username" placeholder="username" bind:value={username} />
            <input type="password" name="password" id="password" placeholder="password" bind:value={password} />
            <input type="submit" hidden>
        </form>
    </Modal>
{/if}

{#if loggedIn}
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

    input {
        width: 15rem;
    }

    .invalid {
        background-color: var(--color-danger);
        font-size: var(--fs-small);
        color: var(--color-bg);
        padding: 0.25rem 0.5rem;
        border-radius: var(--border-radius);
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
