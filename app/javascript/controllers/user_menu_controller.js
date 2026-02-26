import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.open = this.element.classList.contains('open') || false
    this._onDocumentClick = this._onDocumentClick.bind(this)
    this._onKeyDown = this._onKeyDown.bind(this)
    this._onMouseLeave = this._onMouseLeave.bind(this)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    if (this.element.classList.contains('open')) {
      this.close()
    } else {
      this.openMenu()
    }
  }

  openMenu() {
    this.element.classList.add('open')
    // ensure any temporary force-hide is removed when explicitly opening
    this.element.classList.remove('force-hide')
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
    if (btn && typeof btn.blur === 'function') btn.blur()
    // if menu was opened by hover, hovering may still apply :hover/:focus-within
    // add a temporary class to override hover styles until the pointer leaves
    this.element.classList.add('force-hide')
    this.element.addEventListener('mouseleave', this._onMouseLeave)
    if (this.hasMenuTarget) this.menuTarget.setAttribute('aria-hidden', 'true')
    document.removeEventListener('click', this._onDocumentClick)
    document.removeEventListener('keydown', this._onKeyDown)
  }

  _onMouseLeave() {
    this.element.classList.remove('force-hide')
    this.element.removeEventListener('mouseleave', this._onMouseLeave)
  }

  _onDocumentClick(e) {
    if (!this.element.contains(e.target)) this.close()
  }

  _onKeyDown(e) {
    if (e.key === 'Escape') this.close()
  }
}
