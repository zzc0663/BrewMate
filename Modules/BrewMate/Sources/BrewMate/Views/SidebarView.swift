import SwiftUI

/// 左侧导航栏 — 4 个导航项 + 更新 badge
struct SidebarView: View {
    @Binding var selection: SidebarItem
    let outdatedCount: Int

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label {
                HStack {
                    Text(item.displayName)
                    if item == .updates && outdatedCount > 0 {
                        Spacer()
                        Text("\(outdatedCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
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
