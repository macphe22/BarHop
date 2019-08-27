//
//  RegisterVC.swift
//  BarHop
//
//  Created by John Landy on 8/26/19.
//  Copyright © 2019 Scott Macpherson. All rights reserved.
//

import UIKit
import CoreLocation
import MessageUI

class RegisterVC: UIViewController, MFMailComposeViewControllerDelegate {
    
    var coo: (Double, Double) = (0, 0)

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var streetAddressTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipCodeTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var submitBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Handle keyboard exiting
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        // Set up making sure text fields filled in before button active
        setUpButtonGuards()
        // Set up navigation bar logo
        let logoImage = UIImage(named: "NavBarLogo")
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        logoImageView.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoImageView)
        // Set submit button's attributes
        let midBlue = UIColor(red: 0, green: 191/255, blue: 255/255, alpha: 1)
        submitBtn.layer.cornerRadius = 8
        submitBtn.layer.borderWidth = 1
        submitBtn.layer.borderColor = midBlue.cgColor
        submitBtn.titleLabel?.textColor = midBlue
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    // Function to handle setting up guards that only allow the button to be visible to the user when all text fields have been filled out
    func setUpButtonGuards() {
        submitBtn.isHidden = true
        // Add targets for all textFields
        nameTextField.addTarget(self, action: #selector(textFieldsNotEmpty), for: .editingChanged)
        streetAddressTextField.addTarget(self, action: #selector(textFieldsNotEmpty), for: .editingChanged)
        cityTextField.addTarget(self, action: #selector(textFieldsNotEmpty), for: .editingChanged)
        stateTextField.addTarget(self, action: #selector(textFieldsNotEmpty), for: .editingChanged)
        zipCodeTextField.addTarget(self, action: #selector(textFieldsNotEmpty), for: .editingChanged)
        phoneNumberTextField.addTarget(self, action: #selector(textFieldsNotEmpty), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(textFieldsNotEmpty), for: .editingChanged)
    }
    
    // Selector function to check if all text fields have been filled in
    @objc func textFieldsNotEmpty(sender: UITextField) {
        guard
            let name = nameTextField.text, !name.isEmpty,
            let street = streetAddressTextField.text, !street.isEmpty,
            let city = cityTextField.text, !city.isEmpty,
            let state = stateTextField.text, !state.isEmpty,
            let zip = zipCodeTextField.text, !zip.isEmpty,
            let phone = phoneNumberTextField.text, !phone.isEmpty,
            let email = emailTextField.text, !email.isEmpty
        else {
            self.submitBtn.isHidden = true
            return
        }
        // enable okButton if all conditions are met
        submitBtn.isHidden = false
    }
    
    // Function for converting the given street address to coordinates to be used in the Bars table
    func forwardGeoCoding() {
        let fullAddr: String = "\(streetAddressTextField.text!), \(cityTextField.text!), \(stateTextField.text!) \(zipCodeTextField.text!)"
        // Create a CLGeocoder object instance and use it to convert the address to coordinates
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(fullAddr) { (placemarks, error) in
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
            else {
                // handle no location found
                self.alertAddressFailure()
                return
            }
            // Gather our coordinates
            self.coo = (location.coordinate.latitude, location.coordinate.longitude)
            // Continue to email us the user's information
            self.sendEmail(coordinates: self.coo)
        }
    }
    
    // Function that handles alerting user to re-enter address
    func alertAddressFailure() {
        let alertMessage = "Unable to verify address, please try again."
        let alert = UIAlertController(title: "Status", message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    // Function that handles alerting user that email failed to send
    func alertEmailFailure() {
        let alertMessage = "Unable to send email, please try again."
        let alert = UIAlertController(title: "Status", message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    // Function to handle sending email message with venue's inforamtion to us
    func sendEmail(coordinates: (Double, Double)) {
        if MFMailComposeViewController.canSendMail() {
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            mailVC.setToRecipients(["barhopios@gmail.com"])
            mailVC.setSubject("\(nameTextField.text!) Business Message")
            let messageBody = "Name: \(nameTextField.text!)<br>Address: \(streetAddressTextField.text!)<br>City: \(cityTextField.text!)<br>State: \(stateTextField.text!)<br>Zip Code: \(zipCodeTextField.text!)<br>Latitude: \(coordinates.0)<br>Longitude: \(coordinates.1)<br>Phone Number: \(phoneNumberTextField.text!)<br>Email Address: \(emailTextField.text!)"
            mailVC.setMessageBody(messageBody, isHTML: true)
            
            present(mailVC, animated: true)
        } else {
            // show failure alert
            alertEmailFailure()
        }
    }

    // Handles submission of form
    @IBAction func submitBtnClicked(_ sender: Any) {
        forwardGeoCoding()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
