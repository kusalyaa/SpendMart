//import SwiftUI
//
//struct CategoryList: View {
//    let category: Category
//    @State private var searchText = ""
//    @State private var showAddItemPopup = false
//    @State private var showAddProductPopup = false
//    @State private var showAddServicePopup = false
//    
//    // Dummy items for now (later fetched from backend)
//    var items: [CategoryItem] {
//        [
//            CategoryItem(
//                id: UUID(),
//                imageName: "speaker_image",
//                title: "Speaker",
//                subtitle: "JBL Boombox3",
//                systemImageFallback: "speaker.wave.3.fill"
//            ),
//            CategoryItem(
//                id: UUID(),
//                imageName: "youtube_image",
//                title: "Youtube subscription",
//                subtitle: "Annual Plan",
//                systemImageFallback: "play.rectangle.fill"
//            )
//        ]
//    }
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Search Bar
//            HStack {
//                HStack {
//                    Image(systemName: "magnifyingglass")
//                        .foregroundColor(.gray)
//                        .font(.system(size: 16))
//                    
//                    TextField("Search", text: $searchText)
//                        .font(.system(size: 16))
//                }
//                .padding(.horizontal, 12)
//                .padding(.vertical, 8)
//                .background(Color(.systemGray6))
//                .cornerRadius(10)
//                
//                Button(action: {
//                    // Voice search action
//                }) {
//                    Image(systemName: "mic.fill")
//                        .foregroundColor(.gray)
//                        .font(.system(size: 18))
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.top, 8)
//            .padding(.bottom, 16)
//            
//            // Content List
//            ScrollView {
//                LazyVStack(spacing: 0) {
//                    ForEach(items.filter {
//                        searchText.isEmpty ? true :
//                        $0.title.localizedCaseInsensitiveContains(searchText)
//                    }) { item in
//                        NavigationLink(
//                            destination: CategoryCard(category: category)
//                        ) {
//                            CategoryItemRow(item: item)
//                        }
//                        
//                        Divider()
//                            .padding(.leading, 76)
//                    }
//                }
//                .padding(.horizontal, 16)
//            }
//            
//            Spacer()
//            
//            // Add Button
//            HStack {
//                Spacer()
//                Button(action: {
//                                        showAddItemPopup = true
//                                    }) {
//                                        Image(systemName: "plus")
//                                            .font(.title2)
//                                            .foregroundColor(.white)
//                                            .frame(width: 54, height: 54)
//                                            .background(Color.blue)
//                                            .clipShape(RoundedRectangle(cornerRadius: 16))
//                                            .shadow(radius: 4)
//                                    }
//
//                                    .padding(.trailing, 20)
//                                    .padding(.bottom, 100)
//                                }
//        }
//        .navigationTitle(category.name)
//        .navigationBarTitleDisplayMode(.large)
//    }
//}
//
//// MARK: - Item Row
//struct CategoryItemRow: View {
//    let item: CategoryItem
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            // Item Image
//            AsyncImage(url: URL(string: item.imageName)) { image in
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//            } placeholder: {
//                Image(systemName: item.systemImageFallback)
//                    .foregroundColor(.gray)
//                    .font(.system(size: 24))
//                    .frame(width: 44, height: 44)
//                    .background(Color(.systemGray5))
//                    .cornerRadius(8)
//            }
//            .frame(width: 44, height: 44)
//            .cornerRadius(8)
//            
//            // Text Content
//            VStack(alignment: .leading, spacing: 2) {
//                Text(item.title)
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.primary)
//                
//                Text(item.subtitle)
//                    .font(.system(size: 14))
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            // Chevron
//            Image(systemName: "chevron.right")
//                .foregroundColor(.gray)
//                .font(.system(size: 14, weight: .medium))
//        }
//        .padding(.vertical, 12)
//    }
//}
//
//// MARK: - Models
//struct CategoryItem: Identifiable {
//    let id: UUID
//    let imageName: String
//    let title: String
//    let subtitle: String
//    let systemImageFallback: String
//}
//
//// MARK: - Preview
//#Preview {
//    NavigationView {
//        CategoryList(category: Category(name: "Personal", image: "carpark"))
//    }
//}
