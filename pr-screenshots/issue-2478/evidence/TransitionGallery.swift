// Continuous simulator recording of system appearance changes on existing views.
// The diagnostics inspect production layer colors; they never assign or repair them.
import UIKit
import SwiftCharts
import LoopKit
import LoopAlgorithm
import LoopKitUI

private struct TransitionSample: GlucoseValue {
    let startDate: Date
    let quantity: LoopQuantity
}

@main
final class TransitionApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        // Follow simulator system appearance, including changes made after launch.
        window.overrideUserInterfaceStyle = .unspecified
        window.traitOverrides.userInterfaceLevel = .elevated
        window.rootViewController = TransitionGallery()
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}

private final class TransitionGallery: UIViewController {
    private let gauge = SegmentedGaugeBarView()
    private let stack = UIStackView()
    private let appearanceLabel = UILabel()
    private let gaugeCheck = UILabel()
    private let backgroundCheck = UILabel()
    private var manager: ChartsManager!
    private var chart: Chart!
    private var scrubOverlay: UIView!
    private var changesObserved = 0
    private var appeared = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        stack.addArrangedSubview(label("Live appearance transition", size: 24))
        #if BEFORE
        stack.addArrangedSubview(label("BEFORE · Production components", size: 15))
        #else
        stack.addArrangedSubview(label("AFTER · Production components", size: 15))
        #endif
        appearanceLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        appearanceLabel.numberOfLines = 0
        stack.addArrangedSubview(appearanceLabel)

        let gaugeCard = card()
        gaugeCard.addArrangedSubview(label("Preset gauge — 120%", size: 18))
        gauge.numberOfSegments = 2
        gauge.startColor = .systemBlue
        gauge.endColor = .systemOrange
        gauge.borderColor = .systemGray
        gauge.borderWidth = 1
        gauge.backgroundColor = .systemGray6
        gauge.progress = 1.2
        gauge.heightAnchor.constraint(equalToConstant: 36).isActive = true
        gaugeCard.addArrangedSubview(gauge)
        gaugeCard.addArrangedSubview(label("Expected current colors (native UIColors)", size: 13))
        let swatches = UIStackView()
        swatches.spacing = 8
        swatches.distribution = .fillEqually
        for (title, color) in [("Start", UIColor.systemBlue), ("End", .systemOrange), ("Border", .systemGray)] {
            let swatch = label(title, size: 13)
            swatch.textAlignment = .center
            swatch.textColor = .white
            swatch.backgroundColor = color
            swatch.heightAnchor.constraint(equalToConstant: 30).isActive = true
            swatches.addArrangedSubview(swatch)
        }
        gaugeCard.addArrangedSubview(swatches)
        gaugeCheck.font = .systemFont(ofSize: 15, weight: .bold)
        gaugeCheck.numberOfLines = 0
        gaugeCard.addArrangedSubview(gaugeCheck)
        stack.addArrangedSubview(gaugeCard)

