// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const setupMobileNavigation = () => {
	document.querySelectorAll("[data-nav-root]").forEach((root) => {
		if (root.dataset.navBound === "true") return

		const toggle = root.querySelector("[data-nav-toggle]")
		const panel = root.querySelector("[data-nav-panel]")
		if (!toggle || !panel) return

		const closeMenu = () => {
			root.classList.remove("is-open")
			toggle.setAttribute("aria-expanded", "false")
			document.body.classList.remove("no-scroll")
		}

		toggle.addEventListener("click", () => {
			const willOpen = !root.classList.contains("is-open")
			root.classList.toggle("is-open", willOpen)
			toggle.setAttribute("aria-expanded", String(willOpen))
			document.body.classList.toggle("no-scroll", willOpen)
		})

		panel.querySelectorAll("a").forEach((link) => {
			link.addEventListener("click", closeMenu)
		})

		document.addEventListener("keydown", (event) => {
			if (event.key === "Escape") closeMenu()
		})

		root.dataset.navBound = "true"
	})
}

document.addEventListener("turbo:load", setupMobileNavigation)
document.addEventListener("DOMContentLoaded", setupMobileNavigation)
