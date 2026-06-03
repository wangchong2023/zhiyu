//
//  ZipUtility.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：属于 Utils 模块，提供相关的结构体或工具支撑。
//
import Foundation
import Compression

/// ZIP 工具类：支持解压与解析 ZIP 存档中的特定文件。
enum ZipUtility {

    /// 读取 ZIP 存档并返回文件路径与二进制数据的映射。
    static func readZipArchive(at url: URL) -> [String: Data]? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        var archive: [String: Data] = [:]

        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            guard let baseAddress = buffer.baseAddress else { return }

            var offset = 0
            let count = buffer.count

            while offset + 30 < count {
                let bytes = baseAddress.advanced(by: offset)

                // Local file header signature
                guard bytes.load(as: UInt32.self) == 0x04034b50 else {
                    // Try to find next file header
                    if let nextOffset = findNextLocalFileHeader(in: buffer, start: offset) {
                        offset = nextOffset
                        continue
                    }
                    break
                }

                let fileNameLength = Int(bytes.load(fromByteOffset: 28, as: UInt16.self))
                let extraFieldLength = Int(bytes.load(fromByteOffset: 30, as: UInt16.self))
                let compressedSize = Int(bytes.load(fromByteOffset: 18, as: UInt32.self))

                let headerSize = 30 + fileNameLength + extraFieldLength
                let dataOffset = offset + headerSize

                guard dataOffset + compressedSize <= count else { break }

                let nameBytes = UnsafeRawPointer(baseAddress).advanced(by: offset + 30)
                let fileNameData = Data(bytes: nameBytes, count: fileNameLength)
                guard let fileName = String(data: fileNameData, encoding: .utf8) else {
                    offset += 4
                    continue
                }

                // Decompress if needed (method 0 = stored, 8 = deflate)
                let compressionMethod = UInt16(bytes.load(fromByteOffset: 8, as: UInt16.self))
                let compressedData = Data(bytes: baseAddress.advanced(by: dataOffset), count: compressedSize)

                if compressionMethod == 0 {
                    archive[fileName] = compressedData
                } else if compressionMethod == 8 {
                    if let decompressed = decompressDeflate(data: compressedData) {
                        archive[fileName] = decompressed
                    }
                }

                offset = dataOffset + compressedSize
            }
        }

        return archive.isEmpty ? nil : archive
    }

    /// 查找NextLocalFileHeader
    /// - Parameter start: 启动
    /// - Returns: 可选值
    private static func findNextLocalFileHeader(in buffer: UnsafeRawBufferPointer, start: Int) -> Int? {
        let count = buffer.count
        var i = start + 4
        while i + 4 <= count {
            let sig = buffer.load(fromByteOffset: i, as: UInt32.self)
            if sig == 0x04034b50 {
                return i
            }
            i += 1
        }
        return nil
    }

    /// 解压Deflate
    /// - Parameter data: data
    /// - Returns: 可选值
    private static func decompressDeflate(data: Data) -> Data? {
        let destinationBufferSize = data.count * 10
        var destinationData = Data(count: destinationBufferSize)

        let result = destinationData.withUnsafeMutableBytes { destBuffer in
            data.withUnsafeBytes { sourceBuffer -> Int? in
                guard let sourcePointer = sourceBuffer.baseAddress,
                      let destPointer = destBuffer.baseAddress else { return nil }

                let size = compression_decode_buffer(
                    destPointer.bindMemory(to: UInt8.self, capacity: destinationBufferSize),
                    destinationBufferSize,
                    sourcePointer.bindMemory(to: UInt8.self, capacity: data.count),
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
                return size > 0 ? size : nil
            }
        }

        guard let size = result else { return nil }
        return destinationData.prefix(size)
    }
}
