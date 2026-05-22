import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subtotal", "deliveryFee", "grandTotal", "vatAmount", "distanceKm"]

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

  selectDeliveryMode(event) {
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
    const safeDeliveryFee = deliveryFee === null ? 0 : deliveryFee

    this.deliveryFeeTarget.textContent = this.formatCurrency(safeDeliveryFee)

    const subtotal = this.parseAmount(this.subtotalTarget.textContent)
    const vat = (subtotal + safeDeliveryFee) * this.vatRateValue
    const total = subtotal + safeDeliveryFee + vat

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
