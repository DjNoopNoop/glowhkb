import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list", "suggestions", "hiddenId"]
  static values = { url: String, single: Boolean, fieldName: String }

  connect() {
    this.listTarget ||= null
  }

  async search() {
    const q = this.inputTarget.value
    if (!this.urlValue) return
    if (q.length === 0) { this.clearSuggestions(); return }
    const res = await fetch(`${this.urlValue}?q=${encodeURIComponent(q)}`)
    if (!res.ok) return
    const json = await res.json()
    this.showSuggestions(json)
  }

  showSuggestions(items) {
    this.clearSuggestions()
    items.forEach(i => {
      const el = document.createElement('div')
      el.className = 'suggestion-item'
      el.textContent = i.name
      el.dataset.id = i.id
      el.addEventListener('click', () => this.chooseSuggestion(i))
      this.suggestionsTarget.appendChild(el)
    })
  }

  chooseSuggestion(item) {
    if (this.singleValue) {
      // set text and hidden id
      if (this.inputTarget) this.inputTarget.value = item.name
      if (this.hasHiddenIdTarget) this.hiddenIdTarget.value = item.id
      this.clearSuggestions()
      return
    }
    this.addTag(item.name)
    this.inputTarget.value = ''
    this.clearSuggestions()
  }

  keydown(e) {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault()
      const v = this.inputTarget.value.trim()
      if (v.length > 0) this.addTag(v)
      this.inputTarget.value = ''
      this.clearSuggestions()
    }
  }

  addTag(name) {
    // append span to listTarget and hidden input
    const span = document.createElement('span')
    span.className = 'tag'
    span.textContent = name + ' '

    const btn = document.createElement('button')
    btn.type = 'button'
    btn.textContent = '×'
    btn.addEventListener('click', () => span.remove())
    span.appendChild(btn)

    const input = document.createElement('input')
    input.type = 'hidden'
    // use configured fieldNameValue when available
    let fieldName = this.fieldNameValue || this.element.querySelector('input')?.getAttribute('name') || 'publication[items][]'
    input.name = fieldName.includes('[]') ? fieldName : fieldName + '[]'
    input.value = name
    span.appendChild(input)

    if (this.listTarget) this.listTarget.appendChild(span)
  }

  remove(e) {
    const span = e.currentTarget.closest('span')
    if (span) span.remove()
  }

  clearSuggestions() {
    if (!this.hasSuggestionsTarget) return
    this.suggestionsTarget.innerHTML = ''
  }
}
