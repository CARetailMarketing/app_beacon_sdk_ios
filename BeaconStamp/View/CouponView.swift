//
//  CouponView.swift
//  BeaconStamp
//
//  Created by 近藤 寛志 on 2019/03/27.
//  Copyright © 2019 iret,Inc. All rights reserved.
//

import Foundation

class CouponView: UIView {
    
    private var externalLink: URL?
    
    override init(frame: CGRect){
        super.init(frame: frame)
        loadNib()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
    }
    
    func loadNib() {
        let bundle = Bundle(for: CouponView.self)
        let nib = UINib(nibName: "CouponView", bundle: bundle)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
        
        if let closeButton = view.viewWithTag(20) as? UIButton {
            let image = UIImage.init(named: "close_circle", in: bundle, compatibleWith: nil)
            closeButton.setImage(image, for: .normal)
        }
    }
    
    func show(view: UIView, couponInfo: CouponInfo, closeOld: Bool, token: String) {
        if closeOld {
            view.subviews.forEach { (subView) in
                if let couponView = subView as? CouponView {
                    // アニメーションせずにすぐに消す
                    couponView.removeFromSuperview()
                }
            }
        }
        
        if let url = URL(string: couponInfo.creative.coupon) {
            externalLink = url
            viewWithTag(30)?.isHidden = false
        }

        guard let couponImage = viewWithTag(10) as? UIImageView else {
            return
        }
        if let url = URL(string: couponInfo.creative.image), !isShowingCouponView(view: view) {
            let urlRequest = URLRequest(url: url,
                                        cachePolicy: .reloadIgnoringLocalCacheData,
                                        timeoutInterval: 10)
            couponImage.setImageWith(urlRequest,
                                     placeholderImage: nil,
                                     success: { (_, _, image) in
                                        // 画像のダウンロード完了し、クーポンが表示されていないときのみ表示する
                                        if self.isShowingCouponView(view: view) {
                                            return
                                        }
                                        couponImage.image = image
                                        view.addSubview(self)
                                        self.alpha = 0
                                        
                                        UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                                            self.alpha = 1
                                        }, completion: nil)
            }, failure: nil)
        }
    }
    
    func isShowingCouponView(view: UIView) -> Bool {
        return view.subviews.filter{ $0 is CouponView }.count > 0
    }
    
    @IBAction func openBrowser(_ sender: Any) {
        guard let externalLink = externalLink else {
            return
        }
        UIApplication.shared.openURL(externalLink)
    }

    @IBAction func onClose(view: UIView) {
        closeView()
    }
    
    private func closeView() {
        UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.alpha = 0
        }) { (_) in
            self.removeFromSuperview()
        }
    }
}
