## What
Single purpose of this toy program is to see, what single line of js code like this:\
`const response = await fetch("https://google.com", {})` is doing under the hood.\
Networking code written using only syscalls defined in zig std + single C std library function for DNS\
Only `GET` method is supported, because this is only a toy program.

## Usage
zig build run -- [Http_method] [domain] [path]\
zig build run -- GET httpbin.org /get
