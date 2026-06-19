import SwiftUI

/// 左侧导航栏 — 3 个导航项 + 已安装 badge
struct SidebarView: View {
    @Binding var selection: SidebarItem
    let outdatedCount: Int
    let showTrustWarning: Bool

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label {
                HStack {
                    Text(item.displayName)
                    if item == .installed && outdatedCount > 0 {
                        Spacer()
                        Text("\(outdatedCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                    } else if item == .settings && showTrustWarning {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            } icon: {
                Image(systemName: item.icon)
            }
            .tag(item)
        }
        .listStyle(.sidebar)
    }
}
