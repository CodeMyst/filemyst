<script lang="ts">
    import { createEventDispatcher } from "svelte";

    export let showModal: boolean;
    export let title: string;
    export let submitTitle: string;

    let dialog: HTMLDialogElement;

    const dispatch = createEventDispatcher();

    $: if (dialog && showModal) dialog.showModal();

    const onSubmitClick = () => {
        dispatch('submit');
    };

    export const close = () => {
        dialog.close();
    };
</script>

<!-- svelte-ignore a11y-click-events-have-key-events a11y-no-noninteractive-element-interactions -->
<dialog
    bind:this={dialog}
    on:close={() => (showModal = false)}
    on:click|self={() => dialog.close()}
>
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div on:click|stopPropagation>
        <h3>{title}</h3>

        <slot />

        <div class="buttons">
            <button on:click={onSubmitClick}>{submitTitle}</button>
            <button on:click={() => dialog.close()}>close</button>
        </div>
    </div>
</dialog>

<style>
    dialog {
        max-width: 32em;
        border-radius: var(--border-radius);
        padding: 0;
        background-color: var(--color-bg);
        border: 1px solid var(--color-bg1);
        color: var(--color-fg);
    }

    dialog::backdrop {
        background: rgba(0, 0, 0, 0.3);
    }

    dialog > div {
        padding: 1rem;
    }

    h3 {
        margin-bottom: 1rem;
    }

    button {
        display: block;
    }

    .buttons {
        display: flex;
        gap: 0.5rem;
        margin-top: 1rem;
    }
</style>
