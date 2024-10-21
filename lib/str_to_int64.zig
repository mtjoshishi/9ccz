// Convert from a given string to long type numeric.
const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const errno = @import("./errno.zig");

fn test_strToInt64(expected: parsedStrToInt64, actual: parsedStrToInt64) bool {
    if (expected.value == actual.value and std.mem.eql(u8, expected.remaining, actual.remaining) and expected.errno == actual.errno) {
        return true;
    }
    return false;
}

test strToInt64 {
    try expect(test_strToInt64(parsedStrToInt64{ .value = -10, .remaining = "", .errno = 0 }, try strToInt64("-10", 10)));
    try expect(test_strToInt64(parsedStrToInt64{ .value = 255, .remaining = "", .errno = 0 }, try strToInt64("  +255", 10)));
    try expect(test_strToInt64(parsedStrToInt64{ .value = 42, .remaining = @constCast("+28"), .errno = 0 }, try strToInt64("42+28", 10)));
    try expect(test_strToInt64(parsedStrToInt64{ .value = 35, .remaining = @constCast("#"), .errno = 0 }, try strToInt64("35#", 10)));
    try expect(test_strToInt64(parsedStrToInt64{ .value = 0, .remaining = @constCast("#1"), .errno = errno.EINVAL }, try strToInt64("#1", 10)));
}

const parsedStrToInt64 = struct {
    value: i64,
    remaining: []u8,
    errno: u8,
};

fn isSpace(c: u8) bool {
    return c == ' ';
}

pub fn strToInt64(s: []const u8, base: u8) !parsedStrToInt64 {
    var is_neg: bool = false;
    var pos: usize = 0;
    var errno_: u8 = 0;

    while (isSpace(s[pos])) : (pos += 1) {}
    if (s[pos] == '-') {
        is_neg = true;
        pos += 1;
    } else if (s[pos] == '+') {
        pos += 1;
    }

    var any: i2 = 0;
    var accumulate: i64 = 0;
    var cutoff: u64 = undefined;
    if (is_neg) {
        cutoff = -std.math.minInt(i64);
    } else {
        cutoff = std.math.maxInt(i64);
    }

    const cutlim = try std.math.mod(u64, cutoff, @as(u64, base));
    cutoff = @divTrunc(cutoff, @as(u64, base));

    while (pos != s.len) : (pos += 1) {
        if (!std.ascii.isAlphanumeric(s[pos])) {
            break;
        }

        const digit: u8 = switch (s[pos]) {
            '0'...'9' => s[pos] - '0',
            'a'...'z' => s[pos] - 'a' + 10,
            'A'...'Z' => s[pos] - 'A' + 10,
            else => unreachable,
        };
        if (digit >= base) {
            break;
        }
        if (any < 0 or accumulate > cutoff or (accumulate == cutoff and digit > cutlim)) {
            any = -1;
        } else {
            any = 1;
            accumulate *= base;
            accumulate += digit;
        }
    }
    if (any < 0) {
        if (is_neg) {
            accumulate = std.math.minInt(i64);
        } else {
            accumulate = std.math.maxInt(i64);
        }
        errno_ = errno.ERANGE;
    } else if (any == 0) {
        errno_ = errno.EINVAL;
    } else if (is_neg) {
        accumulate = -accumulate;
    }

    if (pos == s.len) {
        return parsedStrToInt64{ .value = accumulate, .remaining = "", .errno = errno_ };
    } else {
        const remaining = @constCast(s[pos..]);
        return parsedStrToInt64{ .value = accumulate, .remaining = remaining, .errno = errno_ };
    }
}