        let chartCard = card()
        chartCard.addArrangedSubview(label("Bolus chart — held scrub selection", size: 18))
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 9))!
        let values = (0...12).map {
            TransitionSample(startDate: start.addingTimeInterval(Double($0) * 900),
                quantity: LoopQuantity(unit: .milligramsPerDeciliter, doubleValue: 160 - Double($0) * 4))
        }
        let provider = PredictedGlucoseChart()
        provider.setGlucoseValues(Array(values.prefix(5)))
        provider.setPredictedGlucoseValues(Array(values.dropFirst(4)))
        var settings = ChartSettings()
        settings.top = 12
        settings.trailing = 8
        settings.clipInnerFrame = false
        #if BEFORE
        let palette = ChartColorPalette(axisLine: .clear, axisLabel: .secondaryLabel, grid: .separator,
            presetTint: .systemIndigo, glucoseTint: .systemTeal, insulinTint: .systemOrange, carbTint: .systemGreen)
        #else
        let palette = ChartColorPalette(axisLine: .clear, axisLabel: .secondaryLabel, grid: .separator,
            presetTint: .systemIndigo, glucoseTint: .systemTeal, insulinTint: .systemOrange, carbTint: .systemGreen,
            background: .secondarySystemGroupedBackground)
        #endif
        manager = ChartsManager(colors: palette, settings: settings, charts: [provider], traitCollection: view.traitCollection)
        manager.startDate = start
        manager.maxEndDate = values.last!.startDate
        manager.updateEndDate(values.last!.startDate)
        manager.gestureRecognizer = UILongPressGestureRecognizer()
        manager.prerender()
        let width = view.bounds.width - 64
        chart = manager.chart(atIndex: 0, frame: CGRect(x: 0, y: 0, width: width, height: 240))!
        chart.view.heightAnchor.constraint(equalToConstant: 240).isActive = true
        chartCard.addArrangedSubview(chart.view)
        let layers = Mirror(reflecting: chart!).children.first { $0.label == "layers" }!.value as! [ChartLayer]
        for case let layer as ChartPointsTouchHighlightLayer<ChartPoint, UIView> in layers {
            let points = layer.chartPointsModels.map(\.chartPoint)
            layer.highlightedPoint = points[points.count / 2]
            scrubOverlay = layer.view!.subviews.first!.subviews.first!
        }
        backgroundCheck.font = .systemFont(ofSize: 15, weight: .bold)
        backgroundCheck.numberOfLines = 0
        chartCard.addArrangedSubview(backgroundCheck)
        stack.addArrangedSubview(chartCard)

        let identities = label("Same instances throughout:\nview \(identity(self))\ngauge \(identity(gauge))\nchart \(identity(chart.view))", size: 12)
        identities.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        stack.addArrangedSubview(identities)
        stack.addArrangedSubview(label("Synthetic data · No navigation or relaunch", size: 12))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appeared = true
        refreshDiagnostics()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if appeared, let previousTraitCollection,
           previousTraitCollection.userInterfaceStyle != traitCollection.userInterfaceStyle {
            changesObserved += 1
        }
        // Read after inherited traits have reached the existing child views.
        DispatchQueue.main.async { [weak self] in self?.refreshDiagnostics() }
    }

    private func refreshDiagnostics() {
        guard isViewLoaded, chart != nil else { return }
        appearanceLabel.text = "\(traitCollection.userInterfaceStyle == .dark ? "DARK" : "LIGHT") · Changes observed: \(changesObserved)"
        let colors = Mirror(reflecting: gauge.layer).children
        let expected: [(String, UIColor)] = [("startColor", .systemBlue), ("endColor", .systemOrange), ("gaugeBorderColor", .systemGray)]
        let matches = expected.allSatisfy { name, color in
            guard let value = colors.first(where: { $0.label == name })?.value else { return false }
            let actual = value as! CGColor
            return actual == color.resolvedColor(with: gauge.traitCollection).cgColor
        }
        gaugeCheck.text = "Gauge colors: \(matches ? "MATCH current appearance" : "MISMATCH — colors stayed stale")"
        gaugeCheck.textColor = matches ? .systemGreen : .systemRed
        let backgroundMatches = scrubOverlay.backgroundColor?.resolvedColor(with: scrubOverlay.traitCollection)
            == UIColor.secondarySystemGroupedBackground.resolvedColor(with: scrubOverlay.traitCollection)
        backgroundCheck.text = "Scrub background: \(backgroundMatches ? "MATCH card" : "MISMATCH with card")"
        backgroundCheck.textColor = backgroundMatches ? .systemGreen : .systemRed
    }

    private func identity(_ object: AnyObject) -> String {
        String(describing: ObjectIdentifier(object))
    }

    private func label(_ text: String, size: CGFloat) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }

    private func card() -> UIStackView {
        let card = UIStackView()
        card.axis = .vertical
        card.spacing = 12
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.isLayoutMarginsRelativeArrangement = true
        card.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return card
    }
}
