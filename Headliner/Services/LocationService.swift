import Foundation
import CoreLocation

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestCityTimeAndCoordinate() async throws -> (city: String?, localTime: String, timeZone: TimeZone, coordinate: CLLocationCoordinate2D?) {
        let location = try await currentLocationIfAuthorized()
        let placemark = try await reverseGeocode(location: location)
        
        let city = placemark.locality ?? placemark.subAdministrativeArea
        let timeZone = placemark.timeZone ?? .current
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = timeZone
        let localTime = formatter.string(from: Date())
        
        return (city, localTime, timeZone, location.coordinate)
    }
    
    private func currentLocationIfAuthorized() async throws -> CLLocation {
        switch manager.authorizationStatus {
        case .notDetermined:
            await requestWhenInUseAuthorization()
        case .denied, .restricted:
            throw CLError(.denied)
        default:
            break
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocation, Error>) in
            self.continuation = continuation
            manager.requestLocation()
        }
    }
    
    private func requestWhenInUseAuthorization() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            manager.requestWhenInUseAuthorization()
            // Small delay to allow authorization dialog to process
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                continuation.resume()
            }
        }
    }
    
    private func reverseGeocode(location: CLLocation) async throws -> CLPlacemark {
        try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    continuation.resume(returning: placemark)
                } else {
                    continuation.resume(throwing: error ?? CLError(.geocodeFoundNoResult))
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            continuation?.resume(returning: location)
            continuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}