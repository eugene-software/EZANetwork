# EZANetwork
[![Version](https://img.shields.io/cocoapods/v/EZANetwork.svg?style=flat-square)](https://cocoapods.org/pods/EZANetwork)
[![License](https://img.shields.io/cocoapods/l/EZANetwork.svg?style=flat-square)](https://cocoapods.org/pods/EZANetwork)

## Requirements 

- iOS 13 and above

## Usage Example

Import dependenices:

```swift
import Combine
import EZANetwork
```

- Inherit EZARequest protocol and define required fields:

```swift

enum NetworkApi {
    case login(requestObject: Encodable)
}

extension NetworkApi: EZARequest {
    var url: URL {
        switch self {
            case .login: return "some url"
        }
    }

    var path: String? {
        switch self {
            case .login: return "api/login"
        }
    }

    var method: HTTPMethod {
        switch self {
            case .login: return .get
        }
    }
    
    var task: EZATask {
        
        switch self {
            
        case .login(let requestObject):
            
            let params = try? requestObject.asDictionary()
            return .query(parameters: params ?? [:])
        }
    }
}
```

- Call api endpoint using publisher:

```swift


var cancellables: Set<AnyCancellable> = .init()

NetworkApi
    .login(requestObject: ["username": "user", "password": "pass"])
    .request()
    .sink { completion in
        <#code#>
    } receiveValue: { value in
        <#code#>
    }
    .store(in: &cancellables)
```

- You can also set logging level for EZANetwork

```swift

EZALogger.set(logLevel: .error) // .debug by default. Set ".disabled" to disable all logs
```

## Installation

### Cocoapods
CBCBluetooth is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EZANetwork'
```
### Swift Package Manager
1. Right click in the Project Navigator
2. Select "Add Packages..."
3. Search for ```https://github.com/eugene-software/EZANetwork.git```

## Author

Eugene Software

## License

EZANetwork is available under the MIT license. See the LICENSE file for more info.
