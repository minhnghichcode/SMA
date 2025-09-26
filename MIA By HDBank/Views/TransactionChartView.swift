//
//  TransactionChartView.swift
//  MIA By HDBank
//
//  Created by minhhoccode on 26/9/25.
//

import SwiftUI
import Charts

struct TransactionChartView: View {
    let transactions: [TransactionData]
    @State private var isAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Báo Cáo Thu Chi")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Chart {
                ForEach(transactions) { transaction in
                    // Income bar
                    BarMark(
                        x: .value("Tháng", transaction.month),
                        y: .value("Thu nhập", isAnimated ? transaction.income : 0),
                        width: .ratio(0.4)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .opacity(0.8)
                    .position(by: .value("Type", "Thu nhập"))
                    
                    // Expense bar
                    BarMark(
                        x: .value("Tháng", transaction.month),
                        y: .value("Chi tiêu", isAnimated ? transaction.expense : 0),
                        width: .ratio(0.4)
                    )
                    .foregroundStyle(Color.red.gradient)
                    .opacity(0.8)
                    .position(by: .value("Type", "Chi tiêu"))
                }
            }
            .frame(height: 300)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel(format: .currency(code: "VND"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    AxisGridLine()
                        .foregroundStyle(.quaternary)
                    AxisTick()
                        .foregroundStyle(.tertiary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    AxisGridLine()
                        .foregroundStyle(.quaternary)
                    AxisTick()
                        .foregroundStyle(.tertiary)
                }
            }
            .chartLegend(position: .bottom) {
                HStack(spacing: 20) {
                    Label("Thu nhập", systemImage: "square.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    
                    Label("Chi tiêu", systemImage: "square.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    isAnimated = true
                }
            }
            
            // Summary cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(transactions) { transaction in
                    TransactionSummaryCard(transaction: transaction)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct TransactionSummaryCard: View {
    let transaction: TransactionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(transaction.month)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Thu: \(formatCurrency(transaction.income))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Chi: \(formatCurrency(transaction.expense))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "equal.circle.fill")
                        .foregroundColor(transaction.netIncome >= 0 ? .green : .red)
                        .font(.caption)
                    Text("Ròng: \(formatCurrency(transaction.netIncome))")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(transaction.netIncome >= 0 ? .green : .red)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.currencySymbol = ""
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return "\(formatted)đ"
        }
        return "\(Int(amount))đ"
    }
}

#Preview {
    let sampleData = [
        TransactionData(month: "Tháng 7", income: 32000000, expense: 25000000),
        TransactionData(month: "Tháng 8", income: 33500000, expense: 27000000),
        TransactionData(month: "Tháng 9", income: 34000000, expense: 26500000),
        TransactionData(month: "Tháng 10", income: 35000000, expense: 28000000)
    ]
    
    ScrollView {
        TransactionChartView(transactions: sampleData)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}