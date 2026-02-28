import { Controller } from "@hotwired/stimulus"

function escapeHTML(str) {
  if (!str) return ''
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

export default class extends Controller {
  connect() {
    const token = this.element.dataset.mapMapboxToken || this.element.dataset.mapboxToken
    if (!token) {
      console.warn("Mapbox access token not found on element; set MAPBOX_ACCESS_TOKEN or credentials.")
      return
    }

    if (!window.mapboxgl) {
      console.error("mapboxgl is not loaded. Ensure the Mapbox JS script is included in the layout.")
      return
    }

    mapboxgl.accessToken = token

    // Attempt to restore persisted map center/zoom
    let initialCenter = [0, 0]
    let initialZoom = 1
    this._hasPersistedMapState = false
    try {
      const raw = localStorage.getItem('site:mapState')
      if (raw) {
        const st = JSON.parse(raw)
        if (Array.isArray(st.center) && typeof st.zoom === 'number') {
          initialCenter = st.center
          initialZoom = st.zoom
          this._hasPersistedMapState = true
        }
      }
    } catch (e) { /* ignore */ }

    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/streets-v11",
      center: initialCenter,
      zoom: initialZoom
    })

    this.map.addControl(new mapboxgl.NavigationControl())

    // persist map position when user moves/zooms
    this.map.on('moveend', () => {
      try {
        const center = this.map.getCenter()
        const zoom = this.map.getZoom()
        localStorage.setItem('site:mapState', JSON.stringify({ center: [center.lng, center.lat], zoom: Number(zoom) }))
        // mark that we now have a persisted state
        this._hasPersistedMapState = true
      } catch (e) { /* ignore */ }
    })

    let publications = []
    this._markers = []

    // listen for filter updates dispatched on the map element
    this.updateListener = (e) => {
      try {
        const pubs = e.detail && e.detail.publications ? e.detail.publications : []
        this.updatePublications(pubs)
      } catch (err) {
        console.error('Error handling update-publications event', err)
      }
    }
    this.element.addEventListener('filter:update', this.updateListener)

    const script = this.element.querySelector('script[data-map-publications]')
    if (script && script.textContent) {
      try {
        publications = JSON.parse(script.textContent)
      } catch (e) {
        console.error('Failed to parse publications JSON from script tag for map:', e)
      }
    } else {
      const pubsJson = this.element.dataset.mapPublications || this.element.dataset.mapPubs
      if (pubsJson) {
        try {
          publications = JSON.parse(pubsJson)
        } catch (e) {
          console.error('Failed to parse publications JSON for map (dataset):', e)
        }
      }
    }

    // initialize with any publications present in the markup
    if (publications && publications.length) this.updatePublications(publications)
  }

  updatePublications(publications) {
    // remove existing markers
    try {
      this._markers.forEach(m => m.remove())
    } catch (e) {
      // ignore
    }
    this._markers = []

    if (!publications || !publications.length) return

    const bounds = new mapboxgl.LngLatBounds()

    publications.forEach((p) => {
      const lat = parseFloat(p.latitude)
      const lng = parseFloat(p.longitude)
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) return

      const markerEl = document.createElement('div')
      markerEl.className = 'pub-marker'
      markerEl.style.position = 'absolute'
      markerEl.style.width = '18px'
      markerEl.style.height = '18px'
      markerEl.style.borderRadius = '50%'
      markerEl.style.background = 'rgba(0,122,255,0.95)'
      markerEl.style.boxShadow = '0 1px 3px rgba(0,0,0,0.3)'
      markerEl.style.cursor = 'pointer'

      const title = escapeHTML(p.title || '')
      const authors = escapeHTML(p.authors || '')
      const meta = []
      if (p.journal) meta.push(escapeHTML(p.journal))
      if (p.year) meta.push('' + p.year)

      let popupHtml = `<div style="font-size:14px;font-weight:600;margin-bottom:6px;">${title}</div>`
      if (authors) popupHtml += `<div style="font-size:13px;color:#333;margin-bottom:4px;">${authors}</div>`
      popupHtml += `<div style="font-size:12px;color:#444">${escapeHTML(meta.join(' • '))}</div>`

      const popup = new mapboxgl.Popup({ offset: 12, closeButton: false, closeOnClick: false }).setHTML(popupHtml)

      const marker = new mapboxgl.Marker(markerEl).setLngLat([lng, lat]).setPopup(popup).addTo(this.map)

      markerEl.addEventListener('mouseenter', () => { marker.getPopup().addTo(this.map) })
      markerEl.addEventListener('mouseleave', () => { marker.getPopup().remove() })
      markerEl.addEventListener('click', () => { window.location.href = `/publications/${p.id}` })

      this._markers.push(marker)
      bounds.extend([lng, lat])
    })

    // Fit map to markers once the style is loaded
    const fit = () => {
      try {
        if (!bounds.isEmpty()) {
          // Only auto-fit to markers if the user does not have a persisted map position/zoom
          if (!this._hasPersistedMapState) {
            this.map.fitBounds(bounds, { padding: 40, maxZoom: 12 })
          }
          // otherwise leave the user's persisted center/zoom intact
        }
      } catch (e) {
        // ignore
      }
    }

    if (this.map.loaded()) fit()
    else this.map.once('load', fit)
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
    if (this.updateListener) this.element.removeEventListener('filter:update', this.updateListener)
  }
}
