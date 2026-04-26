import SwiftUI
import AVFoundation
import PhotosUI
import UIKit

private enum AppTab: Hashable {
    case receipts
    case scan
    case profile
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .receipts
    @State private var selectedReceipt: ReceiptModel?
    @StateObject private var receiptStore = ReceiptStore()
    @State private var deferNextTotalAnimation = false
    @State private var totalAnimationReleaseToken = 0
    @State private var displayedTotal = 0.0
    @State private var hasInitializedDisplayedTotal = false
    @State private var pendingTotalAfterDetail: Double?
    @State private var totalAnimationTask: Task<Void, Never>?
    @StateObject private var profileStore = ProfileStore()
    @State private var isCameraSettingsModalVisible = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppColors.bg
                    .ignoresSafeArea()

                Circle()
                    .fill(AppColors.primary.opacity(0.10))
                    .frame(width: 340, height: 340)
                    .offset(x: -120, y: -310)
                    .allowsHitTesting(false)

                Group {
                    switch selectedTab {
                    case .receipts:
                        ReceiptsView(
                            selectedReceipt: $selectedReceipt,
                            receipts: receiptStore.receipts,
                            deferNextTotalAnimation: $deferNextTotalAnimation,
                            totalAnimationReleaseToken: totalAnimationReleaseToken,
                            displayedTotal: displayedTotal
                        )
                    case .scan:
                        ScanView(
                            onReceiptScanned: { scannedReceipt in
                                deferNextTotalAnimation = true
                                receiptStore.add(scannedReceipt)
                                selectedTab = .receipts
                                DispatchQueue.main.async {
                                    Haptics.success()
                                    selectedReceipt = scannedReceipt
                                }
                            },
                            isCameraSettingsModalVisible: $isCameraSettingsModalVisible
                        )
                    case .profile:
                        ProfileView(profileStore: profileStore)
                    }
                }
                .padding(.bottom, 90)

                if isCameraSettingsModalVisible {
                    Color.black.opacity(0.42)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .zIndex(40)
                }

