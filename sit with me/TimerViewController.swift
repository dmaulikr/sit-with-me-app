//
//  TimerViewController.swift
//  sit with me
//
//  Created by Jason La on 9/1/16.
//  Copyright © 2016 Jason La. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class TimerViewController: UIViewController, UIPickerViewDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var minsLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var hourPicker: UIPickerView!
    @IBOutlet weak var minutePicker: UIPickerView!
    @IBOutlet weak var bellSoundPicker: UIPickerView!
    @IBOutlet weak var ambientSoundPicker: UIPickerView!
    @IBOutlet weak var playBellButton: UIButton!
    @IBOutlet weak var playAmbientButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    var pickerHours : [Int] = []
    var pickerMinutes : [Int] = []
    var bellSounds = ["Hand bell (1x)", "Singing bowl (1x)", "Swiss cow bell (1x)", "Vibrate (1x)", "Hand bell (2x)", "Singing bowl (2x)", "Swiss cow bell (2x)", "Vibrate (2x)", "Hand bell (3x)", "Singing bowl (3x)", "Swiss cow bell (3x)", "Vibrate (3x)"]
    var ambientSounds = ["None", "Wind", "Rain", "Stream", "Frogs", "Crickets"]
    var totalSecs : Int = 0
    var hours : Int = 0
    var mins : Int = 0
    var remainingHours : Int = 0
    var remainingMins : Int = 0
    var remainingSecs : Int = 0
    var timerRunning : Bool = false
    var timerStarted : Bool = false
    var timerChanged : Bool = false
    var timer : Timer!
    var ambientTimer : Timer!
    var bellTimer : Timer!
    var ambientDelay : Double = 0
    let bellDelay : Double = 6.0
    var vibrateOn : Bool = false
    
    var ambientSoundOn : Bool = false
    var bellSound = URL(fileURLWithPath: Bundle.main.path(forResource: "Hand bell (1x)", ofType: "wav")!)
    var ambientSound = URL(fileURLWithPath: Bundle.main.path(forResource: "Crickets", ofType: "wav")!)
    
    var bellAudioPlayer = AVAudioPlayer()
    var ambientAudioPlayer = AVAudioPlayer()
    var ambientTestAudioPlayer = AVAudioPlayer()
    
    let userDefaults = UserDefaults.standard
    var numBellSounds : Int = 1
    var bellCounter : Int = 0
    var bellPlayed : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerHours += 0...12
        pickerMinutes += 0...60
                
        hours = userDefaults.integer(forKey: "userHours")
        mins = userDefaults.integer(forKey: "userMins")
        numBellSounds = userDefaults.integer(forKey: "userNumBells")
        
        timeLabel.isHidden = true
        titleLabel.isHidden = false
        
        if(hours == 0 && mins == 0){
            mins = 15
        }
        hourPicker.selectRow(hours, inComponent: 0, animated: true)
        minutePicker.selectRow(mins, inComponent: 0, animated: true)
        bellSoundPicker.selectRow(userDefaults.integer(forKey: "userBellSound"), inComponent: 0, animated: true)
        ambientSoundPicker.selectRow(userDefaults.integer(forKey: "userAmbientSound"), inComponent: 0, animated: true)
        
        setHoursMins()
        
        let soundString : String = bellSounds[userDefaults.integer(forKey: "userBellSound")]
        let soundStringChar = String(soundString[soundString.index(soundString.startIndex, offsetBy: 0)])

        if(soundStringChar == "V"){
            vibrateOn = true
        }
        
        if(vibrateOn == false){
            bellSound = URL(fileURLWithPath: Bundle.main.path(forResource: bellSounds[userDefaults.integer(forKey: "userBellSound")], ofType: "wav")!)
        }
        if(ambientSounds[userDefaults.integer(forKey: "userAmbientSound")] != "None"){
            ambientSound = URL(fileURLWithPath: Bundle.main.path(forResource: ambientSounds[userDefaults.integer(forKey: "userAmbientSound")], ofType: "wav")!)
            ambientSoundOn = true
        }

        setHoursMins()
        
        print("hours: \(hours), mins: \(mins), bell sound: \(bellSounds[userDefaults.integer(forKey: "userBellSound")]), ambient sound: \(ambientSounds[userDefaults.integer(forKey: "userAmbientSound")]), num of vibs: \(userDefaults.integer(forKey: "userNumBells")), vibrate on: \(vibrateOn)")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func startTimer(_ sender: AnyObject) {
    
        if(timerRunning == false) {
            if(timerStarted == false || timerChanged == true) {
                totalSecs = 60 * 60 * hours + 60 * mins
                timerChanged = false
                ambientDelay = Double(numBellSounds + 1) * bellDelay
            } else {
                if(totalSecs > 60 * 60 * hours + 60 * mins - 10) {
                    ambientDelay = bellDelay
                } else {
                    ambientDelay = 0.0
                }
            }
            
            if(totalSecs == 0){
                let alertController = UIAlertController(title: "Sit With Me", message: "Please select a mediation time.", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                present(alertController, animated: true, completion: nil)
            } else {
                titleLabel.isHidden = true
                dimmerOn()
                disableButtons()
                
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(TimerViewController.updateTimer), userInfo: nil, repeats: true)
                timerStarted = true
                timeLabel.isHidden = false
                //updateTimer()
                timerRunning = true
                startButton.setTitle("Stop", for: UIControlState())
                
                if(totalSecs > 15){
                    ambientTimer = Timer.scheduledTimer(timeInterval: ambientDelay, target: self, selector: #selector(TimerViewController.playAmbientSound), userInfo: nil, repeats: false)
                }
            }
            
        } else {
            stopAmbientPlayer()
            stopBellSoundPlayer()
            
            startButton.setTitle("Start", for: UIControlState())
            timerRunning = false
            
            if(ambientTimer != nil){
                ambientTimer.invalidate()
                ambientTimer = nil
            }
            
            if(bellTimer != nil){
                bellTimer.invalidate()
                bellTimer = nil
            }
            timer.invalidate()
            timer = nil
            
            dimmerOff()
            enableButtons()
        }
    }

    func setHoursMins(){
        if(userDefaults.integer(forKey: "userHours") == 1){
            hoursLabel.text = "hour"
        } else {
            hoursLabel.text = "hours"
        }
        
        if(userDefaults.integer(forKey: "userMins") == 1) {
            minsLabel.text = "min"
        } else {
            minsLabel.text = "mins"
        }
    }
    
    func dimmerOn(){
        UIApplication.shared.isIdleTimerDisabled = true
        self.view.alpha = 0.3
    }
    
    func dimmerOff(){
        UIApplication.shared.isIdleTimerDisabled = false
        self.view.alpha = 1.0
    }
    
    func playAmbientSound(){
        if(ambientSoundOn == true){
            ambientAudioPlayer = try! AVAudioPlayer(contentsOf: ambientSound, fileTypeHint: nil)
            ambientAudioPlayer.numberOfLoops = totalSecs / 10
            ambientAudioPlayer.play()
        }
    }
    
    func disableButtons(){
        backButton.isEnabled = false
        resetButton.isEnabled = false
        playBellButton.isEnabled = false
        playAmbientButton.isEnabled = false
        bellSoundPicker.isUserInteractionEnabled = false
        ambientSoundPicker.isUserInteractionEnabled = false
        hourPicker.isUserInteractionEnabled = false
        minutePicker.isUserInteractionEnabled = false
    }
    
    func enableButtons(){
        backButton.isEnabled = true
        resetButton.isEnabled = true
        playBellButton.isEnabled = true
        playAmbientButton.isEnabled = true
        bellSoundPicker.isUserInteractionEnabled = true
        ambientSoundPicker.isUserInteractionEnabled = true
        hourPicker.isUserInteractionEnabled = true
        minutePicker.isUserInteractionEnabled = true
    }
    
    func startVibrate(){
        bellCounter = numBellSounds - 1
        vibrate()
        bellTimer = Timer.scheduledTimer(timeInterval: bellDelay, target: self, selector: #selector(TimerViewController.multiVibrate), userInfo: nil, repeats: true)
    }
    
    func multiVibrate(){
        if(bellCounter > 0){
            vibrate()
            bellCounter -= 1
        } else {
            if(bellTimer != nil) {
                bellTimer.invalidate()
                bellTimer = nil
            }
        }
    }
    
    func vibrate(){
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    /*
    func startBellSounds(){
        bellCounter = numBellSounds - 1
        playBellSound()
        bellTimer = Timer.scheduledTimer(timeInterval: bellDelay, target: self, selector: #selector(TimerViewController.playMultiBells), userInfo: nil, repeats: true)
    }
    
    func playMultiBells(){
        if(bellCounter > 0){
            bellAudioPlayer = try! AVAudioPlayer(contentsOf: bellSound, fileTypeHint: nil)
            bellAudioPlayer.play()
            bellCounter -= 1
        } else {
            if(bellTimer != nil) {
                bellTimer.invalidate()
                bellTimer = nil
            }
        }
    }*/
    
    func playBellSound(){
        bellAudioPlayer = try! AVAudioPlayer(contentsOf: bellSound, fileTypeHint: nil)
        bellAudioPlayer.play()
    }
    
    @IBAction func testBellSound(_ sender: AnyObject) {
        if(vibrateOn != true){
            playBellSound()
        } else {
            startVibrate()
            print("vibing")
        }
    }
    
    
    @IBAction func testAmbientSound(_ sender: AnyObject) {
        if(ambientSounds[ambientSoundPicker.selectedRow(inComponent: 0)] != "None" && timerRunning == false){
            ambientAudioPlayer = try! AVAudioPlayer(contentsOf: ambientSound, fileTypeHint: nil)
            ambientAudioPlayer.play()
            ambientTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(TimerViewController.stopAmbientPlayer), userInfo: nil, repeats: false)
        }

    }

    func updateTimer() {
        totalSecs -= 1
        
        remainingHours = totalSecs / (60 * 60)
        remainingMins = (totalSecs / 60) % 60
        remainingSecs = totalSecs % 60
        
        timeLabel.text = "\(remainingHours)h : \(remainingMins)m : \(remainingSecs)s"

        if(totalSecs == hours * 60 * 60 + mins * 60 - 3){
            if(vibrateOn == false){
                playBellSound()
            } else {
                startVibrate()
            }
        }
        
        if(totalSecs == 5){
            stopAmbientPlayer()
        }
        
        if(totalSecs == 0){
            
            if(vibrateOn == false){
                playBellSound()
            } else {
                startVibrate()
            }
            
            startButton.setTitle("Start", for: UIControlState())
            
            timerRunning = false
            timerStarted = false
            timer.invalidate()
            timer = nil
            
            totalSecs = 60 * 60 * hours + 60 * mins
            
            dimmerOff()
            enableButtons()
        }
    }
    
    func stopBellSoundPlayer(){
        bellAudioPlayer = try! AVAudioPlayer(contentsOf: bellSound, fileTypeHint: nil)
        if(bellAudioPlayer.isPlaying == true){
            bellAudioPlayer.stop()
        }
    }
    
    func stopAmbientPlayer(){
        ambientAudioPlayer = try! AVAudioPlayer(contentsOf: ambientSound, fileTypeHint: nil)
        if (ambientAudioPlayer.isPlaying == true){
            ambientAudioPlayer.stop()
        }
    }
    
    @IBAction func resetTime(_ sender: AnyObject) {
        if(timerRunning == false) {
            timeLabel.text = "\(hours)h  :  \(mins)m  :  0s"
            totalSecs = 60 * 60 * hours + 60 * mins
            timerStarted = false
        }
    }
    
    func numberOfComponentsInPickerView(_ pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return pickerHours.count
        case 1:
            return pickerMinutes.count
        case 2:
            return bellSounds.count
        case 3:
            return ambientSounds.count
        default:
            return 1
        }
    }
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var pickerString: String
        let pickerLabel = UILabel()
        
        switch pickerView.tag {
        case 0:
            pickerString = String(pickerHours[row])
        case 1:
            pickerString = String(pickerMinutes[row])
        case 2:
            pickerString = bellSounds[row]
        case 3:
            pickerString = ambientSounds[row]
        default:
            pickerString = "Not found"
        }
        
        let myTitle = NSAttributedString(string: pickerString, attributes: [NSFontAttributeName:UIFont(name: "Helvetica", size: 20.0)!,NSForegroundColorAttributeName:UIColor.black])
        pickerLabel.attributedText = myTitle
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            timerChanged =  true
            hours = pickerHours[row]
            userDefaults.set(row, forKey: "userHours")
            if(timerRunning == false) {
                timeLabel.text = "\(hours)h  :  \(mins)m  :  0s"
            }
            setHoursMins()
        case 1:
            timerChanged = true
            mins = pickerMinutes[row]
            userDefaults.set(row, forKey: "userMins")
            if(timerRunning == false) {
                timeLabel.text = "\(hours)h  :  \(mins)m  :  0s"
            }
            setHoursMins()
        case 2:
            let soundString : String = bellSounds[row]
            let soundStringChar = String(soundString[soundString.index(soundString.startIndex, offsetBy: 0)])
            
            if(soundStringChar == "V"){
                vibrateOn = true
            } else {
                bellSound = URL(fileURLWithPath: Bundle.main.path(forResource: bellSounds[row], ofType: "wav")!)
                vibrateOn = false
            }
            
            userDefaults.set(row, forKey: "userBellSound")
            let sound : String = bellSounds[row]
            let numSounds = Int(String(sound[sound.index(sound.endIndex, offsetBy: -3)]))
            
            userDefaults.set(numSounds, forKey: "userNumBells")
            numBellSounds = numSounds!
        case 3:
            userDefaults.set(row, forKey: "userAmbientSound")
            if(ambientSounds[row] == "None"){
                ambientSoundOn = false
            } else {
                ambientSoundOn = true
                ambientSound = URL(fileURLWithPath: Bundle.main.path(forResource: ambientSounds[row], ofType: "wav")!)
            }
        default:
            print("error")
        }
        
        print("hours: \(hours), mins: \(mins), bell sound: \(bellSounds[userDefaults.integer(forKey: "userBellSound")]), ambient sound: \(ambientSounds[userDefaults.integer(forKey: "userAmbientSound")]), num of vibs: \(userDefaults.integer(forKey: "userNumBells")), vibrate on: \(vibrateOn)")
    }
    
    @IBAction func backButton(_ sender: AnyObject) {
        if(timerRunning == true){
            timer.invalidate()
            timer = nil
            stopAmbientPlayer()
            stopBellSoundPlayer()
        }
    }
    override var prefersStatusBarHidden : Bool {
        return true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
