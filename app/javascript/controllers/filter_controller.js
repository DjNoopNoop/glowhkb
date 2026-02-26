import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "menu", "dropdown", "clearButton", "panel", "toggleButton"]

  connect() {
    this.boundDocumentClick = this.documentClick.bind(this)
    document.addEventListener('click', this.boundDocumentClick)
    // initialize badges based on any server-rendered checked inputs
    this.updateBadges()
    // set CSS header height var so filter can position under header without affecting layout
    this.setHeaderHeightVar()
    this._resizeHandler = () => this.setHeaderHeightVar()
    window.addEventListener('resize', this._resizeHandler)

    // ensure toggle button aria reflects initial collapsed state
    if (this.hasToggleButtonTarget && this.hasPanelTarget) {
      const collapsed = this.panelTarget.classList.contains('collapsed')
      this.toggleButtonTarget.setAttribute('aria-expanded', (!collapsed).toString())
    }
  }

  disconnect() {
    document.removeEventListener('click', this.boundDocumentClick)
    window.removeEventListener('resize', this._resizeHandler)
  }

  setHeaderHeightVar() {
    const header = document.querySelector('.site-header')
    if (!header) return
    const h = header.getBoundingClientRect().height || 64
    this.element.style.setProperty('--header-height', `${Math.round(h)}px`)
  }

  toggle(event) {
    event.stopPropagation()
    const button = event.currentTarget
    const dropdown = button.closest('.filter-dropdown')
    const menu = dropdown.querySelector('.filter-menu')
    const expanded = button.getAttribute('aria-expanded') === 'true'
    // If we're opening this menu, close any other open menus first
    if (!expanded) {
      const allMenus = document.querySelectorAll('.filter-menu')
      allMenus.forEach(m => {
        if (m !== menu) {
          m.style.display = 'none'
          const dd = m.closest('.filter-dropdown')
          const btn = dd && dd.querySelector('.filter-button')
          if (btn) btn.setAttribute('aria-expanded', 'false')
        }
      })
    }

    button.setAttribute('aria-expanded', (!expanded).toString())
    menu.style.display = expanded ? 'none' : 'block'
  }

  documentClick(e) {
    // only close menus if click was outside the filter element
    if (this.element.contains(e.target)) return
    const menus = this.element.querySelectorAll('.filter-menu')
    menus.forEach(menu => { menu.style.display = 'none' })
    const buttons = this.element.querySelectorAll('.filter-button')
    buttons.forEach(btn => btn.setAttribute('aria-expanded', 'false'))
  }

  changed(event) {
    event.stopPropagation()
    const input = event.currentTarget
    const label = input.closest('.filter-item-label')
    if (input.checked) {
      label.classList.add('selected')
    } else {
      label.classList.remove('selected')
    }
    this.updateClearState()
    this.fetchMap()
    this.updateBadges()
  }

  updateClearState() {
    const anyChecked = Array.from(this.inputTargets).some(i => i.checked)
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.disabled = !anyChecked
    }
  }

  clear() {
    this.inputTargets.forEach(i => { i.checked = false; i.closest('.filter-item-label').classList.remove('selected') })
    this.updateClearState()
    this.fetchMap()
    this.updateBadges()
  }

  fetchMap() {
    // Gather params from each dropdown (each dropdown has inputs with name like param_key[])
    const params = new URLSearchParams()

    const dropdowns = this.element.querySelectorAll('[data-filter-target="dropdown"]')
    dropdowns.forEach(dd => {
      const key = dd.dataset.filterParamKey
      const checked = Array.from(dd.querySelectorAll('input:checked')).map(i => i.value)
      checked.forEach(v => params.append(`${key}[]`, v))
    })

    // request publications JSON and dispatch update to the map controller
    const url = `/global/map.json?${params.toString()}`
    fetch(url, { headers: { 'Accept': 'application/json' } })
      .then(r => r.json())
      .then(pubs => {
        const mapEl = document.querySelector('#mapbox-map')
        if (mapEl) {
          mapEl.dispatchEvent(new CustomEvent('filter:update', { detail: { publications: pubs } }))
        }
      }).catch(e => { console.error('Failed to fetch publications JSON', e) })
  }

  updateBadges() {
    const dropdowns = this.element.querySelectorAll('[data-filter-target="dropdown"]')
    dropdowns.forEach(dd => {
      const checked = dd.querySelectorAll('input:checked').length
      const button = dd.querySelector('.filter-button')
      const badge = button && button.querySelector('.filter-badge')
      const countEl = badge && badge.querySelector('.filter-badge-count')
      if (!badge || !countEl) return
      if (checked > 0) {
        countEl.textContent = String(checked)
        badge.classList.add('visible')
      } else {
        badge.classList.remove('visible')
      }
    })
  }

  togglePanel(event) {
    event.preventDefault()
    const panel = this.panelTarget
    const toggle = this.toggleButtonTarget
    if (!panel || !toggle) return
    const collapsed = panel.classList.toggle('collapsed')
    // also collapse the outer container so it doesn't leave whitespace
    this.element.classList.toggle('collapsed', collapsed)
    // close any open dropdowns when collapsing
    if (collapsed) {
      const menus = this.element.querySelectorAll('.filter-menu')
      menus.forEach(menu => { menu.style.display = 'none' })
      const buttons = this.element.querySelectorAll('.filter-button')
      buttons.forEach(btn => btn.setAttribute('aria-expanded', 'false'))
    }
    toggle.setAttribute('aria-expanded', (!collapsed).toString())
  }
}
