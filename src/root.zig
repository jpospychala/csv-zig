const std = @import("std");
const testing = std.testing;

pub const CSV = struct {
    headers: ?[][]const u8,
    rows: [][][]const u8,

    fn deinit(Self: *@This(), allocator: std.mem.Allocator) void {
        if (Self.headers != null) {
            for (Self.headers.?) |h| {
                allocator.free(h);
            }
            allocator.free(Self.headers.?);
        }
        for (Self.rows) |row| {
            for (row) |col| {
                allocator.free(col);
            }
            allocator.free(row);
        }
        allocator.free(Self.rows);
    }
};

pub fn read(reader: anytype, allocator: std.mem.Allocator, delim: u8) !CSV {
    var buf = [_]u8{0} ** 4096;
    var headers: ?[][]const u8 = null;
    var rows: std.ArrayList([][]const u8) = std.ArrayList([][]const u8).init(allocator);

    while (true) {
        const lineOrError = reader.readUntilDelimiterOrEof(&buf, '\n');
        if (lineOrError == error.EndOfStream) {
            break;
        }
        const line = try lineOrError;
        if (line == null) {
            break;
        }
        var cols = std.mem.splitScalar(u8, line.?, delim);
        var colsList = std.ArrayList([]const u8).init(allocator);
        while (cols.peek() != null) {
            const copy = try allocator.dupe(u8, cols.next().?);
            try colsList.append(copy);
        }
        const slice = try colsList.toOwnedSlice();
        if (headers == null) {
            headers = slice;
        } else {
            try rows.append(slice);
        }
    }

    return CSV{
        .headers = headers.?,
        .rows = try rows.toOwnedSlice(),
    };
}

test "read" {
    var headers = [3][]const u8{ "lp", "name", "height" };
    var row1 = [3][]const u8{ "1", "joe", "200" };
    var row2 = [3][]const u8{ "2", "luke", "300" };
    var rows = [2][][]const u8{
        &row1,
        &row2,
    };
    const expected = CSV{
        .headers = &headers,
        .rows = &rows,
    };
    var stream = std.io.fixedBufferStream(
        \\lp,name,height
        \\1,joe,200
        \\2,luke,300
    );
    var reader = stream.reader();
    var actual = try read(&reader, testing.allocator, ',');
    defer actual.deinit(testing.allocator);
    try testing.expectEqualDeep(expected, actual);
}
