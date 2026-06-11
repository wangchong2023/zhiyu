import XCTest
@testable import ZhiYu

final class KnowledgePageTests: XCTestCase {
    
    func testIsPrivateWithoutPrivateTag() {
        // Arrange
        let page = KnowledgePage(
            title: "Normal Page",
            content: "This is a public page without any special tags."
        )
        
        // Act & Assert
        XCTAssertFalse(page.isPrivate, "页面如果不包含 private 标签，则不应该是私有的")
    }
    
    func testIsPrivateWithMetadataTag() {
        // Arrange
        let page = KnowledgePage(
            title: "Secret Page",
            content: "This content is secret.",
            tags: ["private", "work"]
        )
        
        // Act & Assert
        XCTAssertTrue(page.isPrivate, "如果页面的元数据标签中包含 private，应当被判定为私有")
    }
    
    func testIsPrivateWithInlineHashTag() {
        // Arrange
        let page = KnowledgePage(
            title: "Inline Secret",
            content: "This content has an inline tag #private hidden inside."
        )
        
        // Act & Assert
        XCTAssertTrue(page.isPrivate, "如果页面的正文内包含 #private，应当被判定为私有")
    }
    
    func testIsPrivateWithMixedTags() {
        // Arrange
        let page = KnowledgePage(
            title: "Mixed Secret",
            content: "We also have #PRIVATE inside, wait, case sensitive?",
            tags: ["Draft"]
        )
        
        // Act
        // Current implementation is exact match "private", so #PRIVATE won't match unless extractAllTags normalizes it.
        // Let's assume it doesn't match #PRIVATE currently. If we want it to, we'd need to modify KnowledgePage.
        // But let's stick to the exact "private" tag for now.
        let page2 = KnowledgePage(
            title: "Mixed Secret 2",
            content: "We also have #private inside.",
            tags: ["Draft"]
        )
        
        // Assert
        XCTAssertTrue(page2.isPrivate, "正文包含 #private 应该被判定为私有")
    }
}
