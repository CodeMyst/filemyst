<script lang="ts">
    import { onMount } from "svelte";
    import { login } from "../api";
    import { loggedInStore } from "../stores";
    import Modal from "./Modal.svelte";

    let showLoginModal = false;

    let modal: Modal;
    let formElement: HTMLFormElement;
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

        formElement.reset();

        if (ok) {
            loggedInStore.set(true);
            modal.close();
            showLoginModal = false;
        }
    };

    const onLogout = () => {
        localStorage.removeItem('filemyst-token');
        loggedInStore.set(false);
    };
</script>

<header>
    <h1>filemyst</h1>

    {#if loggedIn}
        <button on:click={onLogout}>logout</button>
    {:else}
        <button on:click={() => showLoginModal = true}>login</button>
    {/if}
</header>

{#if !loggedIn}
    <Modal bind:this={modal} bind:showModal={showLoginModal} title="login" submitTitle="login" on:submit={onLogin}>
        {#if invalidLogin}
            <p class="invalid">incorrect username or password</p>
        {/if}
        <form bind:this={formElement} on:submit|preventDefault={onLogin}>
            <input type="text" name="username" id="username" placeholder="username" bind:value={username} />
            <input type="password" name="password" id="password" placeholder="password" bind:value={password} />
            <input type="submit" hidden>
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
</style>
