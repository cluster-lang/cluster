import "cl-vector/world_map.clvxx" as visual

fn main():
    // Serve the visualizer component wrapped in a basic HTML layout
    // Keep statements single-line to comply with newline syntax rules
    html := str("<html><head><title>Cluster Vector Visualizer</title><style>body { background: #0b0b12; margin: 0; padding: 20px; display: flex; align-items: center; justify-content: center; height: 95vh; font-family: 'Inter', sans-serif; } .box { width: 90%; max-width: 900px; }</style></head><body><div class='box'>")
    html = html + visual.World_mapMap()
    html = html + "</div></body></html>"

    put "[Cluster] Vector Visualizer Server Active!"
    put "[Cluster] Open your browser at: http://localhost:8080"
    serve_web(8080, html)
