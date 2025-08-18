import SwiftUI

struct CategoriesView: View {
    @State private var categories: [Category] = [
        Category(name: "Personal", image: "carpark"),
        Category(name: "Work", image: "cafe"),
        Category(name: "Shopping", image: "cafe2"),
        Category(name: "Other", image: "carpark")
    ]
    
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 16) {
                    
                    // Custom Top Bar
                    HStack {
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline)
                                Text("Dashboard")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("Categories")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search", text: .constant(""))
                        Spacer()
                        Image(systemName: "mic.fill")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Grid of categories
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(categories) { category in
                                NavigationLink(destination: CategoryCard(category: category)) {
                                    VStack {
                                        Image(category.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 140)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(radius: 3)
                                        
                                        Text(category.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .padding(.top, 4)
                                    }
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 54, height: 54)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                VStack(spacing: 24) {
                    HStack {
                        Text("Add Category")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        Button("Close") {
                            showingAddCategory = false
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    TextField("Category Name", text: $newCategoryName)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    Button(action: {
                        if !newCategoryName.isEmpty {
                            let newCategory = Category(
                                name: newCategoryName,
                                image: "carpark" // default icon for now
                            )
                            categories.append(newCategory)
                            newCategoryName = ""
                            showingAddCategory = false
                        }
                    }) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Text("Categorize Your Items For Easy Use")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .presentationDetents([.medium])
            }
        }
    }
}

// Preview
#Preview {
    CategoriesView()
}
