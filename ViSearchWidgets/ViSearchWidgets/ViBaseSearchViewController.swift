//
//  BaseSearchViewController.swift
//  ViSearchWidgets
//
//  Created by Hung on 10/11/16.
//  Copyright © 2016 Visenze. All rights reserved.
//

import UIKit
import ViSearchSDK

private let reuseIdentifier = "ViProductCardLayoutCell"

public protocol ViSearchViewControllerDelegate: class {
    
    /// configure the collectionview cell before displaying
    func configureCell(collectionView: UICollectionView, indexPath: IndexPath , cell: UICollectionViewCell)
    
    /// configure the layout if necessary
    func configureLayout(layout: UICollectionViewFlowLayout)
    
    /// product selection notification
    func didSelectProduct(collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct)
    
    /// action button tapped
    func actionBtnTapped(collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct)
    
    /// find similar button tapped
    func similarBtnTapped(collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct)
    
}

// make all method optional
public extension ViSearchViewControllerDelegate{
    func configureCell(collectionView: UICollectionView, indexPath: IndexPath , cell: UICollectionViewCell) {}
    func configureLayout(layout: UICollectionViewFlowLayout) {}
    func didSelectProduct(collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){}
    func actionBtnTapped(collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){}
    func similarBtnTapped(collectionView: UICollectionView, indexPath: IndexPath, product: ViProduct){}
}

// subclass implementation
public protocol ViSearchViewControllerProtocol: class {
    // configure the flow layout
    func reloadLayout() -> Void
    
    // call Visearch API and refresh data
    func refreshData() -> Void
}

open class ViBaseSearchViewController: UICollectionViewController , UICollectionViewDelegateFlowLayout, ViSearchViewControllerProtocol, ViProductCellDelegate {
    
    public weak var delegate: ViSearchViewControllerDelegate?
    
    /// last known successful request Id to Visenze API
    public var reqId : String? = ""
    
    /// search parameters
    public var searchParams: ViSearchParams? = nil
    
    /// schema mappings to UI elements
    public var schemaMapping: ViProductSchemaMapping = ViProductSchemaMapping()
    
    // MARK: UI settings
    /// UI settings
    public var imageConfig: ViImageConfig = ViImageConfig()
    public var headingConfig: ViLabelConfig = ViLabelConfig.default_heading_config
    public var labelConfig: ViLabelConfig = ViLabelConfig.default_label_config
    public var priceConfig: ViLabelConfig = ViLabelConfig.default_price_config
    public var discountPriceConfig: ViLabelConfig = ViLabelConfig.default_discount_price_config
    
    // buttons
    public var hasSimilarBtn: Bool = true
    public var similarBtnConfig: ViButtonConfig = ViButtonConfig.default_similar_btn_config
    
    public var hasActionBtn: Bool = true
    public var actionBtnConfig: ViButtonConfig = ViButtonConfig.default_action_btn_config
    
    public var productCardBackgroundColor: UIColor = ViTheme.sharedInstance.default_product_card_background_color
    
    // actual data
    public var products: [ViProduct] = [] {
        didSet {
            reloadLayout()
        }
    }
    
    /// product card size
    public var itemSize: CGSize = CGSize(width: 10, height: 10) {
        didSet {
            reloadLayout()
        }
    }
    
    /// spacing between items on same row
    public var itemSpacing  : CGFloat = 4.0 {
        didSet{
            reloadLayout()
        }
    }
    
    /// background color
    public var backgroundColor  : UIColor = UIColor.white
    
