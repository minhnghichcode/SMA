import SwiftUI
import Foundation

struct MarkdownMessageView: View {
    let text: String
    private var renderedAttributedString: AttributedString {
        var parsed: AttributedString

        do {
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .full
            options.allowsExtendedAttributes = true
            parsed = try AttributedString(markdown: text, options: options)
        } catch {
            parsed = AttributedString(text)
        }

        let themeTextColor = Color.themeSecondaryText
        let codeBackground = Color.themePrimary.opacity(0.08)

        for run in parsed.runs {
            let range = run.range

            if run.inlinePresentationIntent?.contains(.code) == true {
                var container = AttributeContainer()
                container.font = .system(size: 15, weight: .regular, design: .monospaced)
                container.backgroundColor = codeBackground
                container.foregroundColor = themeTextColor
                parsed[range].mergeAttributes(container, mergePolicy: .keepNew)
                parsed[range].baselineOffset = 0
            }

            if run.link != nil {
                var container = AttributeContainer()
                container.foregroundColor = Color.themeAccent
                container.underlineStyle = .single
                parsed[range].mergeAttributes(container, mergePolicy: .keepNew)
            }

            if let presentationIntent = run.presentationIntent {
                for component in presentationIntent.components {
                    switch component.kind {
                    case .paragraph:
                        continue
                    case .header(let level):
                        var fontSize: CGFloat = 16
                        switch level {
                        case 1:
                            fontSize = 22
                        case 2:
                            fontSize = 20
                        case 3:
                            fontSize = 18
                        default:
                            fontSize = 16
                        }
                        var container = AttributeContainer()
                        container.font = .system(size: fontSize, weight: .semibold, design: .default)
                        container.foregroundColor = themeTextColor
                        parsed[range].mergeAttributes(container, mergePolicy: .keepNew)
                    case .table:
                        // Table styling
                        var container = AttributeContainer()
                        container.font = .system(size: 14, weight: .regular, design: .default)
                        parsed[range].mergeAttributes(container, mergePolicy: .keepNew)
                    case .tableRow:
                        // Row styling
                        break
                    case .tableCell:
                        // Cell styling
                        var container = AttributeContainer()
                        container.backgroundColor = Color.themeSecondary.opacity(0.3)
                        container.foregroundColor = themeTextColor
                        parsed[range].mergeAttributes(container, mergePolicy: .keepNew)
                    default:
                        break
                    }
                }
            }
        }

        return parsed
    }

    var body: some View {
        Text(renderedAttributedString)
            .lineSpacing(4)
            .textSelection(.enabled)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        MarkdownMessageView(text: "**Xin chào**! Đây là một thông điệp *markdown* với [liên kết](https://example.com).")
        MarkdownMessageView(text: "### Danh sách\n- Mục đầu tiên\n- Mục thứ hai\n\n`Đoạn code` inline.")
        MarkdownMessageView(text: "| Col1 | Col2 |\n|------|------|\n| Data1 | Data2 |")
    }
    .padding()
    .background(Color.themeSecondary)
}
