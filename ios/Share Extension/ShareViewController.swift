import receive_sharing_intent

class ShareViewController: RSIShareViewController {
    // Use this method to return false if you don't want to redirect to host app automatically.
    override func shouldAutoRedirect() -> Bool {
        return false
    }
}
