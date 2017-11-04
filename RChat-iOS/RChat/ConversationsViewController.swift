//
//  ConversationsViewController.swift
//  RChat
//
//  Created by Max Alexander on 1/9/17.
//  Copyright © 2017 Max Alexander. All rights reserved.
//

import UIKit
import SideMenu
import RealmSwift
import Cartography


protocol ConversationsViewControllerDelegate: class {
    func changeConversation(conversation: Conversation)
    func goToProfile()
}

class ConversationsViewController : UISideMenuNavigationController,
    UITableViewDataSource,
    UITableViewDelegate,
    ComposeViewControllerDelegate,
    ConversationSearchViewDelegate,
    SearchResultsViewControllerDelegate
{

    weak var conversationsViewControllerDelegate: ConversationsViewControllerDelegate?

    lazy var tableView : UITableView = {
        let t = UITableView()
        t.backgroundColor = RChatConstants.Colors.midnightBlue
        t.translatesAutoresizingMaskIntoConstraints = false
        t.separatorColor = .clear
        t.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.REUSE_ID)
        t.rowHeight = ConversationTableViewCell.HEIGHT
        t.contentInset = UIEdgeInsetsMake(0, 0, 200, 0)
        return t
    }()

    lazy var searchView : ConversationSearchView = {
        let c = ConversationSearchView()
        c.translatesAutoresizingMaskIntoConstraints = false
        return c
    }()

    lazy var penButton : UIButton = {
        let b = UIButton()
        b.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4)
        b.imageView?.contentMode = .scaleAspectFit
        b.layer.cornerRadius = 44 / 2
        b.layer.masksToBounds = true
        b.tintColor = .white
        b.setImage(RChatConstants.Images.penIcon, for: .normal)
        b.backgroundColor = RChatConstants.Colors.primaryColor
        return b
    }()

    lazy var searchResultsController : SearchResultsViewController = {
        let s = SearchResultsViewController()
        s.view.alpha = 0
        return s
    }()

    var conversations : Results<Conversation>!
    var notificationToken : NotificationToken?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = RChatConstants.Colors.primaryColorDark
        view.addSubview(tableView)

        addChildViewController(searchResultsController)
        view.addSubview(searchResultsController.view)
        view.addSubview(searchView)
        view.addSubview(penButton)

        penButton.addTarget(self, action: #selector(ConversationsViewController.penButtonDidTap(button:)), for: .touchUpInside)
        searchView.iconButton.addTarget(self, action: #selector(ConversationsViewController.profileIconButtonDidTap(button:)), for: .touchUpInside)

        tableView.dataSource = self
        tableView.delegate = self

        searchView.delegate = self

        searchResultsController.delegate = self

        constrain(searchView, tableView, penButton, searchResultsController.view) { (searchView, tableView, penButton, searchResultsView) in
            searchView.left == searchView.superview!.left
            searchView.right == searchView.superview!.right
            searchView.height == 65
            searchView.top == searchView.superview!.top

            tableView.top == searchView.bottom
            tableView.left == tableView.superview!.left
            tableView.right == tableView.superview!.right
            tableView.bottom == tableView.superview!.bottom

            searchResultsView.top == searchResultsView.superview!.top
            searchResultsView.bottom == tableView.bottom
            searchResultsView.left == tableView.left
            searchResultsView.right == tableView.right

            penButton.width == 44
            penButton.height == 44
            penButton.right == penButton.superview!.right - RChatConstants.Numbers.horizontalSpacing
            penButton.bottom == penButton.superview!.bottom - RChatConstants.Numbers.verticalSpacing
        }

        let realm = RChatConstants.Realms.global
        let predicate = NSPredicate(format: "ANY users.userId = %@", RChatConstants.myUserId)
        conversations = realm.objects(Conversation.self).filter(predicate)

        notificationToken = conversations
            .observe { [weak self] (changes) in
                guard let `self` = self else { return }
                switch changes {
                case .initial:
                    print(self.conversations.count)
                    self.tableView.reloadData()
                    break
                case .update(_, let deletions, let insertions, let modifications):
                    // Query results have changed, so apply them to the UITableView
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                         with: .automatic)
                    self.tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                         with: .automatic)
                    self.tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                         with: .automatic)
                    self.tableView.endUpdates()
                    break
                case .error(let error):
                    fatalError(error.localizedDescription)
                    break
                }
            }

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    func penButtonDidTap(button: UIButton){
        let composeViewController = ComposeViewController()
        composeViewController.delegate = self
        let controller = CustomNavController(rootViewController: composeViewController)
        present(controller, animated: true, completion: nil)
    }

    func profileIconButtonDidTap(button: UIButton) {
        dismiss(animated: true, completion: nil)
        conversationsViewControllerDelegate?.goToProfile()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.REUSE_ID, for: indexPath) as! ConversationTableViewCell
        let conversation = conversations[indexPath.row]
        cell.setupWithConversation(conversation: conversation)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        conversationsViewControllerDelegate?.changeConversation(conversation: conversation)
        dismiss(animated: true, completion: nil)
    }

    func selectedSearchedConversation(conversation: Conversation) {
        searchView.searchTextField.text = ""
        conversationsViewControllerDelegate?.changeConversation(conversation: conversation)
        dismiss(animated: true, completion: nil)
    }

    func composeWithUsers(users: [User]) {
        let conversation = Conversation.putConversation(users: users)
        conversationsViewControllerDelegate?.changeConversation(conversation: conversation)
        dismiss(animated: true, completion: nil)
    }

    func fireChatSearch(searchTerm: String) {
        let selector = #selector(SearchResultsViewController.searchConversationsAndUsers(searchTerm:))
        NSObject.cancelPreviousPerformRequests(withTarget: searchResultsController, selector: selector, object: nil)
        searchResultsController.perform(selector, with: searchTerm, afterDelay: 0.5)
    }

    func searchStateChanged(isFirstResponder: Bool) {
        UIView.animate(withDuration: 0.25) { 
            self.searchResultsController.view.alpha = isFirstResponder ? 1 : 0
        }
    }

    deinit {
        notificationToken?.invalidate()
    }
}