                tabBar
                    .frame(maxWidth: 420)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 8)
                    .zIndex(50)
            }
            .navigationDestination(item: $selectedReceipt) { receipt in
                ReceiptDetailView(receipt: receipt) {
                    selectedReceipt = nil
                    if deferNextTotalAnimation {
                        totalAnimationReleaseToken += 1
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Haptics.prepare()
                if !hasInitializedDisplayedTotal {
                    displayedTotal = totalSpent
                    hasInitializedDisplayedTotal = true
                }
            }
            .onChange(of: totalSpent) { _, newValue in
                if deferNextTotalAnimation || selectedReceipt != nil {
                    pendingTotalAfterDetail = newValue
                } else {
                    animateTotal(to: newValue)
                }
            }
            .onChange(of: totalAnimationReleaseToken) { _, _ in
                guard let pending = pendingTotalAfterDetail else { return }
                pendingTotalAfterDetail = nil
                deferNextTotalAnimation = false
                animateTotal(to: pending)
            }
        }
    }

    private var totalSpent: Double { receiptStore.receipts.reduce(0) { $0 + $1.total } }

    private func animateTotal(to newValue: Double) {
        totalAnimationTask?.cancel()
        let start = displayedTotal
        let delta = newValue - start
        guard abs(delta) > 0.001 else {
            displayedTotal = newValue
            return
        }

        Haptics.light()
        totalAnimationTask = Task { @MainActor in
            let steps = 30
            for step in 1...steps {
                if Task.isCancelled { return }
                let t = Double(step) / Double(steps)
                let eased = 1 - pow(1 - t, 3) // fast start, slow finish
                displayedTotal = start + (delta * eased)
                if step % 6 == 0 {
                    Haptics.light()
                }
                try? await Task.sleep(nanoseconds: 18_000_000)
            }
            displayedTotal = newValue
            Haptics.medium()
        }
    }

    private var tabBar: some View {
        GeometryReader { proxy in
            let contentWidth = proxy.size.width - 16 // horizontal padding inside bar
            let slotWidth = contentWidth / 3
            let activeX = CGFloat(activeTabIndex) * slotWidth + 8

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.clear)
                    .liquidCapsule(tint: .white.opacity(0.08))

                Capsule(style: .continuous)
                    .fill(Color.clear)
                    .liquidCapsule(tint: AppColors.primary.opacity(0.08), interactive: false)
                    .frame(width: slotWidth, height: 54)
                    .offset(x: activeX, y: 0)
                    .allowsHitTesting(false)

                HStack(spacing: 6) {
                    tabButton(icon: "doc.text", title: "Receipts", tab: .receipts)
                    tabButton(icon: "qrcode.viewfinder", title: "Scan", tab: .scan)
                    tabButton(icon: "person.crop.circle", title: "Profile", tab: .profile)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
            }
            .animation(.easeOut(duration: 0.20), value: selectedTab)
        }
        .frame(height: 78)
    }

    private var activeTabIndex: Int {
        switch selectedTab {
        case .receipts: return 0
        case .scan: return 1
        case .profile: return 2
        }
    }

    private func tabButton(icon: String, title: String, tab: AppTab) -> some View {
        let active = selectedTab == tab
        return Button {
            withAnimation(.easeOut(duration: 0.20)) {
                selectedTab = tab
            }
            Haptics.light()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.vertical, 10)
            .foregroundStyle(active ? AppColors.primary : AppColors.muted.opacity(0.9))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ReceiptsView: View {
    @Binding var selectedReceipt: ReceiptModel?
    let receipts: [ReceiptModel]
    @Binding var deferNextTotalAnimation: Bool
    let totalAnimationReleaseToken: Int
    let displayedTotal: Double
    @State private var showAll = false

    private var visibleReceipts: [ReceiptModel] { showAll ? receipts : Array(receipts.prefix(3)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR RECEIPTS")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.1)
                        .foregroundStyle(AppColors.muted)
                    Text("Expenses")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.text)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("TOTAL SPENT")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                    Text("$\(displayedTotal, specifier: "%.2f")")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("\(receipts.count) receipts saved")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    LinearGradient(colors: [AppColors.primary, AppColors.primary.opacity(0.74)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: AppColors.primary.opacity(0.3), radius: 12, x: 0, y: 8)

                VStack(spacing: 0) {
                    LazyVStack(spacing: 10) {
                        ForEach(visibleReceipts) { receipt in
                            ReceiptRow(receipt: receipt)
                                .onTapGesture {
                                    selectedReceipt = receipt
                                    Haptics.medium()
                                }
                        }
                    }
                    .padding(12)

                    if receipts.count > 3 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAll.toggle()
                            }
                            Haptics.light()
                        } label: {
                            HStack(spacing: 6) {
                                Text(showAll ? "Show less" : "View all")
                                Text(showAll ? "↑" : "↓")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .glassCard()
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
        }
        .scrollIndicators(.hidden)
    }
}

private struct ReceiptRow: View {
    let receipt: ReceiptModel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.accent)
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "storefront").foregroundStyle(AppColors.primary))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(receipt.storeName)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    Text("$\(receipt.total, specifier: "%.2f")")
                        .font(.system(size: 15, weight: .semibold))
                }
                Text("\(receipt.items.count) items · \(receipt.paymentMethod)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.muted)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.accent.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.primary.opacity(0.10), lineWidth: 0.8)
        )
    }
}

