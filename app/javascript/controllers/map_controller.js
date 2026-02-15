import { Controller } from "@hotwired/stimulus"

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
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }
}
