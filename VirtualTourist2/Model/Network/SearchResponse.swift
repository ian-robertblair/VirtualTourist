//
//  SearchResponse.swift
//  VirtualTourist
//
//  Created by ian robert blair on 2021/11/25.
//

import Foundation

struct FlickrPhoto:Codable {
    let id:String
    let owner:String
    let secret:String
    let server:String
    let farm:Int
    let title:String
    let ispublic:Int
    let isfriend:Int
    let isfamily:Int
}

struct PhotoObject:Codable {
    let page:Int
    let pages:Int
    let perpage:Int
    let total: Int
    let photo: [FlickrPhoto]
}

struct SearchResponse:Codable {
    let photos:PhotoObject
    let stat:String
}
