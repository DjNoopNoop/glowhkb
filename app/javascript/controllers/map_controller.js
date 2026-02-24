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

    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/streets-v11",
      center: [0, 0],
      zoom: 1
    })

    this.map.addControl(new mapboxgl.NavigationControl())

    let publications = []

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

    if (!publications || !publications.length) return

    const bounds = new mapboxgl.LngLatBounds()

    publications.forEach((p) => {
      const lat = parseFloat(p.latitude)
      const lng = parseFloat(p.longitude)
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) return

      const markerEl = document.createElement('div')
      markerEl.className = 'pub-marker'
      // Let Mapbox position the marker element via transforms; avoid relative positioning
      markerEl.style.position = 'absolute'
      markerEl.style.width = '18px'
      markerEl.style.height = '18px'
      markerEl.style.borderRadius = '50%'
      markerEl.style.background = 'rgba(0,122,255,0.95)'
      markerEl.style.boxShadow = '0 1px 3px rgba(0,0,0,0.3)'
      markerEl.style.cursor = 'pointer'

      const title = escapeHTML(p.title || '')
      const meta = []
      if (p.journal) meta.push(escapeHTML(p.journal))
      if (p.year) meta.push('' + p.year)

      const popupHtml = `<div style="font-weight:600;margin-bottom:4px;">${title}</div><div style="font-size:12px;color:#444">${escapeHTML(meta.join(' • '))}</div>`

      const popup = new mapboxgl.Popup({ offset: 12, closeButton: false, closeOnClick: false }).setHTML(popupHtml)

      const marker = new mapboxgl.Marker(markerEl).setLngLat([lng, lat]).setPopup(popup).addTo(this.map)

      // show popup on hover (explicit add/remove) and navigate on click
      markerEl.addEventListener('mouseenter', () => { marker.getPopup().addTo(this.map) })
      markerEl.addEventListener('mouseleave', () => { marker.getPopup().remove() })
      markerEl.addEventListener('click', () => { window.location.href = `/publications/${p.id}` })

      bounds.extend([lng, lat])
    })

    // Fit map to markers once the style is loaded
    const fit = () => {
      try {
        if (!bounds.isEmpty()) {
          this.map.fitBounds(bounds, { padding: 40, maxZoom: 12 })
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
  }
}
