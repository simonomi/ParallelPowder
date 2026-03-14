import SwiftUI

struct PixelsView: View {
	var body: some View {
		List {
			PixelView(name: "sand", color: .yellow)
			PixelView(name: "water", color: .blue)
			PixelView(name: "tree", color: .green)
		}
	}
}

#Preview {
	Text("hello world")
		.inspector(isPresented: .constant(true)) {
			PixelsView()
		}
}
