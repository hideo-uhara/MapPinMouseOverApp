//
// PopoverViewController.swift
//

import MapKit
import Cocoa

class PopoverViewController: NSViewController {
	
	var mapView: MKMapView! = nil
	var image: NSImage? = nil
	var annotation: MKAnnotation! = nil
	
	@IBOutlet var imageButton: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.imageButton.image = self.image
	}
	
	override var representedObject: Any? {
		didSet {
		}
	}
	
	@IBAction func imageButtonAction(_ sender: Any) {
	}
}

extension PopoverViewController: NSPopoverDelegate {
	
	func popoverDidClose(_ notification: Notification) {
		
		// ピンの選択解除
		for annotation: MKAnnotation in self.mapView.selectedAnnotations {
			self.mapView.deselectAnnotation(annotation, animated: true)
		}
		
	}
}
