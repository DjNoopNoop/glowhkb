import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]

  connect() {
    this.debounceTimer = null
    this.endpoint = '/search'
  }

  query() {
    clearTimeout(this.debounceTimer)
    const q = this.inputTarget.value.trim()
    if (q.length === 0) { this.clearResults(); return }
    this.debounceTimer = setTimeout(() => this.search(q), 250)
  }

  async search(q) {
    try {
      const res = await fetch(`${this.endpoint}?q=${encodeURIComponent(q)}`, { headers: { Accept: 'application/json' } })
      if (!res.ok) { this.clearResults(); return }
      const data = await res.json()
      this.showResults(data, q)
    } catch (err) {
      this.clearResults()
    }
  }

  appendHighlighted(el, text, q) {
    const lowerText = text.toLowerCase()
    const lowerQ = q.toLowerCase()
    let start = 0
    let idx = lowerText.indexOf(lowerQ, start)
    if (idx === -1) { el.appendChild(document.createTextNode(text)); return }
    while (idx !== -1) {
      if (idx > start) el.appendChild(document.createTextNode(text.slice(start, idx)))
      const strong = document.createElement('strong')
      strong.textContent = text.slice(idx, idx + q.length)
      el.appendChild(strong)
      start = idx + q.length
      idx = lowerText.indexOf(lowerQ, start)
    }
    if (start < text.length) el.appendChild(document.createTextNode(text.slice(start)))
  }

  showResults(items, q) {
    if (!items || items.length === 0) { this.clearResults(); return }
    const ul = document.createElement('ul')
    ul.className = 'search-results-list'
    items.forEach(item => {
      const li = document.createElement('li')
      li.className = 'search-result'
      const a = document.createElement('a')
      a.href = item.url
      a.className = 'search-result-link'
      const title = document.createElement('span')
      title.className = 'search-result-title'
      this.appendHighlighted(title, item.title, q)
      const meta = document.createElement('span')
      meta.className = 'search-result-meta'
      meta.textContent = item.type
      a.appendChild(title)
      a.appendChild(meta)
      li.appendChild(a)
      ul.appendChild(li)
    })
    this.resultsTarget.innerHTML = ''
    this.resultsTarget.appendChild(ul)
    this.resultsTarget.hidden = false
  }

  clearResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = ''
      this.resultsTarget.hidden = true
    }
  }

  keydown(e) {
    if (e.key === 'Escape') { this.clearResults(); this.inputTarget.blur(); }
  }
}