private struct ReceiptDetailView: View {
    let receipt: ReceiptModel
    let onClose: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isPrinting = false
    @State private var printStartTask: Task<Void, Never>?
    private static let receiptDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy · h:mm a"
        return formatter
    }()

    var body: some View {
        GeometryReader { _ in
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    Spacer()
                    Text("Receipt")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Color.clear
                        .frame(width: 34, height: 34)
                }
                .padding(.horizontal, 2)

                TicketPrinterView(isPrinting: isPrinting) {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppColors.accent)
                                    .frame(width: 56, height: 56)
                                    .overlay(Image(systemName: "storefront").font(.system(size: 24)).foregroundStyle(AppColors.primary))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(receipt.storeName)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                    Text(displayReceiptCode)
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundStyle(AppColors.muted)
                                }
                            }

                            HStack(spacing: 24) {
                                Label(formattedDate(receipt.purchaseDate), systemImage: "calendar")
                                Label(receipt.paymentMethod.capitalized, systemImage: "creditcard")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.muted)

                            Label(receipt.storeAddress, systemImage: "location")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppColors.muted)
                        }
                        .padding(20)

                        Divider()

                        VStack(alignment: .leading, spacing: 14) {
                            Label("ITEMS", systemImage: "list.bullet.rectangle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.muted)

                            VStack(spacing: 14) {
                                ForEach(receipt.items) { item in
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.name)
                                                .font(.system(size: 18, weight: .semibold))
                                            if item.quantity > 1 {
                                                Text("\(item.quantity) × $\(item.unitPrice, specifier: "%.2f")")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundStyle(AppColors.muted)
                                            }
                                        }
                                        Spacer()
                                        Text("$\(item.total, specifier: "%.2f")")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                            }
                        }
                        .padding(20)

                        Divider()

                        VStack(spacing: 10) {
                            HStack {
                                Text("Subtotal")
                                    .foregroundStyle(AppColors.muted)
                                Spacer()
                                Text("$\(subtotal, specifier: "%.2f")")
                                    .foregroundStyle(AppColors.muted)
                            }

                            HStack {
                                Text("Tax")
                                    .foregroundStyle(AppColors.muted)
                                Spacer()
                                Text("$\(tax, specifier: "%.2f")")
                                    .foregroundStyle(AppColors.muted)
                            }

                            Divider()

                            HStack {
                                Text("Total")
                                    .font(.system(size: 34, weight: .bold))
                                Spacer()
                                Text("$\(receipt.total, specifier: "%.2f")")
                                    .font(.system(size: 34, weight: .bold))
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .padding(20)
                    }
                    .receiptPaperCard()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(AppColors.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            isPrinting = false
            printStartTask?.cancel()
            // Wait for the navigation transition to finish before printing.
            // This makes the paper animation readable and avoids overlapping motions.
            printStartTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 420_000_000)
                isPrinting = true
            }
        }
        .onDisappear {
            printStartTask?.cancel()
            onClose()
        }
    }

    private var subtotal: Double {
        receipt.items.reduce(0) { $0 + $1.total }
    }

    private var tax: Double {
        max(0, receipt.total - subtotal)
    }

    private var displayReceiptCode: String {
        "RCP-\(receipt.id.uuidString.prefix(8).uppercased())"
    }

    private func formattedDate(_ date: Date) -> String {
        Self.receiptDateFormatter.string(from: date)
    }
}

private struct TicketPrinterView<Content: View>: View {
    let isPrinting: Bool
    let content: Content

    @State private var progress: CGFloat = 0
    @State private var microSettle: CGFloat = 0
    @State private var printHapticsTask: Task<Void, Never>?
    @State private var repositionTask: Task<Void, Never>?
    @State private var dockToTop = false
    private let printDuration: Double = 1.95
    private let hapticsStartDelay: Double = 0.30

