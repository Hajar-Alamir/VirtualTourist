//
//  flickrPhotos.swift
//  VirtualTourist
//
//  Created by Hajar F on 12/4/19.
//  Copyright © 2019 Hajar F. All rights reserved.
//

struct Constants {
    static let key = "2ac76dbc3aa3f406f2ff5eeabaf37b29"
    
    static let flickrPhotos = "https://api.flickr.com/services/rest?method=flickr.photos.search&format=json&api_key=\(Constants.key)&bbox={bbox}&per_page=21&page={page}&extras=url_m&nojsoncallback=1"

}
