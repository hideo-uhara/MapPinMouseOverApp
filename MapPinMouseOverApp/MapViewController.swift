//
// MapViewController.swift
//

import Cocoa
import MapKit


class PhotoAnnotation: MKPointAnnotation {
	var path: String
	var popoverViewController: PopoverViewController! = nil
	
	init(path: String, latitude: Double, longitude: Double) {
		self.path = path
		
		super.init()
		self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
}

class MapView: MKMapView {
	
	override func hitTest(_ point: NSPoint) -> NSView? {
		var hitView: NSView? = super.hitTest(point)
		
		while hitView != nil {
			if hitView is MKAnnotationView {
				return nil
			}
			
			hitView = hitView?.superview
		}
		
		return super.hitTest(point)
	}
}

class MapViewController: NSViewController {
	
	let imagePaths: [String] = [
		"IMG_3802.jpeg",
		"IMG_3809.jpeg",
		"IMG_3813.jpeg",
	]
	
	var pinList: [MKPointAnnotation] = []
	var mouseEnteredViews: [MKAnnotationView] = []
	var deselectAnnotationTimer: Timer! = nil
	
	@IBOutlet var mapView: MKMapView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		for imagePath in self.imagePaths {
			let imageUrl: URL = (Bundle.main.resourceURL?.appendingPathComponent("images", isDirectory: true).appendingPathComponent(imagePath, isDirectory: false))!
			let image: CIImage = CIImage(contentsOf: imageUrl)!
			let properties: [String : Any] = image.properties
			let gps: [String : Any] = properties["{GPS}"] as! [String : Any]
			let latitudeRef: String = gps[kCGImagePropertyGPSLatitudeRef as String] as! String
			let longitudeRef: String = gps[kCGImagePropertyGPSLongitudeRef as String] as! String
			var latitude: Double = gps[kCGImagePropertyGPSLatitude as String] as! Double
			var longitude: Double = gps[kCGImagePropertyGPSLongitude as String] as! Double
			
			if latitudeRef == "S" {
				latitude = -latitude
			}
			if longitudeRef == "W" {
				longitude = -longitude
			}
			
			let photoPin: PhotoAnnotation = PhotoAnnotation(path: imageUrl.path, latitude: latitude, longitude: longitude)
			
			self.pinList.append(photoPin)
			self.mapView.addAnnotation(photoPin)
		}
		
		self.mapView.showAnnotations(self.pinList, animated: true)
	}

	override var representedObject: Any? {
		didSet {
		}
	}
	
}

extension MapViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
		
		for annotationView in views {
			if #available(macOS 11.0, *) {
				if let annotationView = annotationView as? MKMarkerAnnotationView {
					if annotationView.annotation is PhotoAnnotation {
						annotationView.markerTintColor = .green
					} else {
						annotationView.markerTintColor = nil // default
					}
				}
			} else {
				if let annotationView = annotationView as? MKPinAnnotationView {
					if annotationView.annotation is PhotoAnnotation {
						annotationView.pinTintColor = .green
					} else {
						annotationView.pinTintColor = nil // default
					}
				}
			}
			
			// ?????????????????????TrackingArea?????????
			let trackingAreas: [NSTrackingArea] = annotationView.trackingAreas
			
			for trackingArea in trackingAreas {
				annotationView.removeTrackingArea(trackingArea)
			}
			
			// ?????????TrackingArea?????????
			let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow]
			let rect: NSRect = NSRect(origin: .zero, size: annotationView.frame.size)
			let trackingArea: NSTrackingArea = NSTrackingArea(rect: rect, options: options, owner: self, userInfo: ["annotationView": annotationView])
			
			annotationView.addTrackingArea(trackingArea)
		}
	}
	
	func selectDeselectAnnotation(annotationView: MKAnnotationView) {
		
		// ??????????????????????????????????????????AnnotationView?????????
		var maxIndex: Int = -1
		var frontMostView: MKAnnotationView? = nil
		
		for mouseEnteredView in self.mouseEnteredViews {
			if let index = annotationView.superview!.subviews.firstIndex(of: mouseEnteredView) {
				if index > maxIndex {
					maxIndex = index
					frontMostView = mouseEnteredView
				}
			}
		}
		
		if let frontMostView = frontMostView, let annotation = frontMostView.annotation {
			// ??????????????????????????????????????????AnnotationView???Annotation?????????
			self.mapView.selectAnnotation(annotation, animated: true)
		} else {
			// ????????????????????????AnnotationView??????????????????Annotation??????????????????
			self.deselectAnnotationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (timer) in
				
				for annotation: MKAnnotation in self.mapView.selectedAnnotations {
					self.mapView.deselectAnnotation(annotation, animated: true)
				}
			 })
		}
	}
	
	override func mouseEntered(with event: NSEvent) {
		
		if let userInfo = event.trackingArea?.userInfo as? [String : AnyObject] {
			if let annotationView = userInfo["annotationView"] as? MKAnnotationView {
				
				if self.deselectAnnotationTimer != nil {
					self.deselectAnnotationTimer.invalidate()
					self.deselectAnnotationTimer = nil
				}
				
				self.mouseEnteredViews.append(annotationView)
				self.selectDeselectAnnotation(annotationView: annotationView)
			}
		}
		
	}
	
	override func mouseExited(with event: NSEvent) {
		
		if let userInfo = event.trackingArea?.userInfo as? [String : AnyObject] {
			if let annotationView = userInfo["annotationView"] as? MKAnnotationView {
				self.mouseEnteredViews.removeAll(where: { $0 == annotationView })
				self.selectDeselectAnnotation(annotationView: annotationView)
			}
		}
	}
	
	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		
		if let photoAnnotation: PhotoAnnotation = view.annotation as? PhotoAnnotation {
			
			let popoverViewController: PopoverViewController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "PopoverViewController") as! PopoverViewController
			
			popoverViewController.mapView = self.mapView
			popoverViewController.annotation = photoAnnotation
			
			// ?????????????????????????????????????????????????????????
			if let origImage: NSImage = NSImage(contentsOfFile: photoAnnotation.path) {
				
				// dpi?????????
				let imageRep: NSImageRep = origImage.representations.first!
				let imageSize: NSSize = NSSize(width: imageRep.pixelsWide, height: imageRep.pixelsHigh)
				let image: NSImage = NSImage(size: imageSize)
				
				image.addRepresentation(imageRep)
				popoverViewController.image = image
			}
			
			self.present(popoverViewController, asPopoverRelativeTo: view.bounds, of: view, preferredEdge: .minY, behavior: .applicationDefined)
			photoAnnotation.popoverViewController = popoverViewController
			
			return
		}
		
	}
	
	func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
		
		if let photoAnnotation: PhotoAnnotation = view.annotation as? PhotoAnnotation {
			if photoAnnotation.popoverViewController != nil {
				photoAnnotation.popoverViewController.dismiss(nil)
				photoAnnotation.popoverViewController = nil
				
				return
			}
		}
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		
		if #available(macOS 11.0, *) {
			let pinId: String = "photoPin"
			
			var annotationView: MKMarkerAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: pinId) as? MKMarkerAnnotationView
			
			if annotationView == nil {
				annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: pinId)
			} else {
				annotationView!.annotation = annotation
			}
						
			//annotationView!.displayPriority = .required // ??????????????????????????????
			
			return annotationView

		} else {
			return nil
		}
			
	}

}

