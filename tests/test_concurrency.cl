fn worker(id: int, ch: Channel[int]):
    put "Worker started:"
    put id
    ch.send(id * 10)

fn main():
    ch := Channel[int](5)
    
    spawn worker(1, ch)
    spawn worker(2, ch)
    
    val1 := ch.recv()
    val2 := ch.recv()
    
    put "Received values:"
    put val1
    put val2
    
    spawn:
        put "Hello from spawn block!"
        
    delay(50)
