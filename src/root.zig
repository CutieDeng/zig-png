const std = @import("std");
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

pub const ChunkType = packed struct {
    _rev0: u2,
    ancillary: u1, 
    _rev1: u5, 
    _rev2: u2, 
    private: u1, 
    _rev3: u5, 
    _rev4: u2, 
    reversed: u1, 
    _rev5: u5, 
    _rev6: u2, 
    safe_to_copy: u1, 
    _rev7: u5, 
}; 

pub const Chunk = struct {
    length: u32, 
    chunk_type: u32, 
    chunk_data: []const u8, 
    crc: u32, 

    pub fn verify(cu: Chunk, actual_crc: *u32) !void {
        var v = std.hash.Crc32.init(); 
        v.update(std.mem.asBytes(&cu.chunk_type)); 
        v.update(std.mem.sliceAsBytes(cu.chunk_data)); 
        const c = v.final(); 
        if (c != cu.crc) {
            actual_crc.* = c; 
            return error.Failure; 
        }
        return ; 
    }

    pub fn initFromBytes(cu: *Chunk, bytes: []const u8) !usize {
        var stream = std.io.fixedBufferStream(bytes); 
        const reader = stream.reader(); 
        cu.length = try reader.readInt(u32, .big); 
        cu.chunk_type = try reader.readInt(u32, .big); 
        try stream.seekBy(@intCast(cu.length)); 
        cu.crc = try reader.readInt(u32, .big); 
        cu.chunk_data = bytes[8..][0..cu.length]; 
        return 12 + cu.length; 
    }

    pub fn dbg(cu: Chunk, writer: anytype) !void {
        const t : [4]u8 = @bitCast(cu.chunk_type); 
        var _unused: u32 = undefined; 
        try writer.print("Chunk(type:{s},len:{},", .{ t, cu.length }); 
        try writer.print("verified:#", .{}); 
        if (cu.verify(&_unused)) { 
            try writer.print("t", .{}); 
        } else |_| {
            try writer.print("f", .{}); 
        }
        const ct: ChunkType = @bitCast(cu.chunk_type); 
        if (ct.ancillary == 1) {
            try writer.print(",+ancillary", .{}); 
        }
        if (ct.private == 1) {
            try writer.print(",+private", .{});
        }
        if (ct.safe_to_copy == 1) {
            try writer.print(",+safe2copy", .{}); 
        }
        try writer.print(")", .{}); 
        return ; 
    }

}; 

pub const fileSignature: [8]u8 = [_] u8 { 137, 80, 78, 71, 13, 10, 26, 10 }; 