    init(isPrinting: Bool, @ViewBuilder content: () -> Content) {
        self.isPrinting = isPrinting
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let edgeY = proxy.size.height
            let slitHeight: CGFloat = 10
            let slitCornerRadius: CGFloat = 5
            let slitMidY = edgeY - (slitHeight / 2)
            let travel = edgeY + 40 // starts hidden below the slit
            let releaseLineFromBottom: CGFloat = slitHeight - 2
            let releaseTransition: CGFloat = 14

            ZStack(alignment: .bottom) {
                // Ticket layer: clipped so only area ABOVE the slit is visible.
                // This creates a true "printing out of slit" reveal.
                content
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: dockToTop ? .top : .bottom
                    )
                    .offset(y: (1 - progress) * travel + microSettle)
                    // Subtle edge bend/compression while the bottom passes the edge.
                    // It quickly relaxes to flat as printing completes.
                    .rotation3DEffect(
                        .degrees(1.7 * edgeBendProgress),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.55
                    )
                    .blur(radius: 0.35 * edgeBendProgress)
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.06 * edgeBendProgress),
                                Color.white.opacity(0.04 * edgeBendProgress),
                                .clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 14)
                    }
                    .mask(alignment: .top) {
                        Rectangle()
                            .frame(height: max(0, slitMidY))
                    }
                    .modifier(
                        ReceiptEdgeWarpModifier(
                            amount: warpAmount,
                            releaseLineFromBottom: releaseLineFromBottom,
                            releaseTransition: releaseTransition
                        )
                    )
                    .zIndex(2)

                // Single slit element: rounded rectangle border, no fill.
                RoundedRectangle(cornerRadius: slitCornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.18))
                    .overlay {
                        RoundedRectangle(cornerRadius: slitCornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.42), lineWidth: 5.6)
                    }
                    .frame(height: slitHeight)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, -7)
                    .shadow(color: .black.opacity(0.14), radius: 1.2, x: 0, y: 0.8)
                    .zIndex(1)

            }
            .onChange(of: isPrinting) { _, newValue in
                guard newValue else { return }
                progress = 0
                microSettle = 0
                dockToTop = false
                printHapticsTask?.cancel()
                Haptics.stopSoftContinuous()
                repositionTask?.cancel()
                // Mechanical timing: quick start and slower finish.
                withAnimation(.timingCurve(0.20, 0.00, 0.10, 1.0, duration: printDuration)) {
                    progress = 1
                }
                startPrintHaptics()
                // Tiny end settle (very low amplitude).
                DispatchQueue.main.asyncAfter(deadline: .now() + printDuration - 0.02) {
                    withAnimation(.easeOut(duration: 0.09)) {
                        microSettle = -1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                        withAnimation(.easeIn(duration: 0.08)) {
                            microSettle = 0
                        }
                    }
                }
                repositionTask = Task { @MainActor in
                    // After the print phase, move the receipt to the top smoothly.
                    try? await Task.sleep(nanoseconds: UInt64((printDuration + 0.04) * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    withAnimation(.timingCurve(0.18, 0.92, 0.16, 1.0, duration: 1.55)) {
                        dockToTop = true
                    }
                }
            }
            .onDisappear {
                printHapticsTask?.cancel()
                Haptics.stopSoftContinuous()
                repositionTask?.cancel()
            }
        }
    }

    private var edgeBendProgress: CGFloat {
        // Keep pinched early, then snap open in a very short window ("BAM" release).
        let holdUntil: CGFloat = 0.72
        let releaseWindow: CGFloat = 0.04
        if progress <= holdUntil { return 1 }
        return max(0, min(1, 1 - ((progress - holdUntil) / releaseWindow)))
    }

    private var warpAmount: CGFloat {
        // During print phase, keep shader squeeze active and let the release line control expansion.
        // Once the card docks to top, disable warp entirely.
        dockToTop ? 0 : 1
    }

    private func startPrintHaptics() {
        printHapticsTask = Task { @MainActor in
            Haptics.prepare()
            // Align first tick with first visible emergence of the receipt.
            try? await Task.sleep(nanoseconds: UInt64(hapticsStartDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            Haptics.startSoftContinuous(duration: printDuration - hapticsStartDelay)
        }
    }
}

private struct ReceiptEdgeWarpModifier: ViewModifier {
    let amount: CGFloat
    let releaseLineFromBottom: CGFloat
    let releaseTransition: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.visualEffect { view, proxy in
                view.distortionEffect(
                    ShaderLibrary.receiptExitWarp(
                        .float(Float(amount)),
                        .float(Float(proxy.size.width)),
                        .float(Float(proxy.size.height)),
                        .float(Float(releaseLineFromBottom)),
                        .float(Float(releaseTransition))
                    ),
                    maxSampleOffset: CGSize(width: 140, height: 0)
                )
            }
        } else {
            content
        }
    }
}

