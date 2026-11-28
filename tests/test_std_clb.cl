import "std/clb.cl"

fn main() -> int:
    println("--- Testing std/clb.cl ---")
    doc := clb_new()
    clb_set_int(doc, "user_id", 42001)
    clb_set_string(doc, "username", "alamgir_zk")
    clb_set_float(doc, "balance", 1250.75)
    clb_set_bool(doc, "is_verified", 1)
    
    assert(clb_has(doc, "user_id") == 1)
    assert(clb_get_int(doc, "user_id", 0) == 42001)
    assert(clb_get_string(doc, "username", "") == "alamgir_zk")
    assert(clb_get_float(doc, "balance", 0.0) == 1250.75)
    assert(clb_get_bool(doc, "is_verified", 0) == 1)
    
    path := "/tmp/test_std_bundle.clb"
    s_res := clb_save(path, doc)
    assert(s_res == 1)
    
    loaded := clb_load(path)
    assert(clb_get_int(loaded, "user_id", 0) == 42001)
    assert(clb_get_string(loaded, "username", "") == "alamgir_zk")
    
    println("PASSED: std/clb.cl works 100%!")
    return 0
