// Print the error information to an user.

const std = @import("std");
const print = std.debug.print;

pub const ERR_BUF_SIZE: u16 = std.math.maxInt(u16);

test printError {
    const fmt: []const u8 = "Oops {d}";
    try printError(error.Oops, fmt, .{10});
}

// Print the error message and exit the program.
// @param anyerror: error.
// @param []const u8: message format.
// @param anytype: arguments.
pub fn printError(err: anyerror, comptime fmt: []const u8, args: anytype) !void {
    var buf: [ERR_BUF_SIZE]u8 = undefined;
    const msg: []u8 = try std.fmt.bufPrint(&buf, fmt, args);
    print("{s}: {s}\n", .{ @errorName(err), msg });
    std.process.exit(1);
}
