const std = @import("std");
const treez = @import("treez");

const log = std.log.scoped(.treesitter_ast);

const highlights = @embedFile("zig-highlights.scm");

const Foo = struct {
    bar: usize = 0,
};

/// Example
/// This example will print this comment
pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const ziglang = try treez.Language.get("zig");

    var parser = try treez.Parser.create();
    defer parser.destroy();

    try parser.setLanguage(ziglang);
    // parser.useStandardLogger();

    const inp = @embedFile("example.zig");
    const tree = try parser.parseString(null, inp);
    defer tree.destroy();

    const query = try treez.Query.create(ziglang, highlights);
    defer query.destroy();

    var pv = try treez.CursorWithValidation.init(allocator, query);

    const cursor = try treez.Query.Cursor.create();
    defer cursor.destroy();

    cursor.execute(query, tree.getRootNode());

    var i: usize = 0;
    while (pv.nextCapture(inp, cursor)) |capture| {
        const node = capture.node;
        log.info("[{d}] {s}: ({d},{d}-{d},{d}): {s}", .{
            i,
            node.getType(),
            node.getStartPoint().row,
            node.getStartPoint().column,
            node.getEndPoint().row,
            node.getEndPoint().column,
            inp[node.getStartByte()..node.getEndByte()],
        });
        i += 1;
    }
}
