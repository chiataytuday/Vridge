//
//  ViewController.swift
//  Vridge
//
//  Created by Kang Mingu on 2020/10/02.
//

import UIKit

import Lottie

private let cellID = "cellID"
private let headerID = "headerID"

protocol HomeViewControllerDelgate: class {
    func updateUsers()
}

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegates: HomeViewControllerDelgate?
    
    private let vridgeLogo: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "imgVridgeLogo")
        return imgView
    }()
    
    private let vridgeText: UIButton = {
        let imgView = UIButton(type: .system)
        imgView.tintColor = UIColor(named: "home_vridgeTypo")
        imgView.setImage(UIImage(named: "vridgetext"), for: .normal)
//        imgView.isUserInteractionEnabled = false
        return imgView
    }()
        
    private lazy var rankButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "btnRank"), for: .normal)
        btn.addTarget(self, action: #selector(handleShowRanking), for: .touchUpInside)
        btn.tintColor = UIColor(named: normalButtonColor)
        return btn
    }()
    
    var numberOfPost = 0
    
    var posts = [Post]() {
        didSet { tableView.reloadData() }
    }
    
    var user: User? {
        didSet { print("DEBUG: user did set as \(user?.username)"); tableView.reloadData() }
    }
    
    var point: Int? {
        didSet { tableView.reloadData() }
    }
    
    var type: String? {
        didSet { tableView.reloadData() }
    }
    
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    lazy var indicator: UIActivityIndicatorView = {
        let ic = UIActivityIndicatorView()
        ic.color = .vridgeBlack
        ic.style = .large
        ic.center = view.center
        return ic
    }()
    
    let animationView: AnimationView = {
        let av = Lottie.AnimationView(name: loadingAnimation)
        av.loopMode = .loop
        return av
    }()
    
    var viewModel = ActionSheetViewModel()
    
    var page = 1
    
    
    // MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        animationView.play()
        
        let refreshControl: UIRefreshControl = {
            let rc = UIRefreshControl()
            let loadingView = Lottie.AnimationView(name: loadingAnimation)
            loadingView.play()
            loadingView.contentMode = .scaleAspectFit
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            loadingView.loopMode = .loop
            rc.addSubview(loadingView)
            loadingView.anchor(top: rc.topAnchor, paddingTop: 20, width: 120, height: 60)
            loadingView.centerX(inView: rc)
            rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
            rc.tintColor = .clear
            return rc
        }()
        
        tableView.refreshControl = refreshControl
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        fetchPosts()
        fetchPoint()
        fetchUserType()
        
        view.addSubview(animationView)
        animationView.center(inView: view)
        animationView.setDimensions(width: 100, height: 100)
        animationView.contentMode = .scaleAspectFill
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchAgain),
                                               name: Notification.Name("fetchAgain"), object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        numberOfPosts()
        
        super.viewWillAppear(true)
        NotificationCenter.default.post(name: Notification.Name("showPostButton"), object: nil)
    }
    
    
    // MARK: - API
    
    func fetchUserType() {
        UserService.shared.fetchUserType { type in
            self.type = type
        }
    }
    
    func fetchPoint() {
        UserService.shared.fetchUserPoint { point in
            self.point = point
        }
    }
    
    func numberOfPosts() {
        PostService.shared.numberOfPosts { nums in
            self.numberOfPost = nums
            print("DEBUG: number of posts ==== \(self.numberOfPost)")
        }
    }
    
    func fetchPosts() {
        PostService.shared.fetchPosts { posts in
            self.posts = posts.sorted(by: { $0.timestamp > $1.timestamp })
            self.indicator.stopAnimating()
            self.animationView.isHidden = true
            
            self.checkIfUserReportPost()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    func checkIfUserReportPost() {
        posts.forEach { post in
            PostService.shared.checkIfUserReportedPost(post) { didReport in
                guard didReport == true else { return }
                
                if let index = self.posts.firstIndex(where: { $0.postID == post.postID }) {
                    self.posts[index].isReported = true
                }
            }
        }
    }
    
    func loadMore(row: Int? = -1) {
        let from = posts.count
        let to = from + POST_LOAD_AT_ONCE >= numberOfPost ? numberOfPost : from + POST_LOAD_AT_ONCE
        
        PostService.shared.refetchPost(post: posts, from: from, upto: to) { posts in
            self.posts = posts.sorted(by: { $0.timestamp > $1.timestamp })
            
            self.checkIfUserReportPost()
            print("DEBUG: loaded more")
            if (self.page * 10) - (from - 1) == 1 && row == -1 {
                self.tableView.scrollToRow(at: IndexPath(item: from - 1, section: 0), at: .bottom, animated: true)
            }
        }
    }
    
    
    // MARK: - Selectors
    
    @objc func fetchAgain() {
        fetchPosts()
        fetchPoint()
        print("DEBUG: it worked!!")
    }
    
    @objc func handleRefresh() {
        print("DEBUG: Refresh feed")
        fetchPosts()
        fetchPoint()
    }
    
    @objc func handleShowRanking() {
        NotificationCenter.default.post(name: Notification.Name("hidePostButton"), object: nil)
        
        let controller = RankingViewController(user: user)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    // MARK: - Helpers
    
    func configureUI() {
        
        navigationItem.title = ""
        
        let logoImage = UIBarButtonItem(customView: vridgeLogo)
        let logoText = UIBarButtonItem(customView: vridgeText)
        navigationItem.leftBarButtonItems = [logoImage, logoText]
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rankButton)
        
        
        // navigation bar tint color set..
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor(named: viewBackgroundColor)?.withAlphaComponent(1.0)
        
        viewModel.delegate = self
        
        // hide navigationBar borderLine..
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        
        tableView.register(HomeFeedCell.self, forCellReuseIdentifier: cellID)
        
        view.addSubview(tableView)
        
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                         bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor)
        
    }
    
    func showReportAlert() {
        let alert = UIAlertController(title: noTitle, message: reportMessage, preferredStyle: .alert)
        let okButton = UIAlertAction(title: "확인", style: .default, handler: nil)
        alert.addAction(okButton)
        present(alert, animated: true, completion: nil)
    }
    
}


