// ZipUtility.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：提供轻量级的 ZIP 压缩包解析工具，专门用于解析 DOCX 和 XLSX 等基于 OpenXML 标准的文档格式。
// 版本: 1.0
// 修改记录:
//   - 2026-05-07: 从 IngestService 迁移并封装为独立的工具类。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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

    private static func decompressDeflate(data: Data) -> Data? {
        let destinationBufferSize = data.count * 10
        var destinationBuffer = [UInt8](repeating: 0, count: destinationBufferSize)

        let result = data.withUnsafeBytes { (sourceBuffer: UnsafeRawBufferPointer) -> Int? in
            guard let sourcePointer = sourceBuffer.baseAddress else { return nil }

            return sourcePointer.withMemoryRebound(to: UInt8.self, capacity: data.count) { sourcePtr in
                compression_decode_buffer(
                    &destinationBuffer,
                    destinationBufferSize,
                    sourcePtr,
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }

        guard let size = result, size > 0 else { return nil }
        return Data(destinationBuffer.prefix(size))
    }
}
