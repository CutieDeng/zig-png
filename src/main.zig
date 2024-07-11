const std = @import("std");

const lib = @import("root.zig"); 

const test_image_path = "/Users/cutiedeng/Documents/language/zig-projects/pvz-on-opengl/resource/titleScreen.png"; 

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer _ = gpa.deinit(); 
    const allocator = gpa.allocator(); 
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    // try stdout.print("Run `zig build test` to run the tests.\n", .{});
    const file = try std.fs.openFileAbsolute(test_image_path, .{}); 
    const buffer = try file.readToEndAlloc(allocator, 1 << 30); 
    defer allocator.free(buffer); 
    const signature_check = std.mem.eql(u8, &lib.fileSignature, buffer[0..8]); 
    if (!signature_check) {
        try stdout.print("png file signature check fails. \n", .{}); 
    } else {
        // main path 
        var chunk_list = std.ArrayList(lib.Chunk).init(allocator); 
        defer chunk_list.deinit(); 
        var remain = buffer[8..]; 
        while (remain.len > 0) {
            const new = try chunk_list.addOne(); 
            const cost = lib.Chunk.initFromBytes(new, remain); 
            if (cost) |c| {
                remain = remain[c..]; 
            } else |_| {
                // content is not enough 
                _ = chunk_list.pop(); 
                try stdout.print("init chunk fails. \n", .{}); 
                break; 
            }
        }
        try stdout.print("Read {} chunks. \n", .{ chunk_list.items.len }); 
        for (chunk_list.items) |it| {
            try it.dbg(stdout); 
            try stdout.print("\n", .{}); 
        }
    }
    try bw.flush(); 
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