// MARK: - UITableViewDataSource

extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! HomeFeedCell
        
        cell.delegate = self
        cell.posts = posts[indexPath.row]
        cell.row = indexPath.row
        cell.selectionStyle = .none
        
        cell.reportedLabel.isHidden = !posts[indexPath.row].isReported
        cell.reportedView.alpha = posts[indexPath.row].isReported ? 0.9 : 0
        cell.captionLabel.isHidden = posts[indexPath.row].isReported
        cell.collectionView.isHidden = posts[indexPath.row].isReported
        cell.profileImageView.isHidden = posts[indexPath.row].isReported
        cell.reportButton.isHidden = posts[indexPath.row].isReported
        cell.username.isHidden = posts[indexPath.row].isReported
        cell.type.isHidden = posts[indexPath.row].isReported
        cell.time.isHidden = posts[indexPath.row].isReported
        
        
        // 컬렉션뷰를 stack view에 추가한 후, 스택뷰에 있는 모든 요소들을 hidden 시키면 어떻게 될까.
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if user == nil {
            let header = HomeHeaderView(frame: .zero, user: nil, point: user?.point ?? 0)
            header.backgroundColor = UIColor(named: "color_all_viewBackground")
            return header
        } else {
            let header = HomeHeaderView(frame: .zero, user: user, point: user!.point)
            header.backgroundColor = UIColor(named: "color_all_viewBackground")
            return header
        }
    }
    
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 137
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 600
//    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return tableView.estimatedRowHeight
//    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
//        let lastRowIndex = tableView.numberOfRows(inSection: 0) - 1
//        if  indexPath.row == lastRowIndex && (page * 10) - lastRowIndex == 1 {
//            print("DEBUG: last index row === \(lastRowIndex)")
//            let spinner = UIActivityIndicatorView(style: .large)
//            spinner.startAnimating()
//            spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(44))
//
//            tableView.tableFooterView = spinner
//            tableView.tableFooterView?.isHidden = false
//        }
        
        let lastElement = posts.count - 1
        if indexPath.row == lastElement {
            page += 1
            loadMore()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = FeedDetailViewController(post: posts[indexPath.row], index: indexPath.row)
        navigationController?.pushViewController(controller, animated: true)
        print("DEBUG: cell tapped ! ")
    }
    
}

extension HomeViewController: HomeFeedCellDelegate {
    
    func pleaseLogin() {
        let viewModel = ActionSheetViewModel()
        present(viewModel.pleaseLogin(self), animated: true, completion: nil)
    }
    
    func currentUserAmendTapped(sender: Post, row: Int) {
        present(viewModel.amendActionSheet(self, row: row, post: sender), animated: true)
    }
    
    func reportButtonTapped(sender: Post, row: Int) {
        present(viewModel.reportActionSheet(self, post: sender, row: row), animated: true, completion: nil)
    }
    
    func cellTapped() {
//        showFeedDetail()
    }
    
}

extension HomeViewController: ActionSheetViewModelDelegate {
    
    func updateUser() {
        delegates?.updateUsers()
        print("DEBUG: delegate passed to HOmeVIewCOntroller")
        self.tableView.reloadData()
    }
    
}
