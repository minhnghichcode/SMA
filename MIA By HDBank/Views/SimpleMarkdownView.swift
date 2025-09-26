import SwiftUI

struct SimpleMarkdownView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseMarkdown(cleanText), id: \.self) { element in
                renderElement(element)
            }
        }
    }
    
    // Remove ~confirm~ from text for display
    private var cleanText: String {
        return text.replacingOccurrences(of: "~confirm~", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        let lines = text.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        var i = 0
        
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            if line.isEmpty {
                i += 1
                continue
            }
            
            // Check for table
            if line.contains("|") && i + 1 < lines.count && lines[i + 1].contains("---") {
                let (tableElement, nextIndex) = parseTable(lines, startIndex: i)
                elements.append(tableElement)
                i = nextIndex
                continue
            }
            
            // Check for headers
            if line.hasPrefix("#") {
                elements.append(.header(level: getHeaderLevel(line), text: line.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)))
            }
            // Check for lists
            else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                elements.append(.listItem(text: String(line.dropFirst(2))))
            }
            // Check for code blocks
            else if line.hasPrefix("```") {
                let (codeElement, nextIndex) = parseCodeBlock(lines, startIndex: i)
                elements.append(codeElement)
                i = nextIndex
                continue
            }
            // Regular paragraph
            else {
                elements.append(.paragraph(text: line))
            }
            
            i += 1
        }
        
        return elements
    }
    
    private func parseTable(_ lines: [String], startIndex: Int) -> (MarkdownElement, Int) {
        var tableRows: [[String]] = []
        var i = startIndex
        
        // Parse header row
        let headerLine = lines[i].trimmingCharacters(in: .whitespaces)
        let headerCells = headerLine.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        tableRows.append(headerCells)
        
        i += 2 // Skip separator line
        
        // Parse data rows
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.contains("|") {
                let cells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                tableRows.append(cells)
                i += 1
            } else {
                break
            }
        }
        
        return (.table(rows: tableRows), i)
    }
    
    private func parseCodeBlock(_ lines: [String], startIndex: Int) -> (MarkdownElement, Int) {
        var codeLines: [String] = []
        var i = startIndex + 1
        
        while i < lines.count && !lines[i].hasPrefix("```") {
            codeLines.append(lines[i])
            i += 1
        }
        
        return (.codeBlock(code: codeLines.joined(separator: "\n")), i + 1)
    }
    
    private func getHeaderLevel(_ line: String) -> Int {
        var level = 0
        for char in line {
            if char == "#" {
                level += 1
            } else {
                break
            }
        }
        return min(level, 6)
    }
    
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element {
        case .header(let level, let text):
            let fontSize: CGFloat = {
                switch level {
                case 1: return 24
                case 2: return 20
                case 3: return 18
                default: return 16
                }
            }()
            
            Text(renderInlineMarkdown(text))
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(.themeSecondaryText)
                .padding(.vertical, 4)
            
        case .paragraph(let text):
            Text(renderInlineMarkdown(text))
                .font(.body)
                .foregroundColor(.themeSecondaryText)
                .padding(.vertical, 2)
            
        case .listItem(let text):
            HStack(alignment: .top) {
                Text("•")
                    .foregroundColor(.themeSecondaryText)
                Text(renderInlineMarkdown(text))
                    .foregroundColor(.themeSecondaryText)
                Spacer()
            }
            .padding(.vertical, 1)
            
        case .table(let rows):
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { cellIndex, cell in
                            Text(renderInlineMarkdown(cell))
                                .font(.system(size: 14, weight: rowIndex == 0 ? .semibold : .regular))
                                .foregroundColor(.themeSecondaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .background(rowIndex == 0 ? Color.themePrimary.opacity(0.15) : Color.themeSecondary.opacity(0.3))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.themeBorder, lineWidth: 1))
            .padding(.vertical, 4)
            
        case .codeBlock(let code):
            Text(code)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.themeSecondaryText)
                .padding(12)
                .background(Color.themePrimary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.vertical, 4)
        }
    }
    
    private func renderInlineMarkdown(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Bold **text**
        let boldPattern = /\*\*(.*?)\*\*/
        let boldMatches = text.matches(of: boldPattern)
        for match in boldMatches.reversed() {
            let fullMatch = String(text[match.range])
            let content = String(match.1)
            
            if let range = attributedString.range(of: fullMatch) {
                attributedString.removeSubrange(range)
                var boldText = AttributedString(content)
                boldText.font = .boldSystemFont(ofSize: 16)
                attributedString.insert(boldText, at: range.lowerBound)
            }
        }
        
        // Italic *text*
        let italicPattern = /\*(.*?)\*/
        let italicMatches = text.matches(of: italicPattern)
        for match in italicMatches.reversed() {
            let fullMatch = String(text[match.range])
            let content = String(match.1)
            
            if let range = attributedString.range(of: fullMatch) {
                attributedString.removeSubrange(range)
                var italicText = AttributedString(content)
                italicText.font = .italicSystemFont(ofSize: 16)
                attributedString.insert(italicText, at: range.lowerBound)
            }
        }
        
        // Code `text`
        let codePattern = /`(.*?)`/
        let codeMatches = text.matches(of: codePattern)
        for match in codeMatches.reversed() {
            let fullMatch = String(text[match.range])
            let content = String(match.1)
            
            if let range = attributedString.range(of: fullMatch) {
                attributedString.removeSubrange(range)
                var codeText = AttributedString(content)
                codeText.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
                codeText.backgroundColor = Color.themePrimary.opacity(0.1)
                attributedString.insert(codeText, at: range.lowerBound)
            }
        }
        
        return attributedString
    }
}

enum MarkdownElement: Hashable {
    case header(level: Int, text: String)
    case paragraph(text: String)
    case listItem(text: String)
    case table(rows: [[String]])
    case codeBlock(code: String)
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SimpleMarkdownView(text: "# Header 1\n\nThis is a **bold** and *italic* text with `code`.")
        SimpleMarkdownView(text: "| Name | Age | City |\n|------|-----|------|\n| John | 25 | NYC |\n| Jane | 30 | LA |")
    }
    .padding()
    .background(Color.themeBackground)
}