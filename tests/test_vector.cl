import "world_map.clv" as my_map

fn main():
    put "Image path: " + my_map.get_image_path()
    
    // Exact lookups
    put "Lookup near Africa: " + my_map.lookup(537.0, 560.0)
    put "Lookup near Europe: " + my_map.lookup(545.0, 318.0)
    put "Lookup out of bounds: " + my_map.lookup(100.0, 100.0)
