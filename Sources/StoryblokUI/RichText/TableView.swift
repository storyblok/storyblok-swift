import SwiftUI
import StoryblokClient

// NOTE: The `@_optimize(none)` on the table view `body` getters below works
// around a swift-frontend 6.2.x crash in Release (`-O`). The optimizer inlines
// SwiftUI's `@inlinable overlay(_:alignment:)` into these getters, and the
// debug-info mangler (`mangleForDebugInfo`) then segfaults walking the nested
// opaque (`some View`) types produced by the chained view modifiers. Opting
// these getters out of the performance inliner avoids that inlining and the
// crash, with negligible runtime cost for view-body construction. Debug builds
// are unaffected (no optimizer). Remove once the compiler bug is fixed.

// MARK: - Table

struct TableView<BL: View & Decodable>: View {
    let table: RichText<BL>.Table

    @_optimize(none)
    var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(table.content.indices, id: \.self) { i in
                if case .tableRow(let row) = table.content[i] {
                    TableRowView(row: row)
                }
            }
        }
        .overlay(Rectangle().stroke(Color.secondary.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Table row

struct TableRowView<BL: View & Decodable>: View {
    let row: RichText<BL>.TableRow

    var body: some View {
        GridRow {
            ForEach(row.content.indices, id: \.self) { i in
                switch row.content[i] {
                case .tableHeader(let h):
                    TableHeaderCellView(header: h)
                        .gridCellColumns(h.columnSpan ?? 1)
                case .tableCell(let c):
                    TableCellView(cell: c)
                        .gridCellColumns(c.columnSpan ?? 1)
                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Table header cell

struct TableHeaderCellView<BL: View & Decodable>: View {
    let header: RichText<BL>.TableHeader

    @_optimize(none)
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(header.content.indices, id: \.self) { i in
                header.content[i]
            }
        }
        .fontWeight(.bold)
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.secondary.opacity(0.12))
        .overlay(Rectangle().stroke(Color.secondary.opacity(0.4), lineWidth: 0.5))
    }
}

// MARK: - Table data cell

struct TableCellView<BL: View & Decodable>: View {
    let cell: RichText<BL>.TableCell

    @_optimize(none)
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(cell.content.indices, id: \.self) { i in
                cell.content[i]
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CssColorParser.parse(cell.backgroundColor) ?? Color.clear)
        .overlay(Rectangle().stroke(Color.secondary.opacity(0.4), lineWidth: 0.5))
    }
}
