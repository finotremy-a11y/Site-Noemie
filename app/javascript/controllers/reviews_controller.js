import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  flagReview(event) {
    const reviewId = event.currentTarget.dataset.reviewId

    if (confirm("Signaler cet avis?")) {
      const form = new FormData()
      form.append("reported", true)

      fetch(`/reviews/${reviewId}/flag`, {
        method: "PATCH",
        body: form,
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })
        .then(res => {
          if (res.ok) {
            alert("Avis signalé. Merci!")
            event.currentTarget.disabled = true
          }
        })
        .catch(err => console.error("Erreur:", err))
    }
  }

  filterByRating(event) {
    const minRating = event.currentTarget.value
    const params = new URLSearchParams()
    if (minRating) params.append("min_rating", minRating)
    window.location.href = `${window.location.pathname}?${params.toString()}`
  }
}
