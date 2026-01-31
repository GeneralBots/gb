use cron::Schedule;
use std::str::FromStr;

fn main() {
    let test_schedules = vec![
        "59 * * * *",
        "0 * * * *", 
        "0 11 * * *",
        "0 0 */2 * *",
        "0 30 23 * * *",
    ];
    
    for schedule in test_schedules {
        println!("Testing: '{}'", schedule);
        match Schedule::from_str(schedule) {
            Ok(_) => println!("  ✅ Valid"),
            Err(e) => println!("  ❌ Error: {}", e),
        }
    }
}
