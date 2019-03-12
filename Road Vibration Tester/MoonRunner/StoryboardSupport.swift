

import UIKit

protocol StoryboardIdentifiable {
  static var storyboardIdentifier: String { get }
}

extension StoryboardIdentifiable where Self: UIViewController {
  static var storyboardIdentifier: String {
    return String(describing: self)
  }
}

extension StoryboardIdentifiable where Self: UITableViewCell {
  static var storyboardIdentifier: String {
    return String(describing: self)
  }
}



extension UIViewController: StoryboardIdentifiable { }
extension UITableViewCell: StoryboardIdentifiable { }


extension UITableView {
  func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
    guard let cell = dequeueReusableCell(withIdentifier: T.storyboardIdentifier, for: indexPath) as? T else {
      fatalError("Could not find table view cell with identifier \(T.storyboardIdentifier)")
    }
    return cell
  }
  
  func cellForRow<T: UITableViewCell>(at indexPath: IndexPath) -> T {
    guard let cell = cellForRow(at: indexPath) as? T else {
      fatalError("Could not get cell as type \(T.self)")
    }
    return cell
  }
}



/// Use in view controllers:
///
/// 1) Have view controller conform to SegueHandlerType
/// 2) Add `enum SegueIdentifier: String { }` to conformance
/// 3) Manual segues are trigged by `performSegue(with:sender:)`
/// 4) `prepare(for:sender:)` does a `switch segueIdentifier(for: segue)` to select the appropriate segue case

protocol SegueHandlerType {
  associatedtype SegueIdentifier: RawRepresentable
}

extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
  
  func performSegue(withIdentifier identifier: SegueIdentifier, sender: Any?) {
    performSegue(withIdentifier: identifier.rawValue, sender: sender)
  }
  
  func segueIdentifier(for segue: UIStoryboardSegue) -> SegueIdentifier {
    guard
      let identifier = segue.identifier,
      let segueIdentifier = SegueIdentifier(rawValue: identifier)
      else {
        fatalError("Invalid segue identifier: \(String(describing: segue.identifier))")
    }
    
    return segueIdentifier
  }
  
}



