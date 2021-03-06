//
//  LoginConductor.swift
//  Influence
//
//  Created by Gregory Klein on 7/22/17.
//  Copyright © 2017 Incipia. All rights reserved.
//

import Conduction
import IncNetworkLayer

class SigninConductor: Conductor {
   fileprivate lazy var _signinVC: SigninViewController = {
      let vc = SigninViewController()
      vc.title = "Log In"
      vc.tabBarItem = UITabBarItem(title: nil, image: #imageLiteral(resourceName: "user_icon"), selectedImage: #imageLiteral(resourceName: "user_icon_selected"))
      vc.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
      
      let rightItem = UIBarButtonItem(image: #imageLiteral(resourceName: "right_arrow_icon"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(SigninConductor._signinItemPressed))
      rightItem.tintColor = UIColor(.outerSpace)
      vc.navigationItem.rightBarButtonItem = rightItem
      self._continueItem = rightItem
      
      let leftItem = UIBarButtonItem(image: #imageLiteral(resourceName: "left_arrow_icon"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(Conductor.dismiss))
      leftItem.tintColor = UIColor(.outerSpace)
      vc.navigationItem.leftBarButtonItem = leftItem
      return vc
   }()
   
   fileprivate var _continueItem: UIBarButtonItem?
   fileprivate var _activityItem: UIBarButtonItem?
   fileprivate let _profileConductor = ProfileConductor()
   
   override var rootViewController: UIViewController? {
      return _signinVC
   }
   
   override func conductorWillShow(in context: UINavigationController) {
      context.navigationBar.configureWithInfluenceDefaults()
      
      let conductionModel = SigninConductionModel()
      conductionModel.delegate = self
      conductionModel.addStateObserver { old, new in
         self._continueItem?.isEnabled = new.isContinueButtonEnabled
         if new.isShowingActivityIndicator {
            self._activityItem = self._signinVC.navigationItem.addRightActivityItem(tintColor: UIColor(.outerSpace))
         } else {
            self._signinVC.navigationItem.removeRightActivityItem(self._activityItem)
         }
      }
      
      conductionModel[.username] = "gkl3i8"
      conductionModel[.password] = "a"
      _signinVC.model = conductionModel
   }
   
   @objc private func _signinItemPressed() {
      _signinVC.model?.continueButtonPressed()
   }
}

extension SigninConductor: SigninConductionModelDelegate {
   func continueButtonPressed(model: SigninConductionModel) {
      var apiInput = APIAccount.Signin()
      try! model.sync(model: &apiInput)
      
      let request = SigninRequest(parameter: apiInput)
      let signinOp = SigninOperation(request: request)
      signinOp.completion = { result in
         switch result {
         case .success(let account):
            guard let context = self.context else { fatalError() }
            DispatchQueue.main.async {
               self._profileConductor.show(with: context, animated: true)
            }
         case .error(let error): print("Error signing in: \(error.localizedDescription)")
         }
         model.signupOperationFinished()
      }
      
      model.signupOperationStarted()
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
         IncNetworkQueue.shared.addOperation(signinOp)
      }
   }
}