private struct ScanView: View {
    let onReceiptScanned: (ReceiptModel) -> Void
    @Binding var isCameraSettingsModalVisible: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var cameraStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var scannedValue = ""
    @State private var showScanAlert = false
    @State private var scanAlertTitle = "QR Scanned"
    @State private var isProcessingScan = false
    @State private var scanLinePhase = false
    @State private var showCameraSettingsAlert = false
    #if targetEnvironment(simulator)
    private let isSimulator = true
    #else
    private let isSimulator = false
    #endif

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width - 36, 360)
            VStack(spacing: 18) {
                Text("Digital Receipt")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(AppColors.muted)
                Text("Scan QR")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Spacer(minLength: 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.thinMaterial)

                    if isSimulator {
                        VStack(spacing: 10) {
                            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                            Text("Simulator Camera Not Supported")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Run on your iPhone for live camera QR scanning.")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.muted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 18)
                        }
                    } else if cameraStatus == .authorized {
                        CameraQRScannerView { value in
                            guard !isProcessingScan else { return }
                            isProcessingScan = true
                            scanLinePhase = false
                            defer {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    isProcessingScan = false
                                }
                            }

                            do {
                                let receipt = try ReceiptModel.fromQRCode(value)
                                onReceiptScanned(receipt)
                            } catch {
                                scanAlertTitle = "Invalid QR"
                                scannedValue = error.localizedDescription
                                showScanAlert = true
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                            Text(cameraStatus == .denied ? "Camera access denied" : "Camera access needed")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Enable camera permission in Settings to scan QR receipts.")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.muted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 18)
                        }
                    }

                    // Corner guides
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(AppColors.primary.opacity(0.45), lineWidth: 1.2)

                    ScannerCornerGuides()
                        .stroke(
                            AppColors.primary.opacity(0.55),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )

                    // Animated scan line
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.clear, AppColors.primary.opacity(0.65), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .padding(.horizontal, 22)
                        .opacity(isProcessingScan ? 0 : 1)
                        .offset(y: scanLinePhase ? (side / 2 - 28) : -(side / 2 - 28))
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: scanLinePhase)
                }
                .frame(width: side, height: side)
                .onAppear {
                    scanLinePhase = true
                }

                Spacer(minLength: 8)

                if isSimulator {
                    Button {
                        let demoPayload = """
                        {
                          "store_name":"Simulator FreshMart",
                          "store_address":"123 Main St, San Francisco, CA",
                          "purchase_date":"\(ISO8601DateFormatter().string(from: Date()))",
                          "items":[{"name":"Whole Milk 2L","quantity":1,"unit_price":2.49},{"name":"Sourdough Bread","quantity":1,"unit_price":3.99}],
                          "subtotal":6.48,
                          "tax":0.52,
                          "total":7.00,
                          "payment_method":"credit_card",
                          "receipt_id":"SIM-\(Int(Date().timeIntervalSince1970))"
                        }
                        """
                        do {
                            scanLinePhase = false
                            let receipt = try ReceiptModel.fromQRCode(demoPayload)
                            onReceiptScanned(receipt)
                        } catch {
                            scanAlertTitle = "Invalid QR"
                            scannedValue = error.localizedDescription
                            showScanAlert = true
                        }
                    } label: {
                        Text("Simulate QR Scan")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(18)
        }
        .onAppear {
            if !isSimulator {
                requestCameraAccess()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard !isSimulator, newPhase == .active else { return }
            refreshCameraStatus()
        }
        .onChange(of: showCameraSettingsAlert) { _, newValue in
            isCameraSettingsModalVisible = newValue
        }
        .onDisappear {
            isCameraSettingsModalVisible = false
        }
        .alert(scanAlertTitle, isPresented: $showScanAlert) {
            Button("OK") {}
        } message: {
            Text(scannedValue)
        }
        .overlay {
            if showCameraSettingsAlert {
                ZStack {
                    VStack(spacing: 14) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 52, height: 52)
                            .background(AppColors.accent.opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text("Camera Access Needed")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)

                        Text("Turn on Camera access in Settings to scan QR receipts.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.muted)
                            .multilineTextAlignment(.center)

                        Button {
                            openAppSettings()
                        } label: {
                            Text("Open Settings")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(20)
                    .frame(maxWidth: 320)
                    .glassCard()
                }
            }
        }
    }

    private func requestCameraAccess() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized || status == .denied || status == .restricted {
            cameraStatus = status
            if status == .denied {
                showCameraSettingsAlert = true
            }
            return
        }

        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraStatus = granted ? .authorized : .denied
                if !granted {
                    showCameraSettingsAlert = true
                }
            }
        }
    }

    private func refreshCameraStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraStatus = status
        if status == .denied {
            showCameraSettingsAlert = true
        } else {
            showCameraSettingsAlert = false
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

private struct ScannerCornerGuides: Shape {
    func path(in rect: CGRect) -> Path {
        let inset: CGFloat = 18
        let length: CGFloat = 22
        let radius: CGFloat = 6
        var path = Path()

        // Top-left
        path.move(to: CGPoint(x: inset + length, y: inset))
        path.addLine(to: CGPoint(x: inset + radius, y: inset))
        path.addQuadCurve(
            to: CGPoint(x: inset, y: inset + radius),
            control: CGPoint(x: inset, y: inset)
        )
        path.addLine(to: CGPoint(x: inset, y: inset + length))

        // Top-right
        path.move(to: CGPoint(x: rect.width - inset - length, y: inset))
        path.addLine(to: CGPoint(x: rect.width - inset - radius, y: inset))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - inset, y: inset + radius),
            control: CGPoint(x: rect.width - inset, y: inset)
        )
        path.addLine(to: CGPoint(x: rect.width - inset, y: inset + length))

        // Bottom-left
        path.move(to: CGPoint(x: inset + length, y: rect.height - inset))
        path.addLine(to: CGPoint(x: inset + radius, y: rect.height - inset))
        path.addQuadCurve(
            to: CGPoint(x: inset, y: rect.height - inset - radius),
            control: CGPoint(x: inset, y: rect.height - inset)
        )
        path.addLine(to: CGPoint(x: inset, y: rect.height - inset - length))

        // Bottom-right
        path.move(to: CGPoint(x: rect.width - inset - length, y: rect.height - inset))
        path.addLine(to: CGPoint(x: rect.width - inset - radius, y: rect.height - inset))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - inset, y: rect.height - inset - radius),
            control: CGPoint(x: rect.width - inset, y: rect.height - inset)
        )
        path.addLine(to: CGPoint(x: rect.width - inset, y: rect.height - inset - length))

        return path
    }
}

