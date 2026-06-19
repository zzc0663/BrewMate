import SwiftUI

/// 加载指示器 — 覆盖在内容上方的半透明遮罩
struct LoadingOverlay: View {
    let message: String

    init(_ message: String = "加载中...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// 可复用的加载状态修饰符
struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack {
            content
            if isLoading {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                LoadingOverlay(message)
            }
        }
    }
}

extension View {
    func loading(_ isLoading: Bool, message: String = "加载中...") -> some View {
        modifier(LoadingModifier(isLoading: isLoading, message: message))
    }
}
