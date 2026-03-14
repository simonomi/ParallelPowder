import SwiftUI

enum GoalType: Identifiable, Hashable, CaseIterable {
	case change, swap
	
	var id: Self { self }
	
	var label: String {
		switch self {
			case .change: "Change to"
			case .swap: "Swap with"
		}
	}
	
	static func random() -> Self {
		allCases.randomElement()!
	}
}

struct GoalView: View {
	@State private var changeOrSwap: GoalType = .random()
	
	var body: some View {
		// have OR rows instead of priority numbers
		// (or maybe OR by default with divider rows?)
		HStack {
			Text("criteria")
			
			Picker("test", selection: $changeOrSwap) {
				ForEach(GoalType.allCases) {
					Text($0.label)
				}
			}
			.labelsHidden()
			
			switch changeOrSwap {
				case .change:
					Picker("Pixel", selection: .constant(Int.random(in: 0..<3))) {
						Label("sand", systemImage: "squareshape.fill")
							.foregroundStyle(.yellow)
							.symbolRenderingMode(.palette)
							.tag(0)
						
						Label("water", systemImage: "squareshape.fill")
							.foregroundStyle(.blue)
							.symbolRenderingMode(.palette)
							.tag(1)
						
						Label("tree", systemImage: "squareshape.fill")
							.foregroundStyle(.green)
							.symbolRenderingMode(.palette)
							.tag(2)
					}
					.labelsHidden()
				case .swap:
					Text("neighbor")
			}
		}
	}
}

#Preview {
	GoalView()
}
