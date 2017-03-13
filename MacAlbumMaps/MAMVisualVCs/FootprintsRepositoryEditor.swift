//
//  FootprintsRepositoryEditor.swift
//  MacAlbumMaps
//
//  Created by 张保国 on 2017/3/13.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

class FootprintsRepositoryEditor: NSViewController {
    
    var fr = FootprintsRepository()
    
    var frTitle: String{
        get{
            return fr.title
        }
        set{
            fr.title = newValue
            print(newValue)
        }
    }
    
    var frPlacemarkStatisticalInfo: String{
        get{
            return fr.placemarkStatisticalInfo
        }
        set{
            fr.placemarkStatisticalInfo = newValue
            print(newValue)
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        //fr.title
        //fr.footprintAnnotations
    }
    
}
