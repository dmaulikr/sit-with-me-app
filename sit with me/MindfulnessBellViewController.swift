//
//  MindfulnessBellViewController.swift
//  sit with me
//
//  Created by Jason La on 9/6/16.
//  Copyright © 2016 Jason La. All rights reserved.
//

import UIKit
import AVFoundation
import UserNotifications
import AudioToolbox

class MindfulnessBellViewController: UIViewController, UIPickerViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bellSoundPicker: UIPickerView!
    @IBOutlet weak var hourPicker: UIPickerView!
    @IBOutlet weak var minutePicker: UIPickerView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var rangeStartPicker: UIPickerView!
    @IBOutlet weak var rangeEndPicker: UIPickerView!
    @IBOutlet weak var soundOnLabel: UILabel!
    
    var pickerHours : [Int] = []
    var pickerMinutes : [Int] = [0, 15, 30, 45]
    var pickerActiveRange : [String] = ["12 am", "1 am", "2 am", "3 am", "4 am", "5 am", "6 am", "7 am", "8 am", "9 am", "10 am", "11 am", "12 pm", "1 pm", "2 pm", "3 pm", "4 pm", "5 pm", "6 pm", "7 pm", "8 pm", "9 pm", "10 pm", "11 pm", "12 am"]
    var bellSounds = ["Hand bell (1x)", "Singing bowl (1x)", "Swiss cow bell (1x)", "Hand bell (2x)", "Singing bowl (2x)", "Swiss cow bell (2x)", "Hand bell (3x)", "Singing bowl (3x)", "Swiss cow bell (3x)", "Vibrate only"]
    
    var hours : Int = 0
    var mins : Int = 0
    //var minsIndex : Int = 0
    var bellSoundIndex : Int = 0
    
    var interval : Double = 0 // given in minutes
    let calendar = Calendar.current
    
    let userDefaults = UserDefaults.standard
    var vibrateOn : Bool = false
    
    var bellSound = URL(fileURLWithPath: Bundle.main.path(forResource: "Hand bell (1x)", ofType: "wav")!)
    var bellAudioPlayer = AVAudioPlayer()
    
    override func viewDidAppear(_ animated: Bool) {
        if let settings = UIApplication.shared.currentUserNotificationSettings{
            if settings.types.contains([.alert, .sound]){
                print("notifications ok")
            } else {
                let alertController = UIAlertController(title: "Mindfulness Bell", message: "Please turn on notifications to use this feature. Go to Settings -> Notifications -> Sit With Me", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        if(userDefaults.integer(forKey: "mindBellInit") == 1){
            titleLabel.isHidden = true
        } else {
            soundOnLabel.isHidden = true
        }
        
        pickerHours += 0...12
        
        hours = userDefaults.integer(forKey: "mindUserHours")
        mins = pickerMinutes[userDefaults.integer(forKey: "mindUserMinsIndex")]
        bellSoundIndex = userDefaults.integer(forKey: "mindUserBellSound")
        
        if(bellSoundIndex == bellSounds.count - 1) {
            vibrateOn = true
        } else {
            vibrateOn = false
        }
        
        if(userDefaults.bool(forKey: "mindBellOn")){
            startButton.setTitle("Turn off", for: UIControlState())
            soundOnLabel.text = "Bells On"
        } else {
            startButton.setTitle("Turn on", for: UIControlState())
            soundOnLabel.text = "Bells Off"
        }
        
        if(hours == 0 && mins == 0){
            userDefaults.set(1, forKey: "mindUserMinsIndex")
            mins = pickerMinutes[1]
        }
        
        if(userDefaults.integer(forKey: "mindStartRange") == 0 && userDefaults.integer(forKey: "mindEndRange") == 0){
            userDefaults.set(10, forKey: "mindStartRange")
            userDefaults.set(20, forKey: "mindEndRange")
        }
        
        hourPicker.selectRow(hours, inComponent: 0, animated: true)
        minutePicker.selectRow(userDefaults.integer(forKey: "mindUserMinsIndex"), inComponent: 0, animated: true)
        bellSoundPicker.selectRow(bellSoundIndex, inComponent: 0, animated: true)
        rangeStartPicker.selectRow(userDefaults.integer(forKey: "mindStartRange"), inComponent: 0, animated: true)
        rangeEndPicker.selectRow(userDefaults.integer(forKey: "mindEndRange"), inComponent: 0, animated: true)
        
        print("bell on: \(userDefaults.bool(forKey: "mindBellOn")), hour: \(hours), mins: \(mins), bell sound: \(bellSounds[bellSoundIndex])")
        // Do any additional setup after loading the view.
    }
    
    @IBAction func startButton(_ sender: AnyObject) {
        userDefaults.set(1, forKey: "mindBellInit")
        titleLabel.isHidden = true
        soundOnLabel.isHidden = false
        
        if (hours == 0 && mins == 0) {
            intervalError()
        } else if (userDefaults.integer(forKey: "mindStartRange") >= userDefaults.integer(forKey: "mindEndRange")) {
            let alertController = UIAlertController(title: "Active Between", message: "Start active hour must must be earlier than end active hour.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            if(userDefaults.bool(forKey: "mindBellOn")){
                stopNotifications()
            } else {
                startNotifications()
            }
        }
    }
    
    func intervalError(){
        let alertController = UIAlertController(title: "Interval", message: "Your interval is 0 minutes. Please select again.", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func startNotifications(){
        soundOnLabel.text = "Bells On"
        startButton.setTitle("Turn off", for: UIControlState())
        userDefaults.set(true, forKey: "mindBellOn")
        interval = Double(self.hours) * 60 + Double(self.mins)

        var totalMins : Int = 0
        var hours : Int = 0
        var mins : Int = 0
        let date = NSDateComponents()
        
        let startHour = userDefaults.integer(forKey: "mindStartRange")
        let endHour = userDefaults.integer(forKey: "mindEndRange")
        
        if #available(iOS 10.0, *){
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.sound = UNNotificationSound.init(named: bellSounds[userDefaults.integer(forKey: "mindUserBellSound")] + ".wav")
            print("\(bellSounds[userDefaults.integer(forKey: "mindUserBellSound")]) + .wav")
            
            while totalMins < (24 * 60) {
                totalMins += Int(interval)
                hours = totalMins / 60
                mins = totalMins % 60
                date.hour = hours
                date.minute = mins
                
                if(hours >= startHour && hours < endHour) || (mins == 0 && hours == endHour){
                    let trigger = UNCalendarNotificationTrigger.init(dateMatching: date as DateComponents, repeats: true)
                    let request = UNNotificationRequest.init(identifier: String(totalMins), content: content, trigger: trigger)
                    center.add(request)
                    print("bell sound set for hour: \(hours), min: \(mins)")
                }
            }
        } else { //for ios 9 and lower
            while totalMins < (24 * 60) {
                totalMins += Int(interval)
                hours = totalMins / 60
                mins = totalMins % 60
                date.hour = hours
                date.minute = mins
                
                if(hours >= startHour && hours < endHour) || (mins == 0 && hours == endHour) {
                    let notification : UILocalNotification = UILocalNotification()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm:ss"
                    notification.fireDate = formatter.date(from: "\(hours):\(mins):00")
                    notification.repeatInterval = NSCalendar.Unit.day
                    notification.soundName = bellSounds[bellSoundIndex] + ".wav"

                    UIApplication.shared.scheduleLocalNotification(notification)
                    print("scheduled bell for \(hours) \(mins)")
                }
            }
        }
    }
    
    func stopNotifications(){
        soundOnLabel.text = "Bells Off"
        bellAudioPlayer = try! AVAudioPlayer(contentsOf: bellSound, fileTypeHint: nil)
        if(bellAudioPlayer.isPlaying == true){
            bellAudioPlayer.stop()
        }
        
        startButton.setTitle("Turn on", for: UIControlState())
        userDefaults.set(false, forKey: "mindBellOn")
        
        if #available(iOS 10.0, *) {
                let center = UNUserNotificationCenter.current()
                center.removeAllPendingNotificationRequests()
                print("ios 10: cleared all notifications")
            }
        else {
            UIApplication.shared.cancelAllLocalNotifications()
            print("ios 9: cleared all notifications")
        }
    }
    
    @IBAction func testBellSound(_ sender: AnyObject) {
        if(vibrateOn == true){
            playVibrate()
        } else {
            playBellSound()
        }
    }
    
    func playBellSound() {
        bellSound = URL(fileURLWithPath: Bundle.main.path(forResource: bellSounds[bellSoundIndex], ofType: "wav")!)
        bellAudioPlayer = try! AVAudioPlayer(contentsOf: bellSound, fileTypeHint: nil)
        bellAudioPlayer.play()
    }
    
    func playVibrate(){
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func numberOfComponentsInPickerView(_ pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return bellSounds.count
        case 1:
            return pickerHours.count
        case 2:
            return pickerMinutes.count
        case 3:
            return pickerActiveRange.count
        case 4:
            return pickerActiveRange.count
        default:
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var pickerString: String
        let pickerLabel = UILabel()
        
        switch pickerView.tag {
        case 0:
            pickerString = bellSounds[row]
        case 1:
            pickerString = String(pickerHours[row])
        case 2:
            pickerString = String(pickerMinutes[row])
        case 3:
            pickerString = pickerActiveRange[row]
        case 4:
            pickerString = pickerActiveRange[row]
        default:
            pickerString = "Not found"
        }
        
        let myTitle = NSAttributedString(string: pickerString, attributes: [NSFontAttributeName:UIFont(name: "HelveticaNeue", size: 20.0)!,NSForegroundColorAttributeName:UIColor.black])
        pickerLabel.attributedText = myTitle
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            let soundString : String = bellSounds[row]
            let soundStringChar = String(soundString[soundString.index(soundString.startIndex, offsetBy: 0)])
            bellSoundIndex = row
            userDefaults.set(row, forKey: "mindUserBellSound")
            if(soundStringChar != "V"){
                vibrateOn = false
            } else {
                vibrateOn = true
            }
        case 1:
            userDefaults.set(pickerHours[row], forKey: "mindUserHours")
            hours = pickerHours[row]
        case 2:
            userDefaults.set(row, forKey: "mindUserMinsIndex")
            mins = pickerMinutes[row]
        case 3:
            userDefaults.set(row, forKey: "mindStartRange")

        case 4:
            userDefaults.set(row, forKey: "mindEndRange")

        default:
            print("error")
        }
        if (hours == 0 && mins == 0) {
            intervalError()
        }
        if(userDefaults.bool(forKey: "mindBellOn") && (hours != 0 || mins != 0)){
            stopNotifications()
            startNotifications()
        }
        print("bell on: \(userDefaults.bool(forKey: "mindBellOn")), hour: \(hours), mins: \(mins), bell sound: \(bellSounds[bellSoundIndex])")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */

}
