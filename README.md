## What
Single purpose of this toy program to see, what single line of js code like this:\
`const response = await fetch("https://google.com", {})` is doing under the hood.\
Only GET method is supported, because this is a only toy program.

## Usage
zig build run -- [Http_method] [domain] [path]\
zig build run -- GET httpbin.org /get
