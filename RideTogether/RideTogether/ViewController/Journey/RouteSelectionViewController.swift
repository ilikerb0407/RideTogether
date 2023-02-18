import UIKit
import MapKit
import CoreLocation
import Lottie

class RouteSelectionViewController: UIViewController {
    
    var weatherdata: ResponseBody?
    
    let weatherManger = WeatherManager()
    
    @IBOutlet weak var feelsLikeTempLabel: UILabel!
    
    @IBOutlet weak var humidityLabel: UILabel!
    
    @IBOutlet weak var showtempLabel: UILabel!
    
    @IBOutlet weak var sunriseLabel: UILabel!
    
    @IBOutlet weak var sunsetLabel: UILabel!
    
    @IBOutlet weak var windLabel: UILabel!
    
    func weather() {
        
        weatherManger.getWeatherInfo(latitude: locationManager.location?.coordinate.latitude ?? 25.1, longitude: locationManager.location?.coordinate.longitude ?? 121.12) { [weak self] result in
            
            self?.weatherdata = result
            DispatchQueue.main.async {
                showWeatherInfo()
            }
            
        }
        
        func showWeatherInfo() {
            
            guard let feelslike = weatherdata?.main.feelsLike.roundDouble() else { return }
            feelsLikeTempLabel.text = "\(feelslike) °C"
            guard let humiditydata = weatherdata?.main.humidity else { return }
            humidityLabel.text = "\(humiditydata) %"
            
            guard let tempdata = weatherdata?.main.tempMax.roundDouble() else { return }
            showtempLabel.text = "\(tempdata) °C"
            
            guard let ssunrise = weatherdata?.sys.sunrise else { return }
            let epocTime = TimeInterval(ssunrise)
            
            sunriseLabel.text = "\(epocTime.sunrise()) AM"
            
            guard let ssunset = weatherdata?.sys.sunset else { return }
            let sunsetTime = TimeInterval(ssunset)
            
            sunsetLabel.text = "\(sunsetTime.sunset()) PM"
            
            guard let swind = weatherdata?.wind.speed.roundDouble() else { return }
            windLabel.text = "\(swind) km/h"
            
            guard let weather = weatherdata?.weather[0].main else { return }
            
            if weather == "Rain" {
                
                rainLottieView.isHidden = false
                rainLottieView.play()
                let sheet = UIAlertController(title: nil, message: "下雨天騎車小心！", preferredStyle: .alert)
                let okOption = UIAlertAction(title: "OK", style: .cancel) { _ in
                }
                
                sheet.addAction(okOption)
                present(sheet, animated: true, completion: nil)
            }
            
            if weather == "Clouds" {
                cloudsLottieView.isHidden = false
                cloudsLottieView.play()
                
                let sheet = UIAlertController(title: nil, message: "記得補充水分!", preferredStyle: .alert)
                
                let okOption = UIAlertAction(title: "OK", style: .cancel) { _ in }
                sheet.addAction(okOption)
                present(sheet, animated: true, completion: nil)
            }
            
            if weather == "Drizzle" {
                
                rainLottieView.isHidden = false
                rainLottieView.play()
                let sheet = UIAlertController(title: nil, message: "下雨天騎車小心！", preferredStyle: .alert)
                let okOption = UIAlertAction(title: "OK", style: .cancel) { [self] _ in
                    rainLottieView.isHidden = true
                }
                sheet.addAction(okOption)
                present(sheet, animated: true, completion: nil)
            }
            
            if weather == "Sun" {
               
                sunLottieView.isHidden = false
                sunLottieView.play()
                
                let sheet = UIAlertController(title: nil, message: "記得補充水分!", preferredStyle: .alert)
                
                let okOption = UIAlertAction(title: "OK", style: .cancel) { _ in
                    }
                sheet.addAction(okOption)
                present(sheet, animated: true, completion: nil)
                }
            
            }
    
        }
    
