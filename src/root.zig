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

    // Read csv contents from reader, field separated by delim
    pub fn read(reader: anytype, allocator: std.mem.Allocator, delim: u8) !CSV {
        var buf = [_]u8{0} ** (1024 * 1024);
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
};

test "read" {
    const expected = CSV{
        .headers = @constCast(&([_][]const u8{ "lp", "name", "height" })),
        .rows = @constCast(&[2][][]const u8{
            @constCast(&[_][]const u8{ "1", "joe", "200" }),
            @constCast(&[_][]const u8{ "2", "luke", "300" }),
        }),
    };
    var stream = std.io.fixedBufferStream(
        \\lp,name,height
        \\1,joe,200
        \\2,luke,300
    );
    var reader = stream.reader();
    var actual = try CSV.read(&reader, testing.allocator, ',');
    defer actual.deinit(testing.allocator);
    try testing.expectEqualDeep(expected, actual);
}

test "large csv read" {
    const start = std.time.milliTimestamp();
    const rows = 1024;
    const cols = 1024;
    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();

    for (0..rows) |r| {
        for (0..cols) |c| {
            try std.fmt.format(buf.writer(), "row{d}col{d},", .{ r, c });
        }
        try buf.writer().writeByte('\n');
    }

    var stream = std.io.fixedBufferStream(buf.items);
    const now = std.time.milliTimestamp();
    var csv = try CSV.read(stream.reader(), testing.allocator, ',');
    const then = std.time.milliTimestamp();
    std.debug.print("create {d} read {d} ms\n", .{ now - start, then - now });
    defer csv.deinit(testing.allocator);
}
