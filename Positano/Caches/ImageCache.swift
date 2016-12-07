//
//  ImageCache.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import PositanoKit
import PositanoNetworking
import MapKit
import Kingfisher

final class YepImageCache {

    static let sharedInstance = YepImageCache()

    let cache = NSCache<NSString, UIImage>()
    let cacheQueue = DispatchQueue(label: "ImageCacheQueue", attributes: [])
    let cacheAttachmentQueue = DispatchQueue(label: "ImageCacheAttachmentQueue", attributes: [])

    class func attachmentOriginKeyWithURLString(_ URLString: String) -> String {
        return "attachment-0.0-\(URLString)"
    }

    class func attachmentSideLengthKeyWithURLString(_ URLString: String, sideLength: CGFloat) -> String {
        return "attachment-\(sideLength)-\(URLString)"
    }

    func imageOfURL(_ url: URL, withMinSideLength: CGFloat?, completion: @escaping (_ url: URL, _ image: UIImage?, _ cacheType: CacheType) -> Void) {

        var sideLength: CGFloat = 0

        if let withMinSideLength = withMinSideLength {
            sideLength = withMinSideLength
        }

        let attachmentOriginKey = YepImageCache.attachmentOriginKeyWithURLString(url.absoluteString)

        let attachmentSideLengthKey = YepImageCache.attachmentSideLengthKeyWithURLString(url.absoluteString, sideLength: sideLength)

        //println("attachmentSideLengthKey: \(attachmentSideLengthKey)")

        let options: KingfisherOptionsInfo = [
            .callbackDispatchQueue(cacheAttachmentQueue),
            .scaleFactor(UIScreen.main.scale),
        ]

        //查找当前 Size 的 Cache

        ImageCache.default.retrieveImage(forKey: attachmentSideLengthKey, options: options) { (image, type) -> () in

            if let image = image?.decodedImage() {
                SafeDispatch.async {
                    completion(url, image, type)
                }

            } else {

                //查找原图

                ImageCache.default.retrieveImage(forKey: attachmentOriginKey, options: options) { (image, type) -> () in

                    if let image = image {

                        //裁剪并存储
                        var finalImage = image

                        if sideLength != 0 {
                            finalImage = finalImage.scaleToMinSideLength(sideLength)

                            let originalData = UIImageJPEGRepresentation(finalImage, 1.0)
                            //let originalData = UIImagePNGRepresentation(finalImage)
                            ImageCache.default.store(finalImage, original: originalData, forKey: attachmentSideLengthKey, toDisk: true, completionHandler: { () -> () in
                            })
                        }

                        SafeDispatch.async {
                            completion(url, finalImage, type)
                        }

                    } else {

                        // 下载

                        ImageDownloader.default.downloadImage(with: url, options: options, progressBlock: { receivedSize, totalSize  in

                        }, completionHandler: { image, error, imageURL, originalData in

                            if let image = image {

                                ImageCache.default.store(image, original: originalData, forKey: attachmentOriginKey, toDisk: true, completionHandler: nil)

                                var storeImage = image

                                if sideLength != 0 {
                                    storeImage = storeImage.scaleToMinSideLength(sideLength)
                                }

                                ImageCache.default.store(storeImage,  original: UIImageJPEGRepresentation(storeImage, 1.0), forKey: attachmentSideLengthKey, toDisk: true, completionHandler: nil)

                                let finalImage = storeImage.decodedImage()

                                //println("Image Decode size \(storeImage.size)")

                                SafeDispatch.async {
                                    completion(url, finalImage, .none)
                                }

                            } else {
                                SafeDispatch.async {
                                    completion(url, nil, .none)
                                }
                            }
                        })
                    }
                }
            }
        }
    }


}

