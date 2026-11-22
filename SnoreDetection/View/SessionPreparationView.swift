import SwiftUI

struct SessionPreparationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: Set<SleepContextTag>

    let onStart: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SessionPreparationHeader()
                    SessionTagGrid(selectedTags: $selectedTags)
                    SessionPreparationFooter(
                        selectedCount: selectedTags.count,
                        onStart: startTracking
                    )
                }
                .padding()
            }
            .navigationTitle("Abans de dormir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel·la") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func startTracking() {
        onStart()
        dismiss()
    }
}

private struct SessionPreparationHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Com ha anat el dia?")
                .font(.title2.bold())

            Text("Selecciona tot el que pugui haver influït en els teus roncs. Pots continuar sense seleccionar cap opció.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SessionTagGrid: View {
    @Binding var selectedTags: Set<SleepContextTag>

    private let columns = [
        GridItem(.adaptive(minimum: 145), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SleepContextTag.allCases) { tag in
                SessionTagButton(
                    tag: tag,
                    isSelected: selectedTags.contains(tag),
                    action: { toggle(tag) }
                )
            }
        }
    }

    private func toggle(_ tag: SleepContextTag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

private struct SessionTagButton: View {
    let tag: SleepContextTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: tag.systemImage)
                    .font(.title2)

                Text(tag.title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 92)
            .padding(.horizontal, 8)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                isSelected ? Color.blue : Color.secondary.opacity(0.12)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.blue : Color.secondary.opacity(0.25),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct SessionPreparationFooter: View {
    let selectedCount: Int
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if selectedCount > 0 {
                Text("\(selectedCount) factors seleccionats")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button(action: onStart) {
                Label("Comença el seguiment", systemImage: "moon.zzz.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.top, 8)
    }
}
