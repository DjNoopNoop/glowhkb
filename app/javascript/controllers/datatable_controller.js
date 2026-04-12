import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["datatable"]

  connect() {
    // attempt to initialize the DataTable; the table element may not be present
    // immediately when Stimulus connects (e.g. when navigating back from show).
    this._initAttempts = 0
    this._initRetryTimeout = null
    this.tryInit()
    // reload when global filters change
    this.boundFiltersChanged = (e) => this.reloadWithFilters(e.detail && e.detail.params)
    document.addEventListener('filters:changed', this.boundFiltersChanged)

    // also reload on header search input change (debounced)
    const searchInput = document.querySelector('[data-search-target="input"]')
    if (searchInput) {
      let timeout
      searchInput.addEventListener('input', (ev) => {
        clearTimeout(timeout)
        timeout = setTimeout(() => { this.reloadWithFilters() }, 300)
      })
    }

    // handle back/forward cache and Turbo navigations: reload table when page is shown or Turbo finishes load
    this.boundPageShow = (e) => { if (this.dt) this.dt.ajax.reload(null, false) }
    window.addEventListener('pageshow', this.boundPageShow)

    this.boundTurboLoad = () => { if (this.dt) this.dt.ajax.reload(null, false) }
    document.addEventListener('turbo:load', this.boundTurboLoad)
  }

  disconnect() {
    document.removeEventListener('filters:changed', this.boundFiltersChanged)
    window.removeEventListener('pageshow', this.boundPageShow)
    document.removeEventListener('turbo:load', this.boundTurboLoad)
    if (this._initRetryTimeout) {
      clearTimeout(this._initRetryTimeout)
      this._initRetryTimeout = null
    }
    if (this.dt) {
      this.dt.destroy(true)
    }
  }

  initDataTable() {
    let table = null
    if (this.hasTableTarget) {
      table = this.tableTarget
    } else {
      table = this.element.querySelector('table')
    }

    if (!table || !window.jQuery || !window.jQuery.fn.DataTable) return

    const self = this
    this.dt = window.jQuery(table).DataTable({
      serverSide: true,
      ajax: {
        url: '/publications.json',
        data: function(d) {
          // include header search q param
          const qInput = document.querySelector('[data-search-target="input"]')
          if (qInput && qInput.value) d.q = qInput.value

          // include filter inputs
          const dropdowns = document.querySelectorAll('[data-filter-target="dropdown"]')
          dropdowns.forEach(dd => {
            const key = dd.dataset.filterParamKey
            const checked = Array.from(dd.querySelectorAll('input:checked')).map(i => i.value)
            if (checked.length) d[key] = checked
          })
        },
        dataSrc: 'data'
      },
      columns: [
        { data: 'title', render: function(data, type, row) {
          if (type === 'display') return `<a href="/publications/${row.id}">${escapeHtml(data)}</a>`
          return data
        }},
        { data: 'authors' },
        { data: 'journal' },
        { data: 'year' },
        { data: 'geographic_location' },
        { data: 'air_pollutants', render: function(data){ return escapeHtml(Array.isArray(data) ? data.join(', ') : (data || '')) } },
        { data: 'medical_conditions', render: function(data){ return escapeHtml(Array.isArray(data) ? data.join(', ') : (data || '')) } },
        { data: 'weather_parameters', render: function(data){ return escapeHtml(Array.isArray(data) ? data.join(', ') : (data || '')) } },
        { data: 'statistical_methods', render: function(data){ return escapeHtml(Array.isArray(data) ? data.join(', ') : (data || '')) } }
      ],
      order: [[3, 'desc']],
      pageLength: 25,
      lengthMenu: [10,25,50,100]
    })
  }

  tryInit() {
    try {
      this._initAttempts = (this._initAttempts || 0) + 1
      this.initDataTable()
      // if init created dt, we're done
      if (this.dt) return
    } catch (err) {
      // ignore initialization errors and retry
      console.warn('DataTable init attempt failed', err)
    }

    // retry a few times (in case DOM is restored from bfcache without targets yet)
    if (this._initAttempts < 6) {
      this._initRetryTimeout = setTimeout(() => this.tryInit(), 150)
    }
  }

  reloadWithFilters(params) {
    if (!this.dt) return
    this.dt.page(0).draw()
  }
}

function escapeHtml(s) {
  if (!s) return ''
  return String(s).replace(/[&"'<>]/g, function(c) {
    return {'&':'&amp;', '"':'&quot;', "'":'&#39;', '<':'&lt;', '>':'&gt;'}[c]
  })
}
