import SwiftUI

struct PixelView: View {
	@State private var isExpanded = true
	
	var name: String
	var color: Color
	
	var body: some View {
		let pixelSize: CGFloat = 30
		
		Toggle(isOn: $isExpanded) {
			HStack {
				// TODO: custom buttonstyle to prevent pixel from changing color when toggle is pressed?
				Rectangle()
					.foregroundStyle(color)
					.frame(width: pixelSize, height: pixelSize)
				
				Text(name)
					.frame(maxWidth: .infinity, alignment: .leading)
				
				Image(systemName: "chevron.backward")
					.rotationEffect(isExpanded ? .degrees(-90) : .zero)
			}
			.contentShape(.rect)
		}
		.toggleStyle(.button)
		.buttonStyle(.plain)
//		.listRowSeparator(.hidden) // ?
		
		if isExpanded {
			GoalView()
			GoalView()
			GoalView()
		}
	}
}

#Preview {
	PixelView(name: "sand", color: .yellow)
}
