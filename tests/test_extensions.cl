import "test_config.clcfg" as config
import "test_component.clx" as ui
import "test_query.clq" as queries
import "test_parser.clp" as parser

fn main():
    // 1. Test .clcfg (Static Configurations)
    put "Config App Name:"
    put config.app_name
    put "Config Port:"
    put config.port
    put "Config Debug:"
    put config.debug
    put "Config Rate Limit:"
    put config.rate_limit

    // 2. Test .clx (UI Components)
    html_output := ui.TodoItem("Build AI Compiler", true)
    put "Rendered UI Component:"
    put html_output

    // 3. Test .clq (Database Queries)
    db::query("test_queries.db", "CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT);")
    db::query("test_queries.db", "DELETE FROM users;")
    db::query("test_queries.db", "INSERT INTO users VALUES (42, 'Alice');")

    res := queries.get_user_by_id(42)
    put "Query Results length:"
    put len(res)
    
    // Clean up test DB
    fs.remove("test_queries.db")

    // 4. Test .clp (Pattern Parser)
    csv_data := "101,Bob,bob@example.com"
    user := parser::parse_UserCSV(csv_data)
    put "Parsed User ID:"
    put user.id
    put "Parsed User Name:"
    put user.name
    put "Parsed User Email:"
    put user.email

    // 5. Test global input() function (returns empty on EOF in tests)
    put "Testing input function:"
    in_val := input("Prompt: ")
    put "Read value: " + in_val
