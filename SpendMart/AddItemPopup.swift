import SwiftUI

// Main Add Item Selection Popup
struct AddItemPopup: View {
    @Binding var isPresented: Bool
    @State private var showingProductPopup = false
    @State private var showingServicePopup = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Item")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 20)
            
            Text("Choose Item Type")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                Button(action: {
                    showingProductPopup = true
                    isPresented = false
                }) {
                    Text("Product")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    showingServicePopup = true
                    isPresented = false
                }) {
                    Text("Service")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .sheet(isPresented: $showingProductPopup) {
            AddProductView()
        }
        .sheet(isPresented: $showingServicePopup) {
            AddServiceView()
        }
    }
}

// Add Product Popup
struct AddProductView: View {
    @State private var showingScanBill = false
    @State private var showingManualAdd = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Product")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 20)
            
            Text("Choose Method")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                Button(action: {
                    showingScanBill = true
                }) {
                    Text("Scan Bill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    showingManualAdd = true
                }) {
                    Text("Add")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(12)
        .sheet(isPresented: $showingScanBill) {
            ScanBillView()
        }
        .sheet(isPresented: $showingManualAdd) {
            ManualAddProductView()
        }
    }
}

// Add Service Popup
struct AddServiceView: View {
    @State private var showingScanBill = false
    @State private var showingManualAdd = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Service")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 20)
            
            Text("Choose Method")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                Button(action: {
                    showingScanBill = true
                }) {
                    Text("Scan Bill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    showingManualAdd = true
                }) {
                    Text("Add")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(12)
        .sheet(isPresented: $showingScanBill) {
            ScanBillView()
        }
        .sheet(isPresented: $showingManualAdd) {
            ManualAddServiceView()
        }
    }
}

// Scan Bill View (Common for both Product and Service)
struct ScanBillView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Scan Bill")
                .font(.title)
                .padding()
            
            // TODO: Implement camera/bill scanning functionality
            // 1. Camera integration for bill scanning
            // 2. OCR/Text recognition to extract item details
            // 3. Parse bill data: item name, price, date, vendor, etc.
            // 4. Auto-populate form fields with extracted data
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .overlay(
                    VStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Camera functionality to be implemented")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
                .padding()
            
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            
            Spacer()
        }
    }
}

// Manual Add Product Form
struct ManualAddProductView: View {
    @State private var productName = ""
    @State private var price = ""
    @State private var location = ""
    @State private var purchaseDate = Date()
    @State private var warrantyPeriod = ""
    @State private var notes = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Product Name")
                            .font(.system(size: 14, weight: .medium))
                        TextField("Enter product name", text: $productName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Price (LKR)")
                            .font(.system(size: 14, weight: .medium))
                        TextField("Enter price", text: $price)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location/Store")
                            .font(.system(size: 14, weight: .medium))
                        TextField("Enter purchase location", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Purchase Date")
                            .font(.system(size: 14, weight: .medium))
                        DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Warranty Period (months)")
                            .font(.system(size: 14, weight: .medium))
                        TextField("Enter warranty period", text: $warrantyPeriod)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 14, weight: .medium))
                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        // TODO: Save product to database
                        // API call: POST /api/products
                        /*
                         let productData = [
                             "name": productName,
                             "price": Double(price) ?? 0,
                             "location": location,
                             "purchase_date": purchaseDate,
                             "warranty_months": Int(warrantyPeriod) ?? 0,
                             "notes": notes,
                             "category_id": selectedCategoryId,
                             "user_id": currentUserId
                         ]
                         */
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Add Product")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(productName.isEmpty || price.isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// Manual Add Service Form
struct ManualAddServiceView: View {
    @State private var serviceName = ""
    @State private var price = ""
    @State private var provider = ""
    @State private var startDate = Date()
    @State private var duration = ""
    @State private var notes = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Service Name")
                            .font(.system(size: 14, weight: .medium))
                        TextField("Enter service name", text: $serviceName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Price (LKR)")
                            .font(.system(size: 14, weight: .medium))
                        TextField("Enter price", text: $price)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Service Provider")
                            .font(.system(size: 14, weight: .medium))
                        TextField("Enter provider name", text: $provider)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.system(size: 14, weight: .medium))
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration (months)")
                            .font(.system(size: 14, weight: .medium))
                        TextField("Enter duration", text: $duration)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 14, weight: .medium))
                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        // TODO: Save service to database
                        // API call: POST /api/services
                        /*
                         let serviceData = [
                             "name": serviceName,
                             "price": Double(price) ?? 0,
                             "provider": provider,
                             "start_date": startDate,
                             "duration_months": Int(duration) ?? 0,
                             "notes": notes,
                             "category_id": selectedCategoryId,
                             "user_id": currentUserId
                         ]
                         */
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Add Service")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(serviceName.isEmpty || price.isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Add Service")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    AddItemPopup(isPresented: .constant(true))
}
