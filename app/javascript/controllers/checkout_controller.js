import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subtotal", "deliveryFee", "grandTotal", "vatAmount", "distanceKm", "deliveryStatus"]

  static values = {
    tierOneMaxKm: Number,
    tierOneFee: Number,
    tierTwoMaxKm: Number,
    tierTwoFee: Number,
    vatRate: Number
  }

  connect() {
    const submitButton = this.element.querySelector('button[type="submit"]')
    if (submitButton && !submitButton.dataset.defaultLabel) {
      submitButton.dataset.defaultLabel = submitButton.textContent
    }

    this.updateGrandTotal()
  }

  selectDeliveryMode() {
    this.updateGrandTotal()
  }

  updateDistance() {
    this.updateGrandTotal()
  }

  deliveryFeeFor(mode, distanceKm) {
    if (mode !== "delivery") return 0
    if (distanceKm <= this.tierOneMaxKmValue) return this.tierOneFeeValue
    if (distanceKm <= this.tierTwoMaxKmValue) return this.tierTwoFeeValue

    return null
  }

  updateDeliveryAvailability(mode, distanceKm) {
    const submitButton = this.element.querySelector('button[type="submit"]')

    if (!submitButton) return

    if (this.hasDistanceKmTarget) {
      this.distanceKmTarget.disabled = mode !== "delivery"
    }

    if (this.hasDeliveryStatusTarget) {
      this.deliveryStatusTarget.classList.remove("is-muted", "is-warning", "is-success")

      if (mode !== "delivery") {
        this.deliveryStatusTarget.textContent = "Retrait sur place gratuit, prêt en 15 à 20 minutes."
        this.deliveryStatusTarget.classList.add("is-success")
      } else if (distanceKm > this.tierTwoMaxKmValue) {
        this.deliveryStatusTarget.textContent = `Livraison indisponible au-delà de ${this.tierTwoMaxKmValue} km. Passez en retrait sur place pour continuer.`
        this.deliveryStatusTarget.classList.add("is-warning")
      } else if (distanceKm > this.tierOneMaxKmValue) {
        this.deliveryStatusTarget.textContent = `Vous êtes dans la zone étendue: frais de livraison majorés jusqu'à ${this.tierTwoMaxKmValue} km.`
        this.deliveryStatusTarget.classList.add("is-muted")
      } else {
        this.deliveryStatusTarget.textContent = `Vous êtes dans la zone standard: livraison disponible jusqu'à ${this.tierOneMaxKmValue} km.`
        this.deliveryStatusTarget.classList.add("is-success")
      }
    }

    if (mode === "delivery" && distanceKm > this.tierTwoMaxKmValue) {
      submitButton.disabled = true
      submitButton.textContent = `Livraison indisponible > ${this.tierTwoMaxKmValue} km`
      return
    }

    submitButton.disabled = false
    submitButton.textContent = submitButton.dataset.defaultLabel || "💳 Passer la commande"
  }

  selectedDeliveryMode() {
    const selected = this.element.querySelector('input[name="delivery_mode"]:checked')
    return selected ? selected.value : "delivery"
  }

  updateGrandTotal() {
    if (!(this.hasSubtotalTarget && this.hasDeliveryFeeTarget && this.hasGrandTotalTarget && this.hasVatAmountTarget)) {
      return
    }

    const mode = this.selectedDeliveryMode()
    const distanceKm = this.hasDistanceKmTarget ? parseFloat(this.distanceKmTarget.value || "0") : 0
    const deliveryFee = this.deliveryFeeFor(mode, distanceKm)
    const subtotal = this.parseAmount(this.subtotalTarget.textContent)

    if (deliveryFee === null) {
      const vat = subtotal * this.vatRateValue
      const total = subtotal + vat

      this.deliveryFeeTarget.textContent = "Indisponible"
      this.vatAmountTarget.textContent = this.formatCurrency(vat)
      this.grandTotalTarget.textContent = this.formatCurrency(total)
      this.updateDeliveryAvailability(mode, distanceKm)
      return
    }

    const vat = (subtotal + deliveryFee) * this.vatRateValue
    const total = subtotal + deliveryFee + vat

    this.deliveryFeeTarget.textContent = this.formatCurrency(deliveryFee)
    this.vatAmountTarget.textContent = this.formatCurrency(vat)
    this.grandTotalTarget.textContent = this.formatCurrency(total)
    this.updateDeliveryAvailability(mode, distanceKm)
  }

  parseAmount(value) {
    return parseFloat(value.replace(/[^\d,.-]/g, "").replace(",", ".")) || 0
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("fr-FR", {
      style: "currency",
      currency: "EUR"
    }).format(value)
  }
}
