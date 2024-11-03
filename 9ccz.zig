const std = @import("std");
const print = std.debug.print;

const strToInt64 = @import("./lib/str_to_int64.zig").strToInt64;
const printError = @import("./lib/print_error.zig").printError;

const TokenKind = enum { TK_RESERVED, TK_NUM, TK_EOF };
const Token = struct { kind: TokenKind, val: i64, str: []u8 };
const TokenError = error{InvalidToken};

// Return true if a given token is expected TK_RESERVED.
fn consume(token: Token, op: u8) bool {
    if (token.kind != TokenKind.TK_RESERVED or token.str[0] != op) {
        return false;
    }
    return true;
}

// Return the numeric value if a given token is TK_NUM.
fn expectNumber(token: Token) !i64 {
    if (token.kind != TokenKind.TK_NUM) {
        try printError(TokenError.InvalidToken, "Expected a number\n", .{});
    }
    return token.val;
}

// Tokenize the input strings and returns the singly-linked list.
fn tokenize(alloc: std.mem.Allocator, input: []u8) !std.SinglyLinkedList(Token) {
    const L = std.SinglyLinkedList(Token);
    var list = L{};

    var head = L.Node{ .data = undefined };
    var cur = &head;
    list.prepend(&head);

    var p = input;
    while (!std.mem.eql(u8, p, "")) {
        // Skip the whitespaces.
        if (std.ascii.isWhitespace(p[0])) {
            p = p[1..];
            continue;
        }

        if (p[0] == '+' or p[0] == '-') {
            const new_tok_ptr = try alloc.create(L.Node);
            const new_tok = Token{ .kind = TokenKind.TK_RESERVED, .val = undefined, .str = p };
            p = p[1..];
            new_tok_ptr.* = L.Node{ .data = new_tok };
            cur.*.insertAfter(new_tok_ptr);
            cur = new_tok_ptr;
            continue;
        }

        if (std.ascii.isAlphanumeric(p[0])) {
            const new_tok_ptr = try alloc.create(L.Node);
            const parsed = try strToInt64(p, 10);
            const new_tok = Token{ .kind = TokenKind.TK_NUM, .val = parsed.value, .str = p };
            new_tok_ptr.* = L.Node{ .data = new_tok };
            cur.*.insertAfter(new_tok_ptr);
            cur = new_tok_ptr;
            p = parsed.remaining;
            continue;
        }

        try printError(TokenError.InvalidToken, "Cannot tokenize.\n", .{});
    }

    const new_tok_ptr = try alloc.create(L.Node);
    const eof_tok = Token{ .kind = TokenKind.TK_EOF, .val = 1, .str = "" };
    new_tok_ptr.* = L.Node{ .data = eof_tok };
    cur.*.insertAfter(new_tok_ptr);

    // Pop the first 'undefined' node.
    _ = list.popFirst();
    return list;
}

fn atEOF(token: Token) bool {
    return token.kind == TokenKind.TK_EOF;
}

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

    const token = try tokenize(allocator, args[1]);

    const stdout = std.io.getStdOut().writer();
    try stdout.print(".intel_syntax noprefix\n", .{});
    try stdout.print(".global main\n", .{});
    try stdout.print("main:\n", .{});

    var itr = token.first;
    // The first token must be numeric.
    try stdout.print("  mov rax, {d}\n", .{try expectNumber(itr.?.data)});
    itr = itr.?.next;

    while (!atEOF(itr.?.data)) : (itr = itr.?.next) {
        if (consume(itr.?.data, '+')) {
            itr = itr.?.next;
            try stdout.print("  add rax, {d}\n", .{try expectNumber(itr.?.data)});
            continue;
        }
        if (itr.?.data.kind != TokenKind.TK_RESERVED or itr.?.data.str[0] != '-') {
            try printError(TokenError.InvalidToken, "Expected '-', but '{c}'\n", .{itr.?.data.str[0]});
        }
        itr = itr.?.next;
        try stdout.print("  sub rax, {d}\n", .{try expectNumber(itr.?.data)});
        continue;
    }
    try stdout.print("  ret\n", .{});
    std.process.exit(0);
}
