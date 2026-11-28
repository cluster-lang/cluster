import "std/clw.cl"

fn main() -> int:
    println("--- Testing std/clw.cl ---")
    world := clw_world_new("TestWorld", 1.0, 16, -9.81)
    clw_add_material(world, 1, "stone", 1, 0.7, 0.1, 2500.0)
    clw_add_material(world, 2, "water", 0, 0.1, 0.0, 1000.0)
    
    clw_set_block(world, 10, 5, 10, 1)
    assert(clw_get_block(world, 10, 5, 10) == 1)
    
    // Collision check
    hit := clw_check_box_collision(world, 9.8, 4.8, 9.8, 10.2, 5.2, 10.2)
    assert(hit == 1)
    
    // Raycast check
    r_hit := clw_raycast(world, 10.0, 0.0, 10.0, 0.0, 1.0, 0.0, 10.0)
    assert(r_hit == 1)
    
    path := "/tmp/test_std_world.clw"
    saved := clw_save(path, world)
    assert(saved == 1)
    
    loaded := clw_load(path)
    assert(loaded.name == "TestWorld")
    assert(clw_get_block(loaded, 10, 5, 10) == 1)
    
    println("PASSED: std/clw.cl works 100%!")
    return 0
