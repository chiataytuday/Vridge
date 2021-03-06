//
//  TabBarController.swift
//  Vridge
//
//  Created by Kang Mingu on 2020/10/02.
//

import UIKit

import Firebase

class MainTabBarController: UITabBarController {
    
    // MARK: - Properties
    
    var user: User? {
        didSet {
            guard let nav = viewControllers?[0] as? UINavigationController else { return }
            guard let home = nav.viewControllers.first as? HomeViewController else { return }
            
            guard let nav2 = viewControllers?[2] as? UINavigationController else { return }
            guard let myPage = nav2.viewControllers.first as? MyPageViewController else { return }
            
            home.delegates = self
            home.user = user
            myPage.user = user
//            if user?.type == "" { isVerified = false }
        }
    }
    
//    var isVerified: Bool?
    
    private let postButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setBackgroundImage(UIImage(named: "icPost"), for: .normal)
        btn.backgroundColor = .vridgeGreen
        btn.addTarget(self, action: #selector(handleButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = UIColor.white.withAlphaComponent(1)
        
        configure()
        //        fetchUser()
        authenticateAndConfigureUI()
    }
    
    
    // MARK: - API
    
    func fetchUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        UserService.shared.fetchUser(uid: uid) { user in
            self.user = user
            print("DEBUG: user update!")
            print("DEBUG: current point -== \(user.point)")
        }
    }
    
    func authenticateAndConfigureUI() {
        if Auth.auth().currentUser == nil {
            DispatchQueue.main.async {
                let controller = LoginViewController()
                let nav = UINavigationController(rootViewController: controller)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        } else {
            fetchUser()
        }
    }
    
    
    
    // MARK: - Selectors
    
    @objc func handleButtonTapped() {
        
        let actionSheetViewModel = ActionSheetViewModel()
        
        if Auth.auth().currentUser == nil {
            present(actionSheetViewModel.pleaseLogin(self), animated: true)
        } else {
        
            let controller = PostingViewController(config: .post)
            controller.delegate = self
            let nav = UINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
        
//        let controller = LoginViewController()
//        controller.delegate = self
//        let nav = UINavigationController(rootViewController: controller)
//        nav.modalPresentationStyle = .fullScreen
        
//        let controller = TestViewController()
//        let nav = UINavigationController(rootViewController: controller)
        
        present(nav, animated: true, completion: nil)
                }
    }
    
    @objc func hidePostButton() {
        postButton.isHidden = true
    }
    
    @objc func showPostButton() {
        postButton.isHidden = false
    }
    
    
    // MARK: - Helpers
    
    func configure() {
        
        view.addSubview(postButton)
        
        postButton.centerX(inView: view)
        postButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 0)
        postButton.widthAnchor.constraint(equalToConstant: 64).isActive = true
        postButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
        postButton.layer.cornerRadius = 64 / 2
        
        NotificationCenter.default.addObserver(self, selector: #selector(hidePostButton), name: Notification.Name("hidePostButton"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showPostButton), name: Notification.Name("showPostButton"), object: nil)
    }
    
}

extension MainTabBarController :LoginViewControllerDelegate {
    
    func userLogout() {
        print("DEBUG: handle log out man")
        do {
            try Auth.auth().signOut()
            dismiss(animated: true) {
                self.user = nil
                let nav = UINavigationController(rootViewController: LoginViewController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        } catch (let err) {
            print("DEBUG: FAILED LOG OUT with error \(err.localizedDescription)")
        }
    }
    
}

extension MainTabBarController: HomeViewControllerDelgate {
    
    func updateUsers() {
        fetchUser()
        print("DEBUG: delegates passed to main")
    }
    
}

extension MainTabBarController: PostingViewControllerDelegate {
    
    func fetchUserAgain() {
        fetchUser()
    }
    
}



