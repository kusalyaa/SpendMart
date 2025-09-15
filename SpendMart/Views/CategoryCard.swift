//import SwiftUI
//
//struct CategoryCard: View {
//    var category: Category
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                
//                // Top Image
//                Image(category.image)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(height: 180)
//                    .clipped()
//                
//                // Title + Location Button
//                HStack {
//                    Text(category.name) // ← Now using the category name
//                        .font(.title3)
//                        .fontWeight(.bold)
//                        .foregroundColor(.blue)
//                    
//                    Spacer()
//                    
//                    Button(action: {
//                        // Handle location tap
//                    }) {
//                        HStack {
//                            Image(systemName: "location.fill")
//                            Text("View Location")
//                        }
//                        .font(.footnote)
//                        .fontWeight(.semibold)
//                        .foregroundColor(.white)
//                        .padding(.vertical, 8)
//                        .padding(.horizontal, 14)
//                        .background(Color.blue)
//                        .cornerRadius(10)
//                    }
//                }
//                .padding(.horizontal)
//                
//                // Details
//                VStack(alignment: .leading, spacing: 10) {
//                    
//                    detailRow(label: "Location", value: "simpliTec, Gallroad Colombo3")
//                    detailRow(label: "Amount", value: "LKR 29,999")
//                    detailRow(label: "Date", value: "2025 JUL 09")
//                    detailRow(label: "Warranty Exp. Date", value: "2026 JUL 09")
//                    detailRow(label: "Item Type", value: "Product")
//                    detailRow(label: "Status", value: "On-going")
//                    
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Notes:")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit...")
//                            .font(.footnote)
//                            .foregroundColor(.blue)
//                    }
//                    
//                    HStack {
//                        Spacer()
//                        Text("LKR 25,000 / 29,999")
//                            .font(.footnote)
//                            .foregroundColor(.gray)
//                    }
//                }
//                .padding(.horizontal)
//                
//                Divider()
//                
//                // Progress Section
//                HStack {
//                    Spacer()
//                    VStack(spacing: 4) {
//                        Text("80%")
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.blue)
//                        Text("Paid")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                    }
//                    Spacer()
//                }
//                .padding()
//                .background(Color.blue.opacity(0.05))
//                .cornerRadius(16)
//                .padding(.horizontal)
//                
//                Spacer()
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .principal) {
//                Text(category.name) // ← Dynamic title
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(.blue)
//            }
//            
//            ToolbarItem(placement: .navigationBarLeading) {
//                HStack {
//                    Image(systemName: "chevron.left")
//                    Text("Categories")
//                        .font(.subheadline)
//                }
//                .foregroundColor(.gray)
//            }
//        }
//    }
//    
//    // Reusable row
//    private func detailRow(label: String, value: String) -> some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(label)
//                .font(.subheadline)
//                .foregroundColor(.gray)
//            Text(value)
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(.blue)
//        }
//    }
//}
//
//// Preview
//#Preview {
//    CategoryCard(category: Category(name: "Speaker", image: "cafe"))
//}
