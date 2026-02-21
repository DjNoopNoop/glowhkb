import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.open = false
    this._onDocumentClick = this._onDocumentClick.bind(this)
    this._onKeyDown = this._onKeyDown.bind(this)
  }

  toggle(event) {
    event.preventDefault()
    this.open ? this.close() : this.openMenu()
  }

  openMenu() {
    this.element.classList.add('open')
    this.open = true
    const btn = this.element.querySelector('button')
    if (btn) btn.setAttribute('aria-expanded', 'true')
    if (this.hasMenuTarget) this.menuTarget.setAttribute('aria-hidden', 'false')
    document.addEventListener('click', this._onDocumentClick)
    document.addEventListener('keydown', this._onKeyDown)
  }

  close() {
    this.element.classList.remove('open')
    this.open = false
    const btn = this.element.querySelector('button')
    if (btn) btn.setAttribute('aria-expanded', 'false')
    if (this.hasMenuTarget) this.menuTarget.setAttribute('aria-hidden', 'true')
    document.removeEventListener('click', this._onDocumentClick)
    document.removeEventListener('keydown', this._onKeyDown)
  }

  _onDocumentClick(e) {
    if (!this.element.contains(e.target)) this.close()
  }

  _onKeyDown(e) {
    if (e.key === 'Escape') this.close()
  }
}
