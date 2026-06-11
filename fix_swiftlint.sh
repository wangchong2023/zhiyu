#!/bin/bash
# Revert the .0 changes first
sed -i '' 's/\.frame(height: DesignSystem.Spacing.small)/\.frame(height: 12)/g' Sources/Features/System/Settings/View/System/RAGEvaluationView.swift
sed -i '' 's/\.frame(width: 260.0)/\.frame(width: 260)/g' Sources/Shared/UIComponents/Menus/UserProfileMenu.swift
sed -i '' 's/\.frame(width: 30.0, height: 30.0)/\.frame(width: 30, height: 30)/g' Sources/Shared/UIComponents/Menus/UserProfileMenu.swift
sed -i '' 's/\.frame(width: 300.0, height: 300.0)/\.frame(width: 300, height: 300)/g' Sources/Features/System/Auth/View/SubscriptionPlanView.swift
sed -i '' 's/\.frame(height: 6.0)/\.frame(height: 6)/g' Sources/Features/System/Auth/View/SubscriptionPlanView.swift
sed -i '' 's/\.frame(width: barWidth, height: 6.0)/\.frame(width: barWidth, height: 6)/g' Sources/Features/System/Auth/View/SubscriptionPlanView.swift
sed -i '' 's/\.frame(width: 80.0, height: 80.0)/\.frame(width: 80, height: 80)/g' Sources/Features/System/Auth/View/SubscriptionPlanView.swift

