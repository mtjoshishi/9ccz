const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const alc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alc);
    defer std.process.argsFree(alc, args);

    if (args.len != 2) {
        print("{s}: invalid numbers of arguments", .{args[0]});
        std.process.exit(1);
    }

    const num = std.fmt.parseInt(i64, args[1], 10) catch {
        print("Invalid arguments", .{});
        std.process.exit(1);
    };

    const stdout = std.io.getStdOut().writer();
    try stdout.print(".intel_syntax noprefix\n", .{});
    try stdout.print(".global main\n", .{});
    try stdout.print("main:\n", .{});
    try stdout.print("  mov rax, {d}\n", .{num});
    try stdout.print("  ret\n", .{});
    std.process.exit(0);
}
