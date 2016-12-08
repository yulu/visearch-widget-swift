//
//  YouMayLikeViewController.swift
//  WidgetsExample
//
//  Created by Hung on 11/11/16.
//  Copyright © 2016 Visenze. All rights reserved.
//

import UIKit
import ViSearchSDK
import ViSearchWidgets

class YouMayLikeViewController: UIViewController, ViSearchViewControllerDelegate {

    public var im_name : String?
    var controller: ViRecommendationViewController? = nil
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
       super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedRecSegue" {
            
            if let im_name = self.im_name {
                if let controller = segue.destination as? ViRecommendationViewController {
                    self.controller = controller
                    controller.delegate = self
                    
                    let containerWidth = self.view.bounds.width
                    
                    // this will let 2.5 images appear on screen
                    let imageWidth = controller.estimateItemWidth(2.5, containerWidth: containerWidth)
                    let imageHeight = min(imageWidth * 1.2, 140 )
                    
                    // configure product image size
                    controller.imageConfig.size = CGSize(width: imageWidth, height: imageHeight )
                    controller.imageConfig.contentMode = .scaleAspectFill
                    
                    // configure search parameter
                    
                    controller.searchParams = ViSearchParams(imName: im_name)
                    controller.searchParams?.limit = 16
                    
                    // to retrieve more meta data , configure the below
        //            controller.searchParams?.fl = ["category"]
                    
                    // configure schema mapping to product UI elements
                    
    //                controller.schemaMapping.heading = "im_title"
    //                controller.schemaMapping.label = "brand"
    //                controller.schemaMapping.price = "price"
                    
                    controller.schemaMapping = AppDelegate.loadSampleSchemaMappingFromPlist()

                    // configure discount price if necessary
                    controller.schemaMapping.discountPrice = "price"
                    controller.priceConfig.isStrikeThrough = true
                    
        //            controller.backgroundColor = UIColor.black
                    controller.paddingLeft = 8.0
                    
                    // IMPORTANT: this must be called last after schema mapping as we calculate the item size based on whether a field is available
                    // e.g. if label is nil in the mapping, then it will not be included in the height calculation of product card
                    controller.itemSize = controller.estimateItemSize()
                    
                    containerHeightConstraint.constant = controller.itemSize.height + 70
                    
                    controller.refreshData()
                }
            }
            else {
                alert(message: "Please set up im_name in SampleData.plist")
            }
            
        }
        
    }
    
    // MARK: ViSearchViewControllerDelegate
    func didSelectProduct(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct) {
        alert(message: "select product with im_name: \(product.im_name)" )
    }
    
    func actionBtnTapped(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){
        alert(message: "action button tapped , product im_name: \(product.im_name)" )
    }
    
    func similarBtnTapped(sender: AnyObject, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){
        print("similar button tapped , product im_name: \(product.im_name)")
        
    }

    func willShowSimilarController(sender: AnyObject, controller: ViFindSimilarViewController, collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){
        
        // only do this from current controller
        if sender is ViRecommendationViewController {
            controller.itemSpacing = 0
            controller.rowSpacing = 0
            controller.setItemWidth(numOfColumns: 2, containerWidth: self.view.bounds.width)
            controller.productCardBorderWidth = 0.7
            controller.productCardBorderColor = UIColor.lightGray

            controller.filterItems = AppDelegate.loadFilterItemsFromPlist()
        }
        
    }
    
    func searchFailed(sender: AnyObject, searchType: ViSearchType , err: Error?, apiErrors: [String]) {
        if err != nil {
            // network error.. display custom error if necessary
            //alert (message: "error: \(err.localizedDescription)")
        }
            
        else if apiErrors.count > 0 {
            // network error.. display custom error if necessary
            //alert (message: "api error: \(apiErrors.joined(separator: ",") )")
        }
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    
        coordinator.animate(alongsideTransition: { context in
            if let controller = self.controller {
                let curSize = controller.imageConfig.size
                controller.imageConfig.size = CGSize(width: curSize.width, height: min(curSize.height , 150) )
                controller.itemSize = controller.estimateItemSize()
                self.containerHeightConstraint.constant = controller.itemSize.height + 70
            }
            
        }, completion: { context in
            
            // after rotate
            
        })

        
        
    }

}
