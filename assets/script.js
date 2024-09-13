const allDialogs = document.querySelectorAll("dialog");

const loginDialog = document.getElementById("login-dialog");
const uploaDialog = document.getElementById("upload-dialog");

for (const dialog of allDialogs) {
	dialog.addEventListener("click", (event) => {
		if (event.target === dialog) {
			dialog.close();
		}
	});

	dialog.querySelector(".close").addEventListener("click", () => {
		dialog.close();
	});
}

const loginButton = document.getElementById("login-button");
if (loginButton) {
	loginButton.addEventListener("click", () => {
		loginDialog.showModal();
	});
}

const uploadButton = document.getElementById("upload-button");
if (uploadButton) {
	uploadButton.addEventListener("click", () => {
		uploaDialog.showModal();
	});
}

htmx.on("#upload-form", "htmx:xhr:progress", (event) => {
	htmx.find("#progress-bar").setAttribute("style", `width: ${event.detail.loaded / event.detail.total * 100}%`);

	if (event.detail.loaded === event.detail.total) {
		setTimeout(() => {
			window.location.reload();
		}, 750);
	}
});
