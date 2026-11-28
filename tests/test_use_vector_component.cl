import "cl-vector/world_map.clvxx" as world_map_component

fn main():
    // Render the controllable HTML/SVG map component
    html := world_map_component.World_mapMap()
    put "Generated HTML component length: " + str(len(html))
