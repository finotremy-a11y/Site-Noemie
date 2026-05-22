import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categoryFilter", "searchFilter", "priceFilter", "productsContainer"]

  filterByCategory(event) {
    this.applyFilters()
  }

  filterBySearch(event) {
    this.applyFilters()
  }

  filterByPrice(event) {
    const priceDisplay = document.getElementById("price-display")
    const maxPrice = event.target.value
    priceDisplay.textContent = `0€ - ${maxPrice}€`
    this.applyFilters()
  }

  applyFilters() {
    const categoryId = this.categoryFilterTarget?.value || ""
    const search = this.searchFilterTarget?.value || ""
    const maxPrice = this.priceFilterTarget?.value || "50"

    const params = new URLSearchParams()
    if (categoryId) params.append("category_id", categoryId)
    if (search) params.append("search", search)
    if (maxPrice !== "50") params.append("max_price", maxPrice)

    const query = params.toString()
    const url = query.length > 0 ? `${window.location.pathname}?${query}` : window.location.pathname
    window.history.replaceState({}, "", url)

    // Optionnel: reload full page ou fetch partial (pour maintenant, full page)
    window.location.href = url
  }

  resetFilters(event) {
    event.preventDefault()
    if (this.categoryFilterTarget) this.categoryFilterTarget.value = ""
    if (this.searchFilterTarget) this.searchFilterTarget.value = ""
    if (this.priceFilterTarget) this.priceFilterTarget.value = "50"
    window.location.href = window.location.pathname
  }

  addToCart(event) {
    const productId = event.currentTarget.dataset.productId
    const productName = event.currentTarget.dataset.productName

    // Simple: POST to add_item action
    const form = new FormData()
    form.append("product_id", productId)
    form.append("quantity", 1)

    fetch("/cart/items", {
      method: "POST",
      body: form,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(res => {
        if (res.ok) {
          alert(`${productName} ajouté au panier!`)
          this.updateCartCount()
        }
      })
      .catch(err => console.error("Erreur:", err))
  }

  updateCartCount() {
    // Fetch cart count from API or session
    fetch("/cart")
      .then(res => res.text())
      .then(html => {
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const count = doc.querySelectorAll(".cart-item").length
        const badge = document.getElementById("cart-count")
        if (badge) {
          badge.textContent = count
          badge.style.display = count > 0 ? "inline-block" : "none"
        }
      })
  }
}
