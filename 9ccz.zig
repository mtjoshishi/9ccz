const std = @import("std");
const print = std.debug.print;

const strToInt64 = @import("./lib/str_to_int64.zig").strToInt64;

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        print("{s}: invalid numbers of arguments", .{args[0]});
        std.process.exit(1);
    }

    var p: []u8 = args[1];

    const stdout = std.io.getStdOut().writer();
    try stdout.print(".intel_syntax noprefix\n", .{});
    try stdout.print(".global main\n", .{});
    try stdout.print("main:\n", .{});

    var parsed_result = try strToInt64(p, 10);
    try stdout.print("  mov rax, {d}\n", .{parsed_result.value});

    p = parsed_result.remaining;

    while (!std.mem.eql(u8, p, "")) {
        if (p[0] == '+') {
            p = p[1..];
            parsed_result = try strToInt64(p, 10);
            p = parsed_result.remaining;
            try stdout.print("  add rax, {d}\n", .{parsed_result.value});
            continue;
        }
        if (p[0] == '-') {
            p = p[1..];
            parsed_result = try strToInt64(p, 10);
            p = parsed_result.remaining;
            try stdout.print("  sub rax, {d}\n", .{parsed_result.value});
            continue;
        } else {
            print("Unexpected character: {d}\n", .{p[0]});
            return 1;
        }
    }
    try stdout.print("  ret\n", .{});
    std.process.exit(0);
}
