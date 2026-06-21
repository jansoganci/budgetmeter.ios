//
//  BillRowView.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team
//

import SwiftUI

/// Unified bill row component that consolidates OverdueBillRow, DueSoonBillRow, and BillRow
/// into a single configurable view to eliminate code duplication.
struct BillRowView: View {
    // MARK: - Row Style

    enum RowStyle {
        case overdue
        case dueSoon
        case standard
    }

    // MARK: - Properties

    let bill: Bill
    let viewModel: BillsViewModel
    let style: RowStyle
    let showRecurring: Bool
    let showAutoPay: Bool
    let showPaidStatus: Bool
    let enableSwipeActions: Bool
    let enableBackground: Bool
    let onTap: (() -> Void)?

    // MARK: - Initialization

    init(
        bill: Bill,
        viewModel: BillsViewModel,
        style: RowStyle,
        showRecurring: Bool = true,
        showAutoPay: Bool = true,
        showPaidStatus: Bool = true,
        enableSwipeActions: Bool = true,
        enableBackground: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.bill = bill
        self.viewModel = viewModel
        self.style = style
        self.showRecurring = showRecurring
        self.showAutoPay = showAutoPay
        self.showPaidStatus = showPaidStatus
        self.enableSwipeActions = enableSwipeActions
        self.enableBackground = enableBackground
        self.onTap = onTap
    }

    // MARK: - Computed Properties

    private var iconBackgroundColor: Color {
        switch style {
        case .overdue:
            return .red
        case .dueSoon:
            return .orange
        case .standard:
            return bill.isPaid ? .brandProgress : .brandProgress.opacity(0.6)
        }
    }

    private var dueDateColor: Color {
        switch style {
        case .overdue:
            return .red
        case .dueSoon:
            return .orange
        case .standard:
            return bill.isPaid ? .brandProgress : .textSecondary
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon placeholder (first letter of name)
            Text(String(bill.name?.prefix(1).uppercased() ?? "?"))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(iconBackgroundColor)
                .cornerRadius(CornerRadius.small)

            VStack(alignment: .leading, spacing: 4) {
                Text(bill.name ?? String(localized: "bills.unknown", defaultValue: "Unknown", table: "UI"))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 4) {
                    Text(viewModel.dueDateText(bill))
                        .font(.caption)
                        .foregroundColor(dueDateColor)

                    if showRecurring && bill.isRecurring {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text(viewModel.frequencyText(bill))
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if showAutoPay && bill.isAutoPay {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text(String(localized: "bills.autopay", defaultValue: "AutoPay", table: "UI"))
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.formatAmount(bill.amount))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                if showPaidStatus && bill.isPaid {
                    Text(String(localized: "bills.status.paid", defaultValue: "✓ Paid", table: "UI"))
                        .font(.caption)
                        .foregroundColor(.brandProgress)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(Spacing.md)
        .applyIf(enableBackground) { view in
            view
                .background(Color.surfaceCard)
                .cornerRadius(CornerRadius.small)
        }
        .applyIf(onTap != nil) { view in
            view.contentShape(Rectangle())
                .onTapGesture {
                    onTap?()
                }
        }
        .applyIf(enableSwipeActions) { view in
            view.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    viewModel.deleteBill(bill)
                } label: {
                    Label(String(localized: "bills.action.delete", defaultValue: "Delete", table: "UI"), systemImage: "trash")
                }

                if !bill.isPaid {
                    Button {
                        viewModel.markAsPaid(bill)
                    } label: {
                        Label(String(localized: "bills.action.mark_paid", defaultValue: "Paid", table: "UI"), systemImage: "checkmark.circle.fill")
                    }
                    .tint(.brandProgress)
                } else {
                    Button {
                        viewModel.markAsUnpaid(bill)
                    } label: {
                        Label(String(localized: "bills.action.mark_unpaid", defaultValue: "Unpaid", table: "UI"), systemImage: "arrow.uturn.backward")
                    }
                    .tint(.orange)
                }
            }
        }
    }
}

// MARK: - View Extension for Conditional Modifiers

extension View {
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
