import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "menu", "dropdown", "clearButton", "panel", "toggleButton"]

  connect() {
    this.boundDocumentClick = this.documentClick.bind(this)
    document.addEventListener('click', this.boundDocumentClick)
    // initialize badges based on any server-rendered checked inputs
    // load persisted filters, panel and dropdown states (if any) before updating UI
    this.loadPanelState()
    this.loadFilters()
    this.loadDropdownStates()
    // set CSS header height var so filter can position under header without affecting layout
    this.setHeaderHeightVar()
    this._resizeHandler = () => this.setHeaderHeightVar()
    window.addEventListener('resize', this._resizeHandler)

    // Persist dropdown states reliably before Turbo navigations and on unload
    this._saveDropdownsBeforeVisit = this.saveAllDropdownStates.bind(this)
    window.addEventListener('turbo:before-visit', this._saveDropdownsBeforeVisit)
    this._beforeUnloadHandler = this.saveAllDropdownStates.bind(this)
    window.addEventListener('beforeunload', this._beforeUnloadHandler)

    // ensure toggle button aria reflects initial collapsed state
    if (this.hasToggleButtonTarget && this.hasPanelTarget) {
      const collapsed = this.panelTarget.classList.contains('collapsed')
      this.toggleButtonTarget.setAttribute('aria-expanded', (!collapsed).toString())
    }
  }

  disconnect() {
    document.removeEventListener('click', this.boundDocumentClick)
    window.removeEventListener('resize', this._resizeHandler)
    window.removeEventListener('turbo:before-visit', this._saveDropdownsBeforeVisit)
    window.removeEventListener('beforeunload', this._beforeUnloadHandler)
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
    // persist this dropdown's open/closed state
    try {
      const key = dropdown && dropdown.dataset && dropdown.dataset.filterParamKey
      if (key) this.saveDropdownState(key, !expanded)
    } catch (e) { }
  }

  documentClick(e) {
    // only close menus if click was outside the filter element
    if (this.element.contains(e.target)) return
    const menus = this.element.querySelectorAll('.filter-menu')
    menus.forEach(menu => { menu.style.display = 'none' })
    const buttons = this.element.querySelectorAll('.filter-button')
    buttons.forEach(btn => btn.setAttribute('aria-expanded', 'false'))
    // persist that all dropdowns are closed
    try {
      const dropdowns = this.element.querySelectorAll('[data-filter-target="dropdown"]')
      dropdowns.forEach(dd => {
        const key = dd.dataset.filterParamKey
        if (key) this.saveDropdownState(key, false)
      })
    } catch (e) { }
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
    this.saveFilters()
    this.fetchMap()
    this.updateBadges()
    // notify other components (e.g. datatable) that filters changed
    const params = new URLSearchParams()
    const dropdowns = this.element.querySelectorAll('[data-filter-target="dropdown"]')
    dropdowns.forEach(dd => {
      const key = dd.dataset.filterParamKey
      const checked = Array.from(dd.querySelectorAll('input:checked')).map(i => i.value)
      checked.forEach(v => params.append(`${key}[]`, v))
    })
    document.dispatchEvent(new CustomEvent('filters:changed', { detail: { params: params } }))
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
    this.saveFilters()
    this.fetchMap()
    this.updateBadges()
    // notify datatable to reload
    document.dispatchEvent(new CustomEvent('filters:changed', { detail: { params: new URLSearchParams() } }))
  }

  // Persist individual dropdown open/closed state
  saveDropdownState(key, expanded) {
    try {
      const raw = localStorage.getItem('site:filterDropdowns')
      const obj = raw ? JSON.parse(raw) : {}
      obj[key] = !!expanded
      localStorage.setItem('site:filterDropdowns', JSON.stringify(obj))
    } catch (e) { }
  }

  loadDropdownStates() {
    try {
      const raw = localStorage.getItem('site:filterDropdowns')
      if (!raw) return
      const obj = JSON.parse(raw)
      const dropdowns = this.element.querySelectorAll('[data-filter-target="dropdown"]')
      dropdowns.forEach(dd => {
        const key = dd.dataset.filterParamKey
        const menu = dd.querySelector('.filter-menu')
        const btn = dd.querySelector('.filter-button')
        const expanded = obj && Object.prototype.hasOwnProperty.call(obj, key) ? !!obj[key] : false
        if (menu) menu.style.display = expanded ? 'block' : 'none'
        if (btn) btn.setAttribute('aria-expanded', expanded ? 'true' : 'false')
      })
    } catch (e) { }
  }

  // Persist/restore panel collapsed state
  loadPanelState() {
    try {
      const v = localStorage.getItem('site:filterPanelCollapsed')
      if (v === null) return
      const collapsed = v === 'true'
      if (this.hasPanelTarget) this.panelTarget.classList.toggle('collapsed', collapsed)
      this.element.classList.toggle('collapsed', collapsed)
    } catch (e) { /* ignore */ }
  }

  savePanelState(collapsed) {
    try { localStorage.setItem('site:filterPanelCollapsed', collapsed ? 'true' : 'false') } catch (e) { }
  }

  // Persist selected filters so they survive navigation between map/table
  saveFilters() {
    try {
      const dropdowns = this.element.querySelectorAll('[data-filter-target="dropdown"]')
      const obj = {}
      dropdowns.forEach(dd => {
        const key = dd.dataset.filterParamKey
        const checked = Array.from(dd.querySelectorAll('input:checked')).map(i => i.value)
        obj[key] = checked
      })
      localStorage.setItem('site:filters', JSON.stringify(obj))
    } catch (e) { /* ignore */ }
  }

  loadFilters() {
    try {
      const raw = localStorage.getItem('site:filters')
      if (!raw) { this.updateBadges(); this.updateClearState(); return }
      const obj = JSON.parse(raw)
      const dropdowns = this.element.querySelectorAll('[data-filter-target="dropdown"]')
      dropdowns.forEach(dd => {
        const key = dd.dataset.filterParamKey
        const arr = obj[key] || []
        const inputs = dd.querySelectorAll('input')
        inputs.forEach(i => {
          i.checked = arr.indexOf(i.value) !== -1
          const label = i.closest('.filter-item-label')
          if (i.checked) label && label.classList.add('selected')
          else label && label.classList.remove('selected')
        })
      })
      this.updateClearState()
      this.updateBadges()
      // notify other parts of the app of the restored filters
      const params = new URLSearchParams()
      dropdowns.forEach(dd => {
        const key = dd.dataset.filterParamKey
        const checked = Array.from(dd.querySelectorAll('input:checked')).map(i => i.value)
        checked.forEach(v => params.append(`${key}[]`, v))
      })
      document.dispatchEvent(new CustomEvent('filters:changed', { detail: { params: params } }))
      // refresh the map with current selections
      this.fetchMap()
    } catch (e) { this.updateBadges(); this.updateClearState() }
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
    // persist panel state
    try { this.savePanelState(collapsed) } catch (e) { }
  }

  // Save current expanded state for all dropdowns (used before navigation)
  saveAllDropdownStates() {
    try {
      const dropdowns = this.element.querySelectorAll('[data-filter-target="dropdown"]')
      dropdowns.forEach(dd => {
        const btn = dd.querySelector('.filter-button')
        const key = dd.dataset.filterParamKey
        const expanded = btn && btn.getAttribute('aria-expanded') === 'true'
        if (key) this.saveDropdownState(key, expanded)
      })
    } catch (e) { }
  }
}