    /// MARK: init methods
    public init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Register cell classes
        self.collectionView!.register(ViProductCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        reloadLayout()
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UICollectionViewDataSource
    override open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ViProductCollectionViewCell
        
        let product = products[indexPath.row]
        if let url =  product.imageUrl {
            let productCardLayout = ViProductCardLayout(
                imgUrl: url, imageConfig: self.imageConfig,
                heading: product.heading, headingConfig: self.headingConfig ,
                label: product.label, labelConfig: self.labelConfig,
                price: product.price, priceConfig: self.priceConfig,
                discountPrice: product.discountPrice, discountPriceConfig: self.discountPriceConfig,
                hasSimilarBtn: self.hasSimilarBtn, similarBtnConfig: self.similarBtnConfig,
                hasActionBtn: self.hasActionBtn, actionBtnConfig: self.actionBtnConfig,
                pricesHorizontalSpacing: ViProductCardLayout.default_spacing, labelLeftPadding: ViProductCardLayout.default_spacing)
            
            let productView = productCardLayout.arrangement( origin: .zero ,
                                                             width:  itemSize.width ,
                                                             height: itemSize.height).makeViews(in: cell.contentView)
            
            productView.backgroundColor = self.productCardBackgroundColor
            cell.delegate = self
            
            if self.hasSimilarBtn {
                // wire up similar button action
                if let similarBtn = productView.viewWithTag(ViProductCardTag.findSimilarBtnTag.rawValue) as? UIButton {
                    // add event
                    similarBtn.addTarget(cell, action: #selector(ViProductCollectionViewCell.similarBtnTapped(sender:)), for: .touchUpInside)
                }
            }
            
            if self.hasActionBtn {
                // wire up similar button action
                if let actionBtn = productView.viewWithTag(ViProductCardTag.actionBtnTag.rawValue) as? UIButton {
                    // add event
                    actionBtn.addTarget(cell, action: #selector(ViProductCollectionViewCell.actionBtnTapped(sender:)), for: .touchUpInside)
                }
            }
            
        }
        
        if let delegate = delegate {
            delegate.configureCell(collectionView: collectionView, indexPath: indexPath, cell: cell)
        }
        
        return cell
    }
    
    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = delegate {
            let product = products[indexPath.row]
            delegate.didSelectProduct(collectionView: collectionView, indexPath: indexPath, product: product)
        }
    }
    
    // MARK : important methods
    
    /// estimate product card item size based on image size in image config
    /// override if necessary
    open func estimateItemSize() -> CGSize{
        
        let productCardLayout = ViProductCardLayout(
            imgUrl: nil, imageConfig: self.imageConfig,
            heading: self.schemaMapping.heading , headingConfig: self.headingConfig ,
            label: self.schemaMapping.label , labelConfig: self.labelConfig,
            price: (self.schemaMapping.price == nil ? nil : 0), priceConfig: self.priceConfig,
            discountPrice: (self.schemaMapping.discountPrice == nil ? nil : 0), discountPriceConfig: self.discountPriceConfig,
            hasSimilarBtn: self.hasSimilarBtn, similarBtnConfig: self.similarBtnConfig,
            hasActionBtn: self.hasActionBtn, actionBtnConfig: self.actionBtnConfig,
            pricesHorizontalSpacing: ViProductCardLayout.default_spacing, labelLeftPadding: ViProductCardLayout.default_spacing)
        
        return productCardLayout.arrangement(origin: .zero, width: self.imageConfig.size.width).frame.size
    }
    
    
    
    /// to be override by subclasses. Subclass must call delegate configureLayout to allow further customatization
    open func reloadLayout(){
        let layout = self.collectionViewLayout as! UICollectionViewFlowLayout
        
        layout.minimumInteritemSpacing = itemSpacing
        layout.headerReferenceSize = .zero
        layout.footerReferenceSize = .zero
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.collectionView?.backgroundColor = backgroundColor
        layout.itemSize = itemSize
    }
    
    /// to be implemented by subclasses
    open func refreshData(){}
    
    /// MARK: action buttons
    
    @IBAction open func similarBtnTapped(_ cell: ViProductCollectionViewCell) {
        if let indexPath = self.collectionView?.indexPath(for: cell) {
            let product = products[indexPath.row]
            delegate?.similarBtnTapped(collectionView: self.collectionView!, indexPath: indexPath, product: product)
            
        }
    }
    
    @IBAction open func actionBtnTapped(_ cell: ViProductCollectionViewCell) {
        if let indexPath = self.collectionView?.indexPath(for: cell) {
            let product = products[indexPath.row]
            delegate?.actionBtnTapped(collectionView: self.collectionView!, indexPath: indexPath, product: product)
        }
    }
    

}
