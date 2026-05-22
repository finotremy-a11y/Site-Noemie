import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemsList"]

  increaseQuantity(event) {
    const itemId = event.currentTarget.dataset.itemId
    const input = document.querySelector(`input[data-item-id="${itemId}"]`)
    const newQty = parseInt(input.value) + 1
    this.updateItem(itemId, newQty)
  }

  decreaseQuantity(event) {
    const itemId = event.currentTarget.dataset.itemId
    const input = document.querySelector(`input[data-item-id="${itemId}"]`)
    const newQty = Math.max(1, parseInt(input.value) - 1)
    this.updateItem(itemId, newQty)
  }

  removeItem(event) {
    const itemId = event.currentTarget.dataset.itemId
    if (confirm("Supprimer cet article?")) {
      this.deleteItem(itemId)
    }
  }

  updateItem(itemId, quantity) {
    const form = new FormData()
    form.append("quantity", quantity)

    fetch(`/cart/items/${itemId}`, {
      method: "PATCH",
      body: form,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(res => {
        if (res.ok) window.location.reload()
      })
      .catch(err => console.error("Erreur:", err))
  }

  deleteItem(itemId) {
    fetch(`/cart/items/${itemId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(res => {
        if (res.ok) window.location.reload()
      })
      .catch(err => console.error("Erreur:", err))
  }

  checkout(event) {
    event.preventDefault()
    window.location.href = "/checkout"
  }
}
