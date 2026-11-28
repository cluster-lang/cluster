import "std/cls.cl"

fn main() -> int:
    println("--- Testing std/cls.cl ---")
    schema := cls_new("UserContract")
    cls_add_int(schema, "id", 1, 1, 1000000)
    cls_add_string(schema, "username", 1, 3, 20, "")
    cls_add_string(schema, "email", 1, 5, 50, "@")
    cls_add_bool(schema, "is_active", 1)
    
    let mut roles: vector[string] = []
    roles.push("Admin")
    roles.push("Developer")
    roles.push("Guest")
    cls_add_enum(schema, "role", 1, roles)
    
    valid_doc := clb_new()
    clb_set_int(valid_doc, "id", 1001)
    clb_set_string(valid_doc, "username", "alamgir_zk")
    clb_set_string(valid_doc, "email", "admin@zk-company.org")
    clb_set_bool(valid_doc, "is_active", 1)
    clb_set_string(valid_doc, "role", "Developer")
    
    is_ok := cls_validate(schema, valid_doc)
    assert(is_ok == 1)
    
    path := "/tmp/test_std_schema.cls"
    s_res := cls_save(path, schema)
    assert(s_res == 1)
    
    loaded := cls_load(path)
    assert(loaded.name == "UserContract")
    assert(cls_validate(loaded, valid_doc) == 1)
    
    println("PASSED: std/cls.cl works 100%!")
    return 0
