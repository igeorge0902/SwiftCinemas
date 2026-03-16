//
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 18/11/15.
//

import Foundation

extension URLSession {
    /// Just like sharedSession, this returns a shared singleton session object.
    class var sharedCustomSession: URLSession {
        // The session is stored in a nested struct because you can't do a 'static let' singleton in a class extension.
        enum Instance {
            /// The singleton URL session, configured to use our custom config and delegate.
            static let session = URLSession(
                configuration: URLSessionConfiguration.CustomSessionConfiguration(),
                delegate: CustomURLSessionDelegate(),
                delegateQueue: OperationQueue.main
            )
        }
        return Instance.session
    }
}
