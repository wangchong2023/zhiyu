// VisionProSpatialView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：空间计算 (Vision Pro) 预览视图。
// 为 iOS 提供模拟的三维视觉引导，展现空间计算设备带来的沉浸式知识交互体验。
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct VisionProSpatialView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background mesh gradient
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                header(title: L10n.Common.Spatial.title, subtitle: L10n.Common.Spatial.subtitle)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.Common.Spatial.features)
                            .font(.headline)
                            .foregroundStyle(.appText)
                        
                        SpatialFeatureRow(icon: DesignSystem.Icons.cubeTransparent, title: L10n.Common.Spatial.featureGraph3D, desc: L10n.Common.Spatial.featureGraph3DDesc)
                        SpatialFeatureRow(icon: DesignSystem.Icons.handTap, title: L10n.Common.Spatial.featureGesture, desc: L10n.Common.Spatial.featureGestureDesc)
                        SpatialFeatureRow(icon: DesignSystem.Icons.eyeFill, title: L10n.Common.Spatial.featureGaze, desc: L10n.Common.Spatial.featureGazeDesc)
                        SpatialFeatureRow(icon: DesignSystem.Icons.personCropPlus, title: L10n.Common.Spatial.featureSpatialAudio, desc: L10n.Common.Spatial.featureSpatialAudioDesc)
                    }
                    .appContainer(cornerRadius: DesignSystem.largeRadius, padding: true)
                    
                    // Device Requirement
                    VStack(spacing: 8) {
                        Image(systemName: DesignSystem.Icons.visionpro)
                            .font(.system(size: 40))
                            .foregroundStyle(.appAccent)
                        
                        Text(L10n.Common.Spatial.requirement)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                }
            }
            .padding()
        }
        .navigationTitle(L10n.Common.Spatial.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.Common.done) { dismiss() }
            }
        }
    }
    
    private func header(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.appText)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
        }
        .padding(.top, 20)
    }
}

struct SpatialFeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.appAccent)
                .frame(width: 44, height: 44)
                .background(Color.appAccent.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.appText)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        VisionProSpatialView()
            .environmentObject(ThemeManager.shared)
    }
}
