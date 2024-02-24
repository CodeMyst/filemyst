<script lang="ts">
    import Modal from "./Modal.svelte";

    let showLoginModal = false;

    let formElement: HTMLFormElement;

    const onLogin = () => {
        formElement.submit();
    };
</script>

<header>
    <h1>filemyst</h1>

    <button on:click={() => showLoginModal = true}>login</button>
</header>

<Modal bind:showModal={showLoginModal} title="login" submitTitle="login" on:submit={onLogin}>
    <form bind:this={formElement}>
        <input type="text" name="username" id="username" placeholder="username" />
        <input type="password" name="password" id="password" placeholder="password" />
        <input type="submit" hidden>
    </form>
</Modal>

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
</style>
