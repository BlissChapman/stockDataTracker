//
//  ViewController.swift
//  veryEarlyRetirement
//
//  Created by Bliss Chapman on 1/24/15.
//  Copyright (c) 2015 Bliss Chapman. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var timer = NSTimer()
    var counter: Int = 0
    
    var dataString: NSString?
    var data: NSData?
    var newString: String?
    
    //var day = NSDateFormatter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("RUNNING")
        if NSUserDefaults.standardUserDefaults().boolForKey("kAlreadyBeenLaunched") == false {
            NSUserDefaults.standardUserDefaults().setObject(0, forKey: "counter")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        counter = NSUserDefaults.standardUserDefaults().objectForKey("counter") as Int
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: "findStockInfo", userInfo: nil, repeats: true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processData", name: "DataReady", object: nil)
    }
    
    func findStockInfo() {
        var stocks = ["SPY"]
        var symbols = "(";
        for quoteTuple in stocks {
            symbols = symbols+"\""+quoteTuple.0+"\","
        }
        symbols = symbols.substringToIndex(symbols.endIndex.predecessor())
        symbols = symbols + ")"
        
        
        //http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20IN%20(%22AAPL%22,%22FB%22,%22GOOG%22)&format=json&env=http://datatables.org/alltables.env
        //var urlString:String = ("http://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quotes where symbol IN "+symbols+"&format=json&env=http://datatables.org/alltables.env").stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        //var urlString = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20IN%20(%22SPY%22)&format=json&env=http://datatables.org/alltables.env"
        
        
        var urlString = "http://finance.google.com/finance/info?client=ig&q=NASDAQ:SPY"
        var url: NSURL = NSURL(string: urlString)!
        
        var request: NSURLRequest = NSURLRequest(URL:url)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: {myData, response, error -> Void in
            self.data = myData
            self.dataString = NSString(data: self.data!, encoding: NSUTF8StringEncoding)!
            if error != nil {
                println("ERROR: \(error.localizedDescription)")
            }
            else {
                var err: NSError?
                NSNotificationCenter.defaultCenter().postNotificationName("DataReady", object: nil)
            }
        })
        task.resume()
    }
    
    func processData() {
        var dataString: NSString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
        var modifiedString = dataString.stringByReplacingOccurrencesOfString("// ", withString: "")
        modifiedString = modifiedString.stringByReplacingOccurrencesOfString("[", withString: "")
        modifiedString = modifiedString.stringByReplacingOccurrencesOfString("{", withString: "")
        modifiedString = modifiedString.stringByReplacingOccurrencesOfString("}", withString: "")
        modifiedString = modifiedString.stringByReplacingOccurrencesOfString("]", withString: "")
        modifiedString = modifiedString.stringByReplacingOccurrencesOfString("\n", withString: "")
        modifiedString = modifiedString.stringByReplacingOccurrencesOfString(":", withString: "")
        modifiedString = modifiedString.stringByReplacingOccurrencesOfString("\"", withString: "")
        modifiedString = modifiedString.stringByReplacingOccurrencesOfString("  ", withString: " ")
        
        var array = modifiedString.componentsSeparatedByString(",")
        //println(array)
        var stockPriceDictionary = [String: String]()
        for value in array {
            var twoStrings = value.componentsSeparatedByString(" ")
            //println(twoStrings)
            var keyString: String? = twoStrings[0]
            //println(keyString)
            var valueString: String = twoStrings[1]
            //println(valueString)
            if keyString == nil {
                println("key is nil")
                keyString = "time"
            }
            stockPriceDictionary[keyString!] = valueString
        }
        
        writeToTxtFile("\(modifiedString)\n\n")
    }
    
    func writeToTxtFile(stringToWrite: String) {
        counter++
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "counter")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        let stringData = stringToWrite.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        let documentDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        let fileDestinationUrl = documentDirectoryURL.URLByAppendingPathComponent("EarlyRetirement-SPYData.txt")
        var stringFromFile = String(contentsOfURL: fileDestinationUrl, encoding: NSUTF8StringEncoding, error: nil)
        
        if NSFileManager.defaultManager().fileExistsAtPath(fileDestinationUrl.path!) {
            var err: NSError?
            if let fileHandle = NSFileHandle(forWritingToURL: fileDestinationUrl, error: &err) {
                fileHandle.seekToFileOffset(fileHandle.seekToEndOfFile())
                fileHandle.writeData(stringData)
                fileHandle.closeFile()
                println("\(counter) price points recorded")
            }
            else {
                println("Can't open fileHandle \(err)")
            }
        }
    }
}


//        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String]
//        if dirs != nil {
//            let dir = dirs![0]
//            let dirURL = NSURL(fileURLWithPath: dir)
//            let myPath = dirURL?.URLByAppendingPathComponent("EarlyRetirement-SPYData.txt")
//
//            var errr3: NSError?
//            //stringToWrite.writeToURL(myPath!, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
//            println("check1")
//        }

    //    func checkMarketAvailability() {
    //        //NOTE: This information is hardcoded as the schedule of the NYSE stock exchange.
    //        var now = NSDate()
    //        var weekday = NSDateFormatter()
    //        weekday.setLocalizedDateFormatFromTemplate("EEEE")
    //        var dayOfWeek = weekday.stringFromDate(now)
    //        switch dayOfWeek {
    //        case "Monday":
    //            println("MONDAY")
    //            checkTimeAvailability()
    //        case "Tuesday":
    //            println("TUESDAY")
    //            checkTimeAvailability()
    //        case "Wednesday":
    //            println("WEDNESDAY")
    //            checkTimeAvailability()
    //        case "Thursday":
    //            println("THURSDAY")
    //            checkTimeAvailability()
    //        case "Friday":
    //            println("FRIDAY")
    //            checkTimeAvailability()
    //        case "Saturday":
    //            println("SATURDAY - market closed")
    //            return
    //        case "Sunday":
    //            println("SUNDAY - market closed")
    //            return
    //        default:
    //            println("ERROR - DAY NOT FOUND")
    //            return
    //        }
    //    }
    
    //    func checkTimeAvailability() {
    //        var now = NSDate()
    //        var timeString = now.description
    //        var hoursMinutesSeconds = timeString.componentsSeparatedByString(" ")[1]
    //        var hours = hoursMinutesSeconds.componentsSeparatedByString(":")
    //        var minutes = hoursMinutesSeconds.componentsSeparatedByString(":")[1]
    //        //23 = 5
    //        println(hours[0])
    //        if hours[0].toInt() >= 21 { //3 pm our time
    //            println("market closed - too late in day")
    //            return
    //        } else if hours[0].toInt() <= 16 { //10 am
    //            if minutes.toInt() <= 30 {
    //                println("market closed - too early in day")
    //                return
    //            }
    //        }
    //        findStockInfo()
    //    }

