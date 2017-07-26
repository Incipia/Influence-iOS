//
//  SignupConductor.swift
//  Influence
//
//  Created by Gregory Klein on 7/22/17.
//  Copyright © 2017 Incipia. All rights reserved.
//

import Conduction
import IncNetworkLayer

class SignupConductor: Conductor {
   fileprivate lazy var _signupVC: SignupViewController = {
      let vc = SignupViewController()
      vc.title = "Sign Up"
      vc.tabBarItem = UITabBarItem(title: nil, image: #imageLiteral(resourceName: "user_icon"), selectedImage: #imageLiteral(resourceName: "user_icon_selected"))
      vc.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
      
      let item = UIBarButtonItem(image: #imageLiteral(resourceName: "right_arrow_icon"),
                                 style: .plain,
                                 target: self,
                                 action: #selector(SignupConductor._continueItemPressed))
      item.tintColor = UIColor(.outerSpace)
      vc.navigationItem.rightBarButtonItem = item
      
      let backItem = UIBarButtonItem(image: #imageLiteral(resourceName: "left_arrow_icon"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(Conductor.dismiss))
      backItem.tintColor = UIColor(.outerSpace)
      
      self._continueItem = item
      vc.navigationItem.leftBarButtonItem = backItem
      
      return vc
   }()
   
   fileprivate var _activityItem: UIBarButtonItem?
   fileprivate var _continueItem: UIBarButtonItem?
   
   override var rootViewController: UIViewController? {
      return _signupVC
   }
   
   override func conductorWillShow(in context: UINavigationController) {
      context.navigationBar.configureWithInfluenceDefaults()
      
      let conductionModel = SignupConductionModel()
      conductionModel.delegate = self
      conductionModel.addStateObserver { old, new in
         self._continueItem?.isEnabled = new.isContinueButtonEnabled
         if new.isShowingActivityIndicator {
            self._activityItem = self._signupVC.navigationItem.addRightActivityItem(tintColor: UIColor(.outerSpace))
         } else {
            self._signupVC.navigationItem.removeRightActivityItem(self._activityItem)
         }
      }
      
      _signupVC.model = conductionModel
   }
   
   @objc private func _continueItemPressed() {
      _signupVC.model?.continueButtonPressed()
   }
}

extension SignupConductor: SignupConductionModelDelegate {
   func continueButtonPressed(model: SignupConductionModel) {
      _signupVC.view.endEditing(true)
      var apiInput = APIAccount.Signup()
      try! model.sync(model: &apiInput)
      
      let request = SignupRequest(parameter: apiInput)
      let signupOp = SignupOperation(request: request)
      signupOp.completion = { result in
         switch result {
         case .success(let account): dump(account)
         case .error(let error): print("Error signing up: \(error.localizedDescription)")
         }
         model.signupOperationFinished()
      }
      
      model.signupOperationStarted()
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
         IncNetworkQueue.shared.addOperation(signupOp)
      }
   }
}

extension UINavigationItem {
   func addRightActivityItem(tintColor: UIColor = .gray) -> UIBarButtonItem {
      let activityView = UIActivityIndicatorView()
      activityView.color = tintColor
      activityView.startAnimating()
      
      let item = UIBarButtonItem(customView: activityView)
      rightBarButtonItems?.append(item)
      return item
   }
   
   func removeRightActivityItem(_ item: UIBarButtonItem?) {
      guard let item = item else { return }
      guard let index = rightBarButtonItems?.index(of: item) else { return }
      rightBarButtonItems?.remove(at: index)
   }
}