private struct ProfileView: View {
    @ObservedObject var profileStore: ProfileStore
    @State private var selectedPhoto: PhotosPickerItem?
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR PROFILE")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.1)
                        .foregroundStyle(AppColors.muted)
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.text)
                }
                .padding(.top, 8)

                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                            profileAvatar
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(profileStore.displayName.isEmpty ? "Your name" : profileStore.displayName)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        Spacer()
                    }
                }
                .padding(18)
                .glassCard()

                VStack(alignment: .leading, spacing: 14) {
                    Text("PERSONAL")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.muted)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "person")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                                .frame(width: 28, height: 28)
                                .background(AppColors.accent.opacity(0.65), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                            TextField("Your name", text: $profileStore.displayName)
                                .textInputAutocapitalization(.words)
                                .font(.system(size: 15, weight: .semibold))
                                .focused($isNameFieldFocused)
                        }

                        settingsRow(icon: "dollarsign.circle", title: "Currency") {
                            Picker("Currency", selection: $profileStore.currencyCode) {
                                ForEach(ProfileStore.supportedCurrencies, id: \.self) { currency in
                                    Text(currency).tag(currency)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        settingsRow(icon: "bell", title: "Notifications") {
                            Toggle("", isOn: $profileStore.notificationsEnabled)
                                .labelsHidden()
                        }
                    }
                }
                .padding(18)
                .glassCard()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .simultaneousGesture(
            TapGesture().onEnded {
                isNameFieldFocused = false
            }
        )
        .onChange(of: selectedPhoto) { _, newPhoto in
            guard let newPhoto else { return }
            Task {
                if let data = try? await newPhoto.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        profileStore.setProfileImage(data)
                    }
                }
            }
        }
    }

    private var profileAvatar: some View {
        Group {
            if let image = profileStore.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(profileStore.initials)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppColors.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.accent)
            }
        }
        .frame(width: 74, height: 74)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
    }

    private func settingsRow<Content: View>(icon: String, title: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 28, height: 28)
                .background(AppColors.accent.opacity(0.65), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(title)
                .font(.system(size: 15, weight: .semibold))

            Spacer()
            trailing()
        }
    }
}

