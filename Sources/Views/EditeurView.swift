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
        TextEditeurRepresentable(
            contenu: $contenu,
            onRetour: { dismiss() }
        )
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            contenu = store.chapitre(id: chapitreID, dans: texteID)?.contenu ?? ""
        }
        .onChange(of: contenu) {
            store.mettreAJourContenu(chapitreID: chapitreID, dans: texteID, contenu: contenu)
        }
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

    private var doubleTapMarge: UITapGestureRecognizer!
    private var aDejaFocus = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        actualiserMarges()
        if !aDejaFocus {
            aDejaFocus = true
            becomeFirstResponder()
        }
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
        doubleTapMarge = UITapGestureRecognizer(target: self, action: #selector(gererDoubleTap))
        doubleTapMarge.numberOfTapsRequired = 2
        doubleTapMarge.delegate = self
        addGestureRecognizer(doubleTapMarge)
    }

    @objc private func gererDoubleTap() {
        menuHandler?()
    }

    // Retourne vrai si le point se trouve dans la marge gauche ou droite
    private func estDansMarge(_ point: CGPoint) -> Bool {
        let limiteGauche = textContainerInset.left
        let limiteDroite = bounds.width - textContainerInset.right
        return point.x < limiteGauche || point.x > limiteDroite
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

    override func layoutSubviews() {
        super.layoutSubviews()
        editeurTextView.frame = bounds
    }
}

// MARK: - UIGestureRecognizerDelegate

extension EditeurTextView: UIGestureRecognizerDelegate {
    // N'active le geste que si le tap est dans la marge — le double-tap sur le texte
    // (sélection de mot) reste donc intact
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === doubleTapMarge else { return true }
        return estDansMarge(gestureRecognizer.location(in: self))
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return gestureRecognizer === doubleTapMarge
    }
}

