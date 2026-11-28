import "cl-vector/world_map.clvxx" as visual

fn main():
    // Wrap the component with a search form that updates the query parameter
    html := str("<html><head><title>Cluster Vector Zoom Search</title>")
    html = html + str("<style>body { background: #0b0b12; margin: 0; padding: 20px; display: flex; flex-direction: column; align-items: center; font-family: 'Inter', sans-serif; color: white; } ")
    html = html + str(".search-box { margin-bottom: 20px; display: flex; gap: 10px; } ")
    html = html + str("input { background: #161622; border: 1px solid rgba(255,255,255,0.1); padding: 8px 16px; border-radius: 6px; color: white; outline: none; } ")
    html = html + str("button { background: #00ffcc; border: none; padding: 8px 16px; border-radius: 6px; color: #0b0b12; font-weight: bold; cursor: pointer; }</style></head><body>")
    html = html + str("<div class='search-box'><input type='text' id='searchQuery' placeholder='Search location (e.g. India)'><button onclick='doSearch()'>Search</button></div>")
            
    // Add the map component (it will automatically inspect 'q' in the browser search query and zoom!)
    html = html + visual.World_mapMap("")
    
    // Add the search script that sets the URL query parameter and populates the text field
    html = html + str("<script>function doSearch() { const q = document.getElementById('searchQuery').value; window.location.search = '?q=' + encodeURIComponent(q); } ")
    html = html + str("window.addEventListener('load', () => { ")
    html = html + str("    const params = new URLSearchParams(window.location.search); ")
    html = html + str("    const q = params.get('q'); ")
    html = html + str("    if (q) { document.getElementById('searchQuery').value = q; } ")
    html = html + str("});</script></body></html>")
            
    put "[Cluster] Interactive Map Search Active!"
    put "[Cluster] Open your browser at: http://localhost:8080"
    serve_web(8080, html)