    var directionsVC: DirectionsViewController?
    
    @IBOutlet private var inputContainerView: UIView!
    @IBOutlet private var originTextField: UITextField!
    @IBOutlet private var stopTextField: UITextField!
    @IBOutlet private var extraStopTextField: UITextField!
    @IBOutlet private var calculateButton: UIButton!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var keyboardAvoidingConstraint: NSLayoutConstraint!
    
    @IBOutlet private var suggestionLabel: UILabel!
    @IBOutlet private var suggestionContainerView: UIView!
    @IBOutlet private var suggestionContainerTopConstraint: NSLayoutConstraint!
    
    private var editingTextField: UITextField?
    private var currentRegion: MKCoordinateRegion?
    private var currentPlace: CLPlacemark?
    
    private let locationManager = CLLocationManager()
    private let completer = MKLocalSearchCompleter()
    
    private let defaultAnimationDuration: TimeInterval = 0.25
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        suggestionContainerView.addBorder()
        inputContainerView.addBorder()
        calculateButton.stylize()
        
        completer.delegate = self
        
        beginObserving()
        configureGestures()
        configureTextFields()
        attemptLocationAccess()
        hideSuggestionView(animated: false)
        
        weather()
        
    }
    
    override func viewDidLayoutSubviews() {
        
        inputContainerView.cornerRadius = 30
    }
    
    private lazy var cloudsLottieView: AnimationView = {
        let view = AnimationView(name: "cloud")
        view.loopMode = .loop
        view.frame = CGRect(x: -30, y: -150, width: 400, height: 400)
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        return view
    }()
    
    private lazy var rainLottieView: AnimationView = {
        let view = AnimationView(name: "rain")
        view.loopMode = .loop
        view.frame = CGRect(x: UIScreen.width / 2 - 100, y: -25, width: 200, height: 200)
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        return view
    }()
    
    private lazy var sunLottieView: AnimationView = {
        let view = AnimationView(name: "sun")
        view.loopMode = .loop
        view.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        return view
    }()
    
    private lazy var otherLottieView: AnimationView = {
        let view = AnimationView(name: "otherweather")
        view.loopMode = .loop
        view.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        return view
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        weather()
    }

    // MARK: - Gestures -
    
    private func configureGestures() {
        view.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(handleTap(_:))
            )
        )
        suggestionContainerView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(suggestionTapped(_:))
            )
        )
    }
    
    private func configureTextFields() {
        originTextField.delegate = self
        stopTextField.delegate = self
        extraStopTextField.delegate = self
        
        originTextField.addTarget(
            self,
            action: #selector(textFieldDidChange(_:)),
            for: .editingChanged
        )
        stopTextField.addTarget(
            self,
            action: #selector(textFieldDidChange(_:)),
            for: .editingChanged
        )
        extraStopTextField.addTarget(
            self,
            action: #selector(textFieldDidChange(_:)),
            for: .editingChanged
        )
        
    }
    
    private func attemptLocationAccess() {
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            locationManager.requestLocation()
        }
    }
    
    private func hideSuggestionView(animated: Bool) {suggestionContainerTopConstraint.constant = -1 * (suggestionContainerView.bounds.height + 1)
        
        guard animated else {
            view.layoutIfNeeded()
            return
        }
        
        UIView.animate(withDuration: defaultAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func showSuggestion(_ suggestion: String) {
        suggestionLabel.text = suggestion
        suggestionContainerTopConstraint.constant = -4 // to hide the top corners
        
        UIView.animate(withDuration: defaultAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func presentAlert(message: String) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        present(alertController, animated: true)
        
    }
    
    // MARK: - Actions
    
    @objc private func textFieldDidChange(_ field: UITextField) {
        if field == originTextField && currentPlace != nil {
            currentPlace = nil
            field.text = ""
        }
        
        guard let query = field.contents else {
            hideSuggestionView(animated: true)
            
            if completer.isSearching {
                completer.cancel()
            }
            return
        }
        
        completer.queryFragment = query
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let gestureView = gesture.view
        let point = gesture.location(in: gestureView)
        
        guard
            let hitView = gestureView?.hitTest(point, with: nil),
            hitView == gestureView
        else {
            return
        }
        
        view.endEditing(true)
    }
    
    @objc private func suggestionTapped(_ gesture: UITapGestureRecognizer) {
        
        hideSuggestionView(animated: true)
        editingTextField?.text = suggestionLabel.text
        editingTextField = nil
        
    }
    
    @IBAction private func calculateButtonTapped() {
        
        view.endEditing(true)
        
        calculateButton.isEnabled = false
        activityIndicatorView.startAnimating()
        
        let segment: RouteBuilder.Segment?
        
        if let currentLocation = currentPlace?.location {
            segment = .location(currentLocation)
        } else if let originValue = originTextField.contents {
            segment = .text(originValue)
        } else {
            segment = nil
        }
        
        let stopSegments: [RouteBuilder.Segment] = [
            stopTextField.contents,
            extraStopTextField.contents
        ]
            .compactMap { contents in
                if let value = contents {
                    return .text(value)
                } else {
                    return nil
                }
            }
        
        guard
            let originSegment = segment,
            !stopSegments.isEmpty
        else {
            presentAlert(message: "Please select an origin and at least 1 stop.")
            activityIndicatorView.stopAnimating()
            calculateButton.isEnabled = true
            return
        }
        
        RouteBuilder.buildRoute(
            origin: originSegment,
            stops: stopSegments,
            within: currentRegion
        ) { [self] result in
            self.calculateButton.isEnabled = true
            self.activityIndicatorView.stopAnimating()
            
            switch result {
                
            case .success(let route):
                
                let viewController = DirectionsViewController(route: route)
                
//                self.present(viewController, animated: true)
                if #available(iOS 15.0, *) {
                    if let presentVc = viewController.sheetPresentationController {
                        
                        presentVc.detents = [ .large(), .medium() ]
                        
                        self.navigationController?.present(viewController, animated: true, completion: .none)
                    }
                } else {
                    // Fallback on earlier versions
                }
                
            case .failure(let error):
                let errorMessage: String
                
                switch error {
                case .invalidSegment(let reason):
                    errorMessage = "There was an error with: \(reason)."
                }
                
                self.presentAlert(message: errorMessage)
            }
        }
    }
    
    // MARK: - Notifications
    
    private func beginObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let viewHeight = view.bounds.height - view.safeAreaInsets.bottom
        let visibleHeight = viewHeight - frame.origin.y
        keyboardAvoidingConstraint.constant = visibleHeight + 32
        
        UIView.animate(withDuration: defaultAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITextFieldDelegate

extension RouteSelectionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        hideSuggestionView(animated: true)
        
        if completer.isSearching {
            completer.cancel()
        }
        
        editingTextField = textField
    }
}

// MARK: - CLLocationManagerDelegate

extension RouteSelectionViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else {
            return
        }
        
        let commonDelta: CLLocationDegrees = 25 / 111
        
        let span = MKCoordinateSpan(latitudeDelta: commonDelta, longitudeDelta: commonDelta)
        
        let region = MKCoordinateRegion(center: firstLocation.coordinate, span: span)
        
        currentRegion = region
        completer.region = region
        
        CLGeocoder().reverseGeocodeLocation(firstLocation) { places, _ in
            guard let firstPlace = places?.first, self.originTextField.contents == nil else {
                return
            }
            
            self.currentPlace = firstPlace
            self.originTextField.text = firstPlace.abbreviation
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error requesting location: \(error.localizedDescription)")
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension RouteSelectionViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        guard let firstResult = completer.results.first else {
            return
        }
        
        showSuggestion(firstResult.title)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error suggesting a location: \(error.localizedDescription)")
    }
    
}
