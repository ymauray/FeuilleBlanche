import SwiftUI
import UIKit

// MARK: - Vue SwiftUI

struct EditeurView: View {
    let texteID: UUID
    let chapitreID: UUID

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var contenu = ""

    var body: some View {
        GeometryReader { _ in
            TextEditeurRepresentable(
                contenu: $contenu,
                onRetour: {
                    sauvegarder()
                    dismiss()
                }
            )
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            contenu = store.chapitre(id: chapitreID, dans: texteID)?.contenu ?? ""
        }
        .onDisappear {
            sauvegarder()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            sauvegarder()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            sauvegarder()
        }
    }

    private func sauvegarder() {
        store.mettreAJourContenu(chapitreID: chapitreID, dans: texteID, contenu: contenu)
    }
}

// MARK: - UIViewRepresentable

struct TextEditeurRepresentable: UIViewRepresentable {
    @Binding var contenu: String
    var onRetour: () -> Void

    func makeUIView(context: Context) -> EditeurContainerView {
        let tv = EditeurTextView()
        tv.font = {
            let descriptor = UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .body)
                .withDesign(.serif) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            return UIFont(descriptor: descriptor, size: 18)
        }()
        tv.backgroundColor = .systemBackground
        tv.contentInsetAdjustmentBehavior = .never
        tv.alwaysBounceVertical = true
        tv.delegate = context.coordinator
        tv.menuHandler = onRetour
        tv.definirTexte(contenu)
        return EditeurContainerView(editeurTextView: tv)
    }

    func updateUIView(_ uiView: EditeurContainerView, context: Context) {
        guard uiView.editeurTextView.text != contenu else { return }
        uiView.editeurTextView.definirTexte(contenu)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: EditeurContainerView, context: Context) -> CGSize? {
        guard let width = proposal.width, let height = proposal.height else { return nil }
        return CGSize(width: width, height: height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(contenu: $contenu)
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        private var contenuBinding: Binding<String>

        init(contenu: Binding<String>) {
            self.contenuBinding = contenu
        }

        func textViewDidChange(_ textView: UITextView) {
            contenuBinding.wrappedValue = textView.text
        }
    }
}

// MARK: - Sous-classe UITextView

final class EditeurTextView: UITextView {
    var menuHandler: (() -> Void)?

    private var swipeRetour: UISwipeGestureRecognizer!
    private var aDejaFocus = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        actualiserMarges()
        if !aDejaFocus {
            aDejaFocus = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(clavierVaApparaitre(_:)),
                name: UIResponder.keyboardWillShowNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(clavierVaDisparaitre(_:)),
                name: UIResponder.keyboardWillHideNotification,
                object: nil
            )
            becomeFirstResponder()
        }
    }

    @objc private func clavierVaApparaitre(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        UIView.animate(withDuration: duration) {
            self.contentInset.bottom = keyboardFrame.height
            self.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
        }
    }

    @objc private func clavierVaDisparaitre(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        UIView.animate(withDuration: duration) {
            self.contentInset.bottom = 0
            self.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    // Empêche SwiftUI de dimensionner la vue à la hauteur du texte
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configurerGeste()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configurerGeste()
    }

    // Applique le texte avec le style typographique (indentation première ligne)
    func definirTexte(_ texte: String) {
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = 24
        style.alignment = .justified
        style.paragraphSpacing = 8
        let attributs: [NSAttributedString.Key: Any] = [
            .font: font ?? UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.label,
            .paragraphStyle: style
        ]
        typingAttributes = attributs
        attributedText = NSAttributedString(string: texte, attributes: attributs)
    }

    // Recalcule les marges à chaque changement de safe area (rotation, Dynamic Island)
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        actualiserMarges()
    }

    func actualiserMarges() {
        textContainerInset = UIEdgeInsets(
            top: max(safeAreaInsets.top, 24),
            left: max(safeAreaInsets.left, 24),
            bottom: max(safeAreaInsets.bottom, 24),
            right: max(safeAreaInsets.right, 24)
        )
    }

    private func configurerGeste() {
        swipeRetour = UISwipeGestureRecognizer(target: self, action: #selector(gererSwipe))
        swipeRetour.direction = .right
        addGestureRecognizer(swipeRetour)
    }

    @objc private func gererSwipe() {
        menuHandler?()
    }
}

// MARK: - Container

final class EditeurContainerView: UIView {
    let editeurTextView: EditeurTextView

    init(editeurTextView: EditeurTextView) {
        self.editeurTextView = editeurTextView
        super.init(frame: .zero)
        addSubview(editeurTextView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        editeurTextView.frame = bounds
    }
}


