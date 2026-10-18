import { Turbo } from "@hotwired/turbo-rails"

Turbo.config.forms.confirm = (message) => {
  const dialog = document.getElementById("confirm_dialog")
  if (!dialog) return Promise.resolve(window.confirm(message))

  dialog.querySelector("[data-confirm-message]").textContent = message
  dialog.returnValue = ""
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
  })
}
