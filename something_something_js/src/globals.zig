const std = @import("std");

var stdout_buf:[1024]u8 = undefined;
var stdout_wr = std.fs.File.stdout().writer(&stdout_buf); 
pub const stdout = &stdout_wr.interface;

var stderr_buf:[1024]u8 = undefined;
var stderr_wr = std.fs.File.stderr().writer(&stderr_buf); 
pub const stderr = &stderr_wr.interface;

var stdin_buf:[1024]u8 = undefined;
var stdin_re = std.fs.File.stdin().reader(&stdin_buf);
pub const stdin = &stdin_re.interface;